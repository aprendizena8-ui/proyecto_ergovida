package com.ergovida.backend.config;

import java.util.LinkedHashMap;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import com.ergovida.backend.service.AlertaErrorService;

import jakarta.servlet.http.HttpServletRequest;

@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger logger =
            LoggerFactory.getLogger(GlobalExceptionHandler.class);

    private final AlertaErrorService alertaErrorService;

    public GlobalExceptionHandler(AlertaErrorService alertaErrorService) {
        this.alertaErrorService = alertaErrorService;
    }

    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<Map<String, Object>> manejarEstado(
            ResponseStatusException error,
            HttpServletRequest request) {

        HttpStatus estado = HttpStatus.resolve(error.getStatusCode().value());
        if (estado == null) {
            estado = HttpStatus.INTERNAL_SERVER_ERROR;
        }

        if (estado.is5xxServerError()) {
            notificar(error, request);
        }

        return ResponseEntity.status(estado).body(respuesta(
                estado,
                error.getReason() == null
                        ? estado.getReasonPhrase()
                        : error.getReason()));
    }

    @ExceptionHandler(NoResourceFoundException.class)
    public ResponseEntity<Map<String, Object>> manejarNoEncontrado(
            NoResourceFoundException error) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(respuesta(
                HttpStatus.NOT_FOUND,
                "Recurso no encontrado."));
    }

    @ExceptionHandler({
            MethodArgumentNotValidException.class,
            HttpMessageNotReadableException.class,
            MissingServletRequestParameterException.class,
            HttpRequestMethodNotSupportedException.class
    })
    public ResponseEntity<Map<String, Object>> manejarSolicitudInvalida(
            Exception error) {

        HttpStatus estado = error instanceof HttpRequestMethodNotSupportedException
                ? HttpStatus.METHOD_NOT_ALLOWED
                : HttpStatus.BAD_REQUEST;

        return ResponseEntity.status(estado).body(respuesta(
                estado,
                "La solicitud no es válida. Revisa los datos enviados."));
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<Map<String, Object>> manejarConflictoDatos(
            DataIntegrityViolationException error) {

        logger.warn("Conflicto de datos: {}", error.getMessage());

        return ResponseEntity.status(HttpStatus.CONFLICT).body(respuesta(
                HttpStatus.CONFLICT,
                "No se pudo guardar la información: ya existe un registro "
                        + "con esos datos."));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> manejarError(
            Exception error,
            HttpServletRequest request) {

        logger.error(
                "Error no controlado en {} {}",
                request.getMethod(),
                request.getRequestURI(),
                error);

        notificar(error, request);

        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(respuesta(
                        HttpStatus.INTERNAL_SERVER_ERROR,
                        "Ocurrió un error interno. El equipo administrador "
                                + "fue notificado."));
    }

    private void notificar(Exception error, HttpServletRequest request) {
        try {
            alertaErrorService.registrarError(
                    error.getClass().getSimpleName(),
                    request.getMethod() + " " + request.getRequestURI(),
                    error.getMessage() == null
                            ? "Error sin mensaje"
                            : error.getMessage(),
                    error,
                    origenIp(request));
        } catch (Exception alertaError) {
            logger.error(
                    "No se pudo notificar el error al administrador: {}",
                    alertaError.getMessage());
        }
    }

    private static Map<String, Object> respuesta(
            HttpStatus estado,
            String mensaje) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("timestamp", java.time.LocalDateTime.now().toString());
        body.put("status", estado.value());
        body.put("error", estado.getReasonPhrase());
        body.put("mensaje", mensaje);
        return body;
    }

    private static String origenIp(HttpServletRequest request) {
        String forwarded = request.getHeader("X-Forwarded-For");
        if (forwarded != null && !forwarded.isBlank()) {
            return forwarded.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
