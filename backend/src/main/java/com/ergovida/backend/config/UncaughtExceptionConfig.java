package com.ergovida.backend.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

import com.ergovida.backend.service.AlertaErrorService;

/**
 * Captura excepciones no controladas en hilos del servidor y las notifica a
 * los administradores. Los errores de peticiones HTTP ya se manejan en
 * GlobalExceptionHandler.
 */
@Component
public class UncaughtExceptionConfig implements ApplicationRunner {

    private static final Logger logger =
            LoggerFactory.getLogger(UncaughtExceptionConfig.class);

    private final AlertaErrorService alertaErrorService;

    public UncaughtExceptionConfig(AlertaErrorService alertaErrorService) {
        this.alertaErrorService = alertaErrorService;
    }

    @Override
    public void run(ApplicationArguments args) {
        Thread.setDefaultUncaughtExceptionHandler((thread, error) -> {
            String modulo = "Hilo " + thread.getName();
            logger.error("Excepción no controlada en {}", modulo, error);
            try {
                alertaErrorService.registrarError(
                        error.getClass().getSimpleName(),
                        modulo,
                        error.getMessage() == null
                                ? "Error sin mensaje"
                                : error.getMessage(),
                        error,
                        "servidor");
            } catch (Exception alertaError) {
                logger.error(
                        "No se pudo notificar la excepción no controlada: {}",
                        alertaError.getMessage());
            }
        });
    }
}
