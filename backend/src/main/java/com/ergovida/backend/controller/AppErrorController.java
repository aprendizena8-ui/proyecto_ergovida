package com.ergovida.backend.controller;

import java.util.LinkedHashMap;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.ergovida.backend.service.AlertaErrorService;

import jakarta.servlet.http.HttpServletRequest;

/**
 * Recibe errores graves ocurridos en la app Flutter (caidas, excepciones no
 * controladas) y los registra para que AlertaErrorService notifique por correo
 * a los administradores.
 */
@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*")
public class AppErrorController {

    private static final Logger logger =
            LoggerFactory.getLogger(AppErrorController.class);

    private final AlertaErrorService alertaErrorService;

    public AppErrorController(AlertaErrorService alertaErrorService) {
        this.alertaErrorService = alertaErrorService;
    }

    @PostMapping("/app-errores")
    public ResponseEntity<Map<String, Object>> reportar(
            @RequestBody Map<String, String> body,
            HttpServletRequest request) {

        String tipo = limpiar(body.get("tipo"), 120, "Error de la app");
        String modulo = limpiar(body.get("modulo"), 190, "Aplicacion Flutter");
        String mensaje = limpiar(body.get("mensaje"), 2000, "Error sin mensaje");
        String stack = limpiar(body.get("stack"), 4000, "");

        String detalle = stack.isEmpty()
                ? mensaje
                : mensaje + "\n\n" + stack;

        try {
            alertaErrorService.registrarError(
                    tipo,
                    modulo,
                    detalle,
                    origenIp(request));
        } catch (Exception error) {
            logger.error(
                    "No se pudo registrar el error de la app: {}",
                    error.getMessage());
            return ResponseEntity.ok(respuesta(
                    false,
                    "No se pudo registrar el error."));
        }

        return ResponseEntity.ok(respuesta(
                true,
                "El error fue registrado y notificado a los administradores."));
    }

    private static Map<String, Object> respuesta(
            boolean recibido,
            String mensaje) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("recibido", recibido);
        body.put("mensaje", mensaje);
        return body;
    }

    private static String limpiar(String valor, int maximo, String defecto) {
        String limpio = valor == null ? "" : valor.trim();
        if (limpio.isEmpty()) {
            return defecto;
        }
        return limpio.length() > maximo
                ? limpio.substring(0, maximo)
                : limpio;
    }

    private static String origenIp(HttpServletRequest request) {
        String forwarded = request.getHeader("X-Forwarded-For");
        if (forwarded != null && !forwarded.isBlank()) {
            return forwarded.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
