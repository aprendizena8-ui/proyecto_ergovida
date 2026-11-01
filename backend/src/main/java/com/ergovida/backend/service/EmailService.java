package com.ergovida.backend.service;

import java.time.LocalTime;
import java.time.format.DateTimeFormatter;

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

    public void enviarRecordatorioPausa(
            String destinatario,
            String nombre,
            LocalTime hora) {

        String saludo = nombre == null || nombre.isBlank()
                ? "¡Hola!"
                : "¡Hola, " + nombre.trim() + "!";

        SimpleMailMessage mensaje = new SimpleMailMessage();
        if (remitente != null && !remitente.isBlank()) {
            mensaje.setFrom(remitente);
        }
        mensaje.setTo(destinatario);
        mensaje.setSubject("ErgoVida - Es momento de tu pausa activa");
        mensaje.setText(
            saludo + "\n\n" +
            "Es momento de tu pausa activa de las " +
            hora.format(DateTimeFormatter.ofPattern("HH:mm")) + ".\n\n" +
            "Levántate, estira el cuerpo y descansa la vista unos minutos.\n" +
            "Puedes abrir ErgoVida y realizar uno de tus ejercicios guiados.\n\n" +
            "Equipo ErgoVida"
        );
        mailSender.send(mensaje);
    }
}
