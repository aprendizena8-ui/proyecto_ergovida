package com.ergovida.backend.service;

import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Locale;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import com.ergovida.backend.model.SolicitudAyuda;

@Service
public class EmailService {

    private final RestTemplate restTemplate = new RestTemplate();

    @Value("${brevo.api.key:}")
    private String apiKey;

    @Value("${brevo.sender.email:ergovida.sena@gmail.com}")
    private String senderEmail;

    @Value("${brevo.sender.name:ErgoVida}")
    private String senderName;

    private void enviarPorBrevo(String destinatario, String asunto, String textoPlano) {
        if (apiKey == null || apiKey.isBlank()) {
            throw new IllegalStateException("Falta la API Key de Brevo (BREVO_API_KEY).");
        }

        String url = "https://api.brevo.com/v3/smtp/email";

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.set("api-key", apiKey);

        String htmlContent = "<p>" + textoPlano.replace("\n", "<br>") + "</p>";

        String body = """
            {
                "sender": {"name": "%s", "email": "%s"},
                "to": [{"email": "%s"}],
                "subject": "%s",
                "htmlContent": "%s"
            }
            """.formatted(senderName, senderEmail, destinatario, asunto, htmlContent.replace("\"", "\\\""));

        HttpEntity<String> request = new HttpEntity<>(body, headers);
        restTemplate.postForObject(url, request, String.class);
    }

    public void enviarCodigoVerificacion(String destinatario, String codigo) {
        String texto = "¡Hola!\n\n" +
            "Tu código de verificación es: " + codigo + "\n\n" +
            "Ingrésalo en la app para continuar.\n" +
            "El código vence en 15 minutos.\n\n" +
            "Equipo ErgoVida";
        enviarPorBrevo(destinatario, "ErgoVida - Código de verificación", texto);
    }

    public void enviarRecordatorioPausa(String destinatario, String nombre, LocalTime hora) {
        String saludo = nombre == null || nombre.isBlank() ? "¡Hola!" : "¡Hola, " + nombre.trim() + "!";
        String horaAmPm = hora.format(DateTimeFormatter.ofPattern("hh:mm a", Locale.ENGLISH));

        String texto = saludo + "\n\n" +
            "Este es tu recordatorio diario de las " + horaAmPm + ".\n\n" +
            "Es momento de tu pausa activa: levántate, estira el cuerpo " +
            "y descansa la vista unos minutos.\n" +
            "Puedes abrir ErgoVida y realizar uno de tus ejercicios guiados.\n\n" +
            "Recibirás este correo todos los días a las " + horaAmPm + ".\n\n" +
            "Equipo ErgoVida";
        enviarPorBrevo(destinatario, "ErgoVida - Tu recordatorio diario de pausa activa", texto);
    }

    public void enviarRecordatorioGlobal(String destinatario, String nombre, String mensajeRecordatorio, LocalTime hora) {
        String saludo = nombre == null || nombre.isBlank() ? "¡Hola!" : "¡Hola, " + nombre.trim() + "!";
        String horaAmPm = hora.format(DateTimeFormatter.ofPattern("hh:mm a", Locale.ENGLISH));

        String texto = saludo + "\n\n" +
            "Tienes un recordatorio de ErgoVida para las " + horaAmPm + ":\n\n" +
            mensajeRecordatorio + "\n\n" +
            "Recuerda realizar tu pausa activa y cuidar tu bienestar laboral.\n\n" +
            "Equipo ErgoVida";
        enviarPorBrevo(destinatario, "ErgoVida - Recordatorio de bienestar", texto);
    }

    public void enviarCorreoPrueba(List<String> destinatarios, String solicitante) {
        String fecha = LocalDateTime.now().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm"));
        String texto = "Hola.\n\n" +
            "Este es un correo de prueba enviado desde ErgoVida por " + valorSeguro(solicitante) + " el " + fecha + ".\n\n" +
            "Si recibes este mensaje, la API de Brevo está funcionando.\n\n" +
            "Equipo ErgoVida";
        for (String correo : destinatarios) {
            enviarPorBrevo(correo, "ErgoVida - Correo de prueba", texto);
        }
    }

    public void enviarSolicitudAyuda(SolicitudAyuda solicitud, List<String> destinatarios) {
        String fecha = LocalDateTime.now().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm"));
        String texto = "Nueva solicitud de ayuda recibida.\n\n" +
            "Asunto: " + valorSeguro(solicitud.getAsunto()) + "\n" +
            "Descripcion:\n" + valorSeguro(solicitud.getDescripcion()) + "\n\n" +
            "Enviada por: " + valorSeguro(solicitud.getNombre()) + "\n" +
            "Correo: " + valorSeguro(solicitud.getCorreo()) + "\n" +
            "Rol: " + valorSeguro(solicitud.getRol()) + "\n" +
            "Fecha y hora: " + fecha + "\n" +
            "Estado inicial: " + valorSeguro(solicitud.getEstado()) + "\n\n" +
            "Equipo ErgoVida";
        for (String correo : destinatarios) {
            enviarPorBrevo(correo, "ErgoVida - Solicitud de ayuda: " + valorSeguro(solicitud.getAsunto()), texto);
        }
    }

    public void enviarAlertaError(List<String> destinatarios, String tipo, String modulo, String mensaje, int veces) {
        String fecha = LocalDateTime.now().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm"));
        String texto = "Se detecto un error en el servidor ErgoVida.\n\n" +
            "Fecha y hora: " + fecha + "\n" +
            "Tipo de error: " + valorSeguro(tipo) + "\n" +
            "Modulo o ruta: " + valorSeguro(modulo) + "\n" +
            "Mensaje: " + valorSeguro(mensaje) + "\n" +
            "Veces detectado: " + veces + "\n\n" +
            "Equipo ErgoVida";
        for (String correo : destinatarios) {
            enviarPorBrevo(correo, "ErgoVida - ALERTA: error en " + valorSeguro(modulo), texto);
        }
    }

    public void enviarFalloRecordatorios(List<String> destinatarios, String resumen, int fallos) {
        String fecha = LocalDateTime.now().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm"));
        String texto = "El scheduler de recordatorios reporto fallos.\n\n" +
            "Fecha y hora: " + fecha + "\n" +
            "Envios fallidos: " + fallos + "\n" +
            "Detalle:\n" + valorSeguro(resumen) + "\n\n" +
            "Equipo ErgoVida";
        for (String correo : destinatarios) {
            enviarPorBrevo(correo, "ErgoVida - ALERTA: fallo al enviar recordatorios", texto);
        }
    }

    private static String valorSeguro(String valor) {
        return valor == null || valor.isBlank() ? "(sin dato)" : valor.trim();
    }
}
