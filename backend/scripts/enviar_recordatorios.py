import os
import re
import smtplib
import sys
from datetime import date, datetime
from email.message import EmailMessage
from zoneinfo import ZoneInfo

import mysql.connector

VENTANA_MINUTOS = int(os.getenv("VENTANA_MINUTOS", "20"))
ZONA = ZoneInfo(os.getenv("TZ_RECORDATORIOS", "America/Bogota"))
SMTP_HOST = os.getenv("MAIL_HOST", "smtp.gmail.com")
SMTP_PORT = int(os.getenv("MAIL_PORT", "587"))
REMITENTE = (os.getenv("MAIL_USERNAME") or "").strip()
PASSWORD = (os.getenv("MAIL_PASSWORD") or "").strip()


class Correo:
    def __init__(self):
        self.smtp = None

    def conectar(self):
        if self.smtp is None:
            self.smtp = smtplib.SMTP(SMTP_HOST, SMTP_PORT, timeout=25)
            self.smtp.starttls()
            self.smtp.login(REMITENTE, PASSWORD)

    def enviar(self, destinatario, asunto, cuerpo):
        self.conectar()
        mensaje = EmailMessage()
        mensaje["From"] = REMITENTE
        mensaje["To"] = destinatario
        mensaje["Subject"] = asunto
        mensaje.set_content(cuerpo)
        try:
            self.smtp.send_message(mensaje)
        except Exception:
            self.cerrar()
            raise

    def cerrar(self):
        if self.smtp is not None:
            try:
                self.smtp.quit()
            except Exception:
                pass
            self.smtp = None


def parsear_jdbc(url):
    limpio = (url or "").strip()
    coincidencia = re.match(
        r"^jdbc:mysql://([^:/?]+)(?::(\d+))?/([^?]+)",
        limpio,
        re.IGNORECASE,
    )
    if not coincidencia:
        raise ValueError("DB_URL no tiene el formato jdbc:mysql://host:puerto/base")
    host = coincidencia.group(1)
    puerto = int(coincidencia.group(2) or 3306)
    base = coincidencia.group(3)
    ssl = "ssl-mode=DISABLED" not in limpio.upper()
    return host, puerto, base, ssl


def conectar_db():
    host, puerto, base, ssl = parsear_jdbc(os.getenv("DB_URL"))
    config = {
        "host": host,
        "port": puerto,
        "user": os.getenv("DB_USER"),
        "password": os.getenv("DB_PASSWORD"),
        "database": base,
        "connection_timeout": 20,
        "autocommit": False,
    }
    if ssl:
        config["ssl_disabled"] = False
    return mysql.connector.connect(**config)


def hora_a_minutos(valor):
    if valor is None:
        return None
    texto = str(valor)
    partes = texto.split(":")
    if len(partes) < 2:
        return None
    try:
        return int(partes[0]) * 60 + int(partes[1])
    except ValueError:
        return None


def dentro_de_ventana(hora, ahora_minutos):
    if hora is None:
        return False
    diferencia = ahora_minutos - hora
    return 0 <= diferencia <= VENTANA_MINUTOS


def aplica_hoy(dias_semana, hoy):
    if not dias_semana or not str(dias_semana).strip():
        return True
    dias = set()
    for parte in str(dias_semana).split(","):
        try:
            dias.add(int(parte.strip()))
        except ValueError:
            continue
    return not dias or hoy.isoweekday() in dias


def registrar_historial(
    cursor,
    tipo,
    recordatorio_id,
    horario_id,
    usuario_id,
    exito,
    error,
    hoy,
    ahora,
):
    cursor.execute(
        """
        INSERT INTO recordatorios_envios_historial
            (tipo_recordatorio, recordatorio_id, horario_id, usuario_id,
             canal, exito, error, fecha, fecha_hora)
        VALUES (%s, %s, %s, %s, 'EMAIL', %s, %s, %s, %s)
        """,
        (
            tipo,
            recordatorio_id,
            horario_id,
            usuario_id,
            1 if exito else 0,
            error,
            hoy,
            ahora,
        ),
    )


def correo_personal_ya_enviado(cursor, horario_id, usuario_id, hoy):
    cursor.execute(
        """
        SELECT 1
        FROM recordatorios_envios_historial
        WHERE tipo_recordatorio = 'PERSONAL'
          AND horario_id = %s
          AND usuario_id = %s
          AND canal = 'EMAIL'
          AND exito = 1
          AND fecha = %s
        LIMIT 1
        """,
        (horario_id, usuario_id, hoy),
    )
    return cursor.fetchone() is not None


def global_ya_enviado(cursor, recordatorio_id, usuario_id, hoy):
    cursor.execute(
        """
        SELECT 1
        FROM recordatorios_globales_envios
        WHERE recordatorio_id = %s AND usuario_id = %s AND fecha = %s
        LIMIT 1
        """,
        (recordatorio_id, usuario_id, hoy),
    )
    return cursor.fetchone() is not None


def enviar_personales(conexion, correo, hoy, ahora, ahora_minutos):
    cursor = conexion.cursor()
    cursor.execute(
        """
        SELECT h.id, h.usuario_id, TIME_FORMAT(h.hora, '%H:%i'),
               u.nombre, u.correo
        FROM horarios h
        JOIN usuarios u ON u.id = h.usuario_id
        WHERE h.hora IS NOT NULL
          AND (h.ultimo_envio IS NULL OR h.ultimo_envio <> %s)
          AND (u.activo IS NULL OR u.activo = 1)
          AND (u.recordatorios IS NULL OR u.recordatorios = 1)
          AND (u.recordatorios_correo IS NULL OR u.recordatorios_correo = 1)
          AND u.correo IS NOT NULL AND u.correo <> ''
        """,
        (hoy,),
    )
    horarios = cursor.fetchall()
    enviados = 0
    fallos = 0
    detalles = []

    for horario_id, usuario_id, hora, nombre, destinatario in horarios:
        if not dentro_de_ventana(hora_a_minutos(hora), ahora_minutos):
            continue

        if correo_personal_ya_enviado(cursor, horario_id, usuario_id, hoy):
            cursor.execute(
                "UPDATE horarios SET ultimo_envio = %s WHERE id = %s",
                (hoy, horario_id),
            )
            conexion.commit()
            continue

        saludo = "¡Hola!" if not nombre or not nombre.strip() else f"¡Hola, {nombre.strip()}!"
        cuerpo = (
            f"{saludo}\n\n"
            f"Este es tu recordatorio diario de las {hora}.\n\n"
            "Es momento de tu pausa activa: levántate, estira el cuerpo "
            "y descansa la vista unos minutos.\n"
            "Puedes abrir ErgoVida y realizar uno de tus ejercicios guiados.\n\n"
            "Equipo ErgoVida"
        )

        try:
            correo.enviar(
                destinatario.strip(),
                "ErgoVida - Tu recordatorio diario de pausa activa",
                cuerpo,
            )
            registrar_historial(
                cursor, "PERSONAL", None, horario_id, usuario_id, True, None, hoy, ahora
            )
            cursor.execute(
                "UPDATE horarios SET ultimo_envio = %s WHERE id = %s",
                (hoy, horario_id),
            )
            conexion.commit()
            enviados += 1
        except Exception as error:
            conexion.rollback()
            try:
                registrar_historial(
                    cursor,
                    "PERSONAL",
                    None,
                    horario_id,
                    usuario_id,
                    False,
                    str(error)[:500],
                    hoy,
                    ahora,
                )
                conexion.commit()
            except Exception:
                conexion.rollback()
            fallos += 1
            detalles.append(f"Correo a {destinatario}: {error}")

    cursor.close()
    return enviados, fallos, detalles


def enviar_globales(conexion, correo, hoy, ahora, ahora_minutos):
    cursor = conexion.cursor()
    cursor.execute(
        """
        SELECT id, TIME_FORMAT(hora, '%H:%i'), dias_semana, mensaje
        FROM recordatorios_globales
        WHERE activo = 1 AND hora IS NOT NULL
        """
    )
    recordatorios = cursor.fetchall()
    if not recordatorios:
        cursor.close()
        return 0, 0, []

    cursor.execute(
        """
        SELECT id, nombre, correo
        FROM usuarios
        WHERE (activo IS NULL OR activo = 1)
          AND (recordatorios IS NULL OR recordatorios = 1)
          AND (recordatorios_correo IS NULL OR recordatorios_correo = 1)
          AND correo IS NOT NULL AND correo <> ''
        """
    )
    usuarios = cursor.fetchall()
    enviados = 0
    fallos = 0
    detalles = []

    for recordatorio_id, hora, dias_semana, mensaje in recordatorios:
        if not aplica_hoy(dias_semana, hoy):
            continue
        if not dentro_de_ventana(hora_a_minutos(hora), ahora_minutos):
            continue

        for usuario_id, nombre, destinatario in usuarios:
            if global_ya_enviado(cursor, recordatorio_id, usuario_id, hoy):
                continue

            saludo = "¡Hola!" if not nombre or not nombre.strip() else f"¡Hola, {nombre.strip()}!"
            cuerpo = (
                f"{saludo}\n\n"
                f"Tienes un recordatorio de ErgoVida para las {hora}:\n\n"
                f"{mensaje or 'Es momento de tu pausa activa.'}\n\n"
                "Recuerda realizar tu pausa activa y cuidar tu bienestar laboral.\n\n"
                "Equipo ErgoVida"
            )

            try:
                correo.enviar(
                    destinatario.strip(),
                    "ErgoVida - Recordatorio de bienestar",
                    cuerpo,
                )
                cursor.execute(
                    """
                    INSERT IGNORE INTO recordatorios_globales_envios
                        (recordatorio_id, usuario_id, fecha)
                    VALUES (%s, %s, %s)
                    """,
                    (recordatorio_id, usuario_id, hoy),
                )
                registrar_historial(
                    cursor,
                    "GLOBAL",
                    recordatorio_id,
                    None,
                    usuario_id,
                    True,
                    None,
                    hoy,
                    ahora,
                )
                conexion.commit()
                enviados += 1
            except Exception as error:
                conexion.rollback()
                try:
                    registrar_historial(
                        cursor,
                        "GLOBAL",
                        recordatorio_id,
                        None,
                        usuario_id,
                        False,
                        str(error)[:500],
                        hoy,
                        ahora,
                    )
                    conexion.commit()
                except Exception:
                    conexion.rollback()
                fallos += 1
                detalles.append(f"Correo a {destinatario}: {error}")

    cursor.close()
    return enviados, fallos, detalles


def notificar_fallos(conexion, correo, fallos, detalles, hoy, ahora):
    if fallos <= 0:
        return
    cursor = conexion.cursor()
    try:
        cursor.execute(
            "SELECT correo FROM correos_administradores WHERE activo = 1"
        )
        destinatarios = [fila[0] for fila in cursor.fetchall() if fila[0]]
    except Exception:
        destinatarios = []
    finally:
        cursor.close()

    if not destinatarios:
        return

    resumen = "\n".join(detalles[:10])
    cuerpo = (
        "El envio automatico de recordatorios de ErgoVida reporto fallos.\n\n"
        f"Fecha y hora: {ahora:%d/%m/%Y %H:%M}\n"
        f"Envios fallidos: {fallos}\n"
        f"Detalle:\n{resumen}\n\n"
        "Equipo ErgoVida"
    )
    for destinatario in destinatarios:
        try:
            correo.enviar(
                destinatario.strip(),
                "ErgoVida - ALERTA: fallo al enviar recordatorios",
                cuerpo,
            )
        except Exception as error:
            print(f"No se pudo notificar a {destinatario}: {error}")


def main():
    if not REMITENTE or not PASSWORD:
        print("Faltan MAIL_USERNAME o MAIL_PASSWORD.")
        return 1

    ahora = datetime.now(ZONA)
    hoy = ahora.date()
    ahora_minutos = ahora.hour * 60 + ahora.minute
    ahora_db = ahora.replace(tzinfo=None)

    conexion = conectar_db()
    correo = Correo()
    try:
        personales, fallos_personales, detalles_personales = enviar_personales(
            conexion, correo, hoy, ahora_db, ahora_minutos
        )
        globales, fallos_globales, detalles_globales = enviar_globales(
            conexion, correo, hoy, ahora_db, ahora_minutos
        )
        fallos = fallos_personales + fallos_globales
        detalles = detalles_personales + detalles_globales
        notificar_fallos(conexion, correo, fallos, detalles, hoy, ahora_db)
        print(
            f"Recordatorios personales enviados: {personales}. "
            f"Globales enviados: {globales}. Fallos: {fallos}."
        )
        for detalle in detalles:
            print(detalle)
        return 0
    finally:
        correo.cerrar()
        conexion.close()


if __name__ == "__main__":
    sys.exit(main())
