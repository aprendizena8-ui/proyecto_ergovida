package com.ergovida.backend.service;

import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

import com.ergovida.backend.model.SolicitudAyuda;

@Service
public class EmailService {

    private final JavaMailSender mailSender;
    private final String remitente;

    public EmailService(
            JavaMailSender mailSender,
            @Value("${spring.mail.username:}") String remitente) {
        this.mailSender = mailSender;
        this.remitente = remitente;
    }

    public void enviarCodigoVerificacion(String destinatario, String codigo) {
        SimpleMailMessage mensaje = new SimpleMailMessage();
        if (remitente != null && !remitente.isBlank()) {
            mensaje.setFrom(remitente);
        }
        mensaje.setTo(destinatario);
        mensaje.setSubject("ErgoVida - Código de verificación");
        mensaje.setText(
            "¡Hola!\n\n" +
            "Tu código de verificación es: " + codigo + "\n\n" +
            "Ingrésalo en la app para continuar.\n" +
            "El código vence en 15 minutos.\n\n" +
            "Equipo ErgoVida"
        );
        mailSender.send(mensaje);
    }

    public void enviarRecordatorioPausa(
            String destinatario,
            String nombre,
            LocalTime hora) {

        String saludo = nombre == null || nombre.isBlank()
                ? "¡Hola!"
                : "¡Hola, " + nombre.trim() + "!";

        String horaAmPm = hora.format(
                DateTimeFormatter.ofPattern("hh:mm a", Locale.ENGLISH));

        SimpleMailMessage mensaje = new SimpleMailMessage();
        if (remitente != null && !remitente.isBlank()) {
            mensaje.setFrom(remitente);
        }
        mensaje.setTo(destinatario);
        mensaje.setSubject("ErgoVida - Tu recordatorio diario de pausa activa");
        mensaje.setText(
            saludo + "\n\n" +
            "Este es tu recordatorio diario de las " + horaAmPm + ".\n\n" +
            "Es momento de tu pausa activa: levántate, estira el cuerpo " +
            "y descansa la vista unos minutos.\n" +
            "Puedes abrir ErgoVida y realizar uno de tus ejercicios guiados.\n\n" +
            "Recibirás este correo todos los días a las " + horaAmPm + ".\n\n" +
            "Equipo ErgoVida"
        );
        mailSender.send(mensaje);
    }

    public void enviarRecordatorioGlobal(
            String destinatario,
            String nombre,
            String mensajeRecordatorio,
            LocalTime hora) {

        String saludo = nombre == null || nombre.isBlank()
                ? "¡Hola!"
                : "¡Hola, " + nombre.trim() + "!";

        String horaAmPm = hora.format(
                DateTimeFormatter.ofPattern("hh:mm a", Locale.ENGLISH));

        SimpleMailMessage mensaje = new SimpleMailMessage();
        if (remitente != null && !remitente.isBlank()) {
            mensaje.setFrom(remitente);
        }
        mensaje.setTo(destinatario);
        mensaje.setSubject("ErgoVida - Recordatorio de bienestar");
        mensaje.setText(
            saludo + "\n\n" +
            "Tienes un recordatorio de ErgoVida para las " + horaAmPm + ":\n\n" +
            mensajeRecordatorio + "\n\n" +
            "Recuerda realizar tu pausa activa y cuidar tu bienestar laboral.\n\n" +
            "Equipo ErgoVida"
        );
        mailSender.send(mensaje);
    }

    public void enviarCorreoPrueba(
            List<String> destinatarios,
            String solicitante) {

        String fecha = LocalDateTime.now().format(
                DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm"));

        enviar(
                destinatarios,
                "ErgoVida - Correo de prueba de alertas",
                "Hola.\n\n" +
                "Este es un correo de prueba enviado desde ErgoVida "
                + "por " + valorSeguro(solicitante) + " el " + fecha + ".\n\n"
                + "Si recibes este mensaje, la configuracion SMTP y los "
                + "correos de administradores estan funcionando.\n\n"
                + "Equipo ErgoVida");
    }

    public void enviarSolicitudAyuda(
            SolicitudAyuda solicitud,
            List<String> destinatarios) {

        String fecha = LocalDateTime.now().format(
                DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm"));

        enviar(
                destinatarios,
                "ErgoVida - Solicitud de ayuda: " + valorSeguro(solicitud.getAsunto()),
                "Nueva solicitud de ayuda recibida.\n\n"
                + "Asunto: " + valorSeguro(solicitud.getAsunto()) + "\n"
                + "Descripcion:\n" + valorSeguro(solicitud.getDescripcion()) + "\n\n"
                + "Enviada por: " + valorSeguro(solicitud.getNombre()) + "\n"
                + "Correo: " + valorSeguro(solicitud.getCorreo()) + "\n"
                + "Rol: " + valorSeguro(solicitud.getRol()) + "\n"
                + "Fecha y hora: " + fecha + "\n"
                + "Estado inicial: " + valorSeguro(solicitud.getEstado()) + "\n\n"
                + "Puedes gestionar esta solicitud desde el panel administrador "
                + "de ErgoVida.\n\n"
                + "Equipo ErgoVida");
    }

    public void enviarAlertaError(
            List<String> destinatarios,
            String tipo,
            String modulo,
            String mensaje,
            int veces) {

        String fecha = LocalDateTime.now().format(
                DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm"));

        enviar(
                destinatarios,
                "ErgoVida - ALERTA: error en " + valorSeguro(modulo),
                "Se detecto un error en el servidor ErgoVida.\n\n"
                + "Fecha y hora: " + fecha + "\n"
                + "Tipo de error: " + valorSeguro(tipo) + "\n"
                + "Modulo o ruta: " + valorSeguro(modulo) + "\n"
                + "Mensaje: " + valorSeguro(mensaje) + "\n"
                + "Veces detectado: " + veces + "\n\n"
                + "Este correo se agrupa: el mismo error no volvera a "
                + "notificarse antes del intervalo configurado.\n\n"
                + "Equipo ErgoVida");
    }

    public void enviarFalloRecordatorios(
            List<String> destinatarios,
            String resumen,
            int fallos) {

        String fecha = LocalDateTime.now().format(
                DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm"));

        enviar(
                destinatarios,
                "ErgoVida - ALERTA: fallo al enviar recordatorios",
                "El scheduler de recordatorios reporto fallos.\n\n"
                + "Fecha y hora: " + fecha + "\n"
                + "Envios fallidos: " + fallos + "\n"
                + "Detalle:\n" + valorSeguro(resumen) + "\n\n"
                + "Revisa el historial en la tabla "
                + "recordatorios_envios_historial.\n\n"
                + "Equipo ErgoVida");
    }

    private void enviar(
            List<String> destinatarios,
            String asunto,
            String texto) {

        if (destinatarios == null || destinatarios.isEmpty()) {
            throw new IllegalStateException(
                    "No hay correos de administradores configurados.");
        }

        List<String> limpios = new ArrayList<>();
        for (String correo : destinatarios) {
            if (correo != null && !correo.isBlank()) {
                limpios.add(correo.trim());
            }
        }
        if (limpios.isEmpty()) {
            throw new IllegalStateException(
                    "No hay correos de administradores configurados.");
        }

        SimpleMailMessage mensaje = new SimpleMailMessage();
        if (remitente != null && !remitente.isBlank()) {
            mensaje.setFrom(remitente);
        }
        mensaje.setTo(limpios.toArray(String[]::new));
        mensaje.setSubject(asunto);
        mensaje.setText(texto);
        mailSender.send(mensaje);
    }

    private static String valorSeguro(String valor) {
        return valor == null || valor.isBlank() ? "(sin dato)" : valor.trim();
    }
}
