# Despliegue 24/7 de ErgoVida

Esta guia deja el backend Spring Boot ejecutandose siempre (aunque la app
Flutter este cerrada) y configura las alertas por correo, las solicitudes de
ayuda y las notificaciones push.

## 1. Requisitos

- MySQL 8 con la base `ergovida_db`.
- Java 17.
- Un servidor Linux (VPS) o Windows Server con acceso a internet.
- Cuenta de Gmail con contrasena de aplicacion para el envio de correos.
- Proyecto de Firebase con Cloud Messaging habilitado (solo si se usara push).
- Dominio o IP publica para que la app movil llegue al backend.

## 2. Base de datos

Ejecuta en MySQL Workbench, sobre `ergovida_db`:

```sql
SOURCE C:/ruta/al/repositorio/backend/sql/alertas_soporte_push.sql;
```

El script es idempotente: crea solo lo que falta y no borra datos. Incluye:

- `correos_administradores`
- `solicitudes_ayuda`
- `dispositivos_push`
- `alertas_error`
- `recordatorios_envios_historial`
- `recordatorios_globales`
- `recordatorios_globales_envios`
- columnas faltantes `horarios.ultimo_envio` y
  `usuarios.recordatorios_correo`

Verifica las tablas:

```sql
USE ergovida_db;
SHOW TABLES;
SELECT * FROM correos_administradores;
```

## 3. Variables de entorno del backend

Nunca escribas credenciales en el codigo. Define estas variables en el
servidor:

| Variable | Ejemplo | Uso |
| --- | --- | --- |
| `DB_URL` | `jdbc:mysql://localhost:3306/ergovida_db` | Conexion MySQL |
| `DB_USER` | `ergovida` | Usuario MySQL |
| `DB_PASSWORD` | `********` | Contrasena MySQL |
| `MAIL_USERNAME` | `cuenta@gmail.com` | Cuenta SMTP |
| `MAIL_PASSWORD` | `********` | Contrasena de aplicacion |
| `ALERTAS_ERROR_INTERVALO_MINUTOS` | `15` | Agrupacion de errores |
| `RECORDATORIOS_SCHEDULER_ENABLED` | `true` | Scheduler del servidor |
| `FCM_ENABLED` | `true` | Activa push |
| `FIREBASE_SERVICE_ACCOUNT_PATH` | `/etc/ergovida/firebase.json` | Cuenta de servicio FCM |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | `{...}` | Alternativa al archivo |
| `FIREBASE_PROJECT_ID` | `ergovida-app` | Proyecto Firebase |
| `TZ` | `America/Bogota` | Zona horaria del servidor |

Configura la zona horaria del servidor en `America/Bogota` (o la zona donde
estan los usuarios). Los recordatorios comparan la hora del servidor con la
hora guardada en MySQL, por lo que una zona horaria distinta enviaria los
correos y push a destiempo.

Si el servidor usa el archivo `backend/db.properties`, puedes dejar ahi
`DB_URL`, `DB_USER` y `DB_PASSWORD`; en produccion se recomienda usar solo
variables de entorno.

## 4. Compilar y ejecutar el backend

Desde `backend/`:

```powershell
.\mvnw.cmd clean package -DskipTests
java -jar target/backend-0.0.1-SNAPSHOT.jar
```

El puerto es `8080`. Verifica:

```powershell
Invoke-RestMethod http://localhost:8080/api/health
```

Debe responder `status: UP` y `database: UP`.

## 5. Servicio 24/7 con systemd (Linux)

Copia el JAR a `/opt/ergovida/backend.jar` y crea
`/etc/systemd/system/ergovida.service`:

```ini
[Unit]
Description=ErgoVida Backend
After=network.target mysql.service

[Service]
User=ergovida
WorkingDirectory=/opt/ergovida
EnvironmentFile=/etc/ergovida/ergovida.env
ExecStart=/usr/bin/java -jar /opt/ergovida/backend.jar
Restart=always
RestartSec=5
SuccessExitStatus=143

[Install]
WantedBy=multi-user.target
```

Archivo `/etc/ergovida/ergovida.env`:

```ini
DB_URL=jdbc:mysql://localhost:3306/ergovida_db
DB_USER=ergovida
DB_PASSWORD=CAMBIAR
TZ=America/Bogota
MAIL_USERNAME=cuenta@gmail.com
MAIL_PASSWORD=CAMBIAR
ALERTAS_ERROR_INTERVALO_MINUTOS=15
RECORDATORIOS_SCHEDULER_ENABLED=true
FCM_ENABLED=true
FIREBASE_SERVICE_ACCOUNT_PATH=/etc/ergovida/firebase.json
FIREBASE_PROJECT_ID=ergovida-app
```

Activa el servicio:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now ergovida
sudo systemctl status ergovida
sudo journalctl -u ergovida -f
```

El scheduler se ejecuta cada minuto y funciona sin que la app movil este
abierta. Si el servidor se reinicia, systemd lo levanta otra vez.

## 6. Firebase Cloud Messaging

1. Crea el proyecto en <https://console.firebase.google.com>.
2. Agrega una app Android con el `applicationId` del proyecto
   (`com.example.tarea` o el definitivo).
3. Descarga la cuenta de servicio: Configuracion del proyecto > Cuentas de
   servicio > Generar nueva clave privada.
4. Guarda el JSON fuera del repositorio y apunta
   `FIREBASE_SERVICE_ACCOUNT_PATH` a ese archivo.
5. Compila la app con los datos publicos de Firebase:

```powershell
flutter build apk --release `
  --dart-define=API_BASE_URL=https://tu-dominio.com/api `
  --dart-define=FIREBASE_API_KEY=... `
  --dart-define=FIREBASE_APP_ID=... `
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... `
  --dart-define=FIREBASE_PROJECT_ID=... `
  --dart-define=FIREBASE_STORAGE_BUCKET=...
```

`API_BASE_URL` debe apuntar al backend publico y terminar en `/api`. Si se
omite, la app usa las URLs locales de desarrollo. Sin los datos de Firebase
la app sigue funcionando y los recordatorios llegan solo por correo. Los
permisos Android `INTERNET` y `POST_NOTIFICATIONS` ya estan declarados en el
manifest.

En iOS, ademas de los datos de Firebase, debes subir la clave APNs al
proyecto de Firebase y habilitar la capacidad Push Notifications en Xcode.

## 7. Servidor desplegado y app cerrada

El backend revisa cada minuto `recordatorios_globales` y `horarios`. Cuando la
hora coincide:

1. Envia un correo (si el usuario lo tiene activo).
2. Envia un push a los dispositivos registrados (si FCM esta configurado).
3. Guarda el intento en `recordatorios_envios_historial`.

La app no necesita estar abierta: el servidor hace el envio. Al iniciar
sesion, la app registra el token del dispositivo en `dispositivos_push`.

## 8. Alertas automaticas de errores

- Las alertas solo se envian por el backend.
- Los correos se configuran desde el panel administrador o en
  `correos_administradores`.
- Los errores iguales se agrupan cada 15 minutos
  (`ALERTAS_ERROR_INTERVALO_MINUTOS`).
- Los errores `4xx` no generan alerta; los `5xx` y las excepciones no
  controladas si.
- El boton "Enviar correo de prueba" permite validar SMTP y destinatarios.
- Las fallas al enviar recordatorios tambien se notifican a los
  administradores.

## 9. Solicitudes de ayuda

- El usuario o lider SST abre Ajustes > Ayuda y soporte.
- La solicitud se guarda en `solicitudes_ayuda` con estado `PENDIENTE`.
- Se envia un correo a los administradores configurados.
- El administrador puede marcarla como `RESUELTA` o reabrirla desde el panel.
- Si SMTP falla, la solicitud queda guardada igualmente.

## 10. Monitoreo externo recomendado

El backend no puede avisar por correo si el servidor entero esta apagado.
Configura un monitor externo (UptimeRobot, Better Stack, Pingdom) apuntando a:

```text
https://tu-dominio/api/health
```

El monitor debe alertar al administrador si el endpoint deja de responder o
devuelve un estado distinto de `200`.

## 11. Verificacion rapida

```sql
SELECT COUNT(*) FROM correos_administradores WHERE activo = 1;
SELECT * FROM solicitudes_ayuda ORDER BY fecha_creacion DESC LIMIT 10;
SELECT * FROM recordatorios_envios_historial ORDER BY fecha_hora DESC LIMIT 20;
SELECT * FROM alertas_error ORDER BY ultimo_envio DESC LIMIT 20;
SELECT * FROM dispositivos_push WHERE activo = 1;
```

Prueba manual de los endpoints administrativos (reemplaza el ID y el correo):

```bash
curl -X POST http://localhost:8080/api/admin/correos-alertas/probar \
  -H "X-Usuario-Id: 1" \
  -H "X-Usuario-Correo: administrador@empresa.com"
```

## 12. Notas de seguridad

- No subas a Git `db.properties`, `firebase.json` ni archivos `.env`.
- Usa una contrasena de aplicacion de Gmail, no la contrasena normal.
- Restringe los correos administradores a personas autorizadas.
- MantǸn el repositorio de avatares sin cambios: esta funcionalidad no toca
  archivos, tamanos, rutas ni estilos de avatares.

## 13. Despliegue con Docker

El backend incluye `backend/Dockerfile` y `backend/docker-compose.yml` con
`restart: always`, para que el scheduler siga enviando correos aunque nadie
tenga la app abierta.

```bash
cd backend
cp .env.example .env
```

Edita `.env` con la URL de Aiven, el usuario, la contrasena y la cuenta de
Gmail. Luego:

```bash
docker compose up -d --build
docker compose ps
docker compose logs -f ergovida-backend
```

El contenedor escucha en `http://localhost:8080`. No lo ejecutes al mismo
tiempo que el `docker-compose.yml` de la raiz (Dozzle tambien usa el puerto
8080). El `.dockerignore` excluye `db.properties` y `.env`, por lo que las
credenciales no quedan dentro de la imagen.

## 14. Alternativa sin servidor: GitHub Actions

Si no quieres mantener un servidor encendido, el workflow
`.github/workflows/recordatorios.yml` ejecuta el envio desde GitHub cada 10
minutos. No requiere la app Flutter ni el backend local: se conecta a la base
de datos de Aiven, envia los correos y registra el historial para no repetir
envios.

Configura estos secrets en GitHub (Settings > Secrets and variables >
Actions > New repository secret):

| Secret | Contenido |
| --- | --- |
| `DB_URL` | `jdbc:mysql://HOST:PUERTO/ergovida_db?ssl-mode=REQUIRED` |
| `DB_USER` | Usuario de Aiven |
| `DB_PASSWORD` | Contrasena de Aiven |
| `MAIL_USERNAME` | Cuenta de Gmail |
| `MAIL_PASSWORD` | Contrasena de aplicacion de Gmail |

El workflow corre sobre la rama por defecto del repositorio. Si la rama por
defecto no contiene `.github/workflows/recordatorios.yml`, fusiona o sube el
archivo a esa rama. Puedes probarlo manualmente en Actions > Recordatorios
ErgoVida > Run workflow.

Notas:

- GitHub puede retrasar los cron unos minutos; por eso el script usa una
  ventana de 20 minutos (`VENTANA_MINUTOS`).
- GitHub desactiva los workflows programados tras 60 dias sin actividad en el
  repositorio.
- En repositorios privados los minutos de Actions se consumen; en publicos el
  cron es gratuito.
- El script y el backend usan las mismas tablas de deduplicacion
  (`horarios.ultimo_envio`, `recordatorios_globales_envios` y
  `recordatorios_envios_historial`), asi que no se duplican correos si ambos
  estan activos.
- El script no envia notificaciones push; para push usa el backend 24/7.

