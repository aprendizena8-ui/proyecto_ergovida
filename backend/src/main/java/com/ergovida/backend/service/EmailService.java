package com.ergovida.backend.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

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
}
