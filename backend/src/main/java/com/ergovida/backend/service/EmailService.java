package com.ergovida.backend.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class EmailService {

    @Autowired
    private JavaMailSender mailSender;

    public void enviarCodigoVerificacion(String destinatario, String codigo) {
        SimpleMailMessage mensaje = new SimpleMailMessage();
        mensaje.setTo(destinatario);
        mensaje.setSubject("ErgoVida - Código de verificación");
        mensaje.setText(
            "¡Hola!\n\n" +
            "Tu código de verificación es: " + codigo + "\n\n" +
            "Ingrésalo en la app para activar tu cuenta.\n\n" +
            "Equipo ErgoVida"
        );
        mailSender.send(mensaje);
    }
}
