package com.ergovida.backend.service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import java.util.function.Consumer;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.ergovida.backend.model.AlertaError;
import com.ergovida.backend.model.NivelLog;
import com.ergovida.backend.repository.AlertaErrorRepository;

/**
 * Detecta errores del backend, los registra y notifica por correo a los
 * administradores. Agrupa errores identicos para no enviar mas de un correo
 * por intervalo (15 minutos por defecto).
 */
@Service
public class AlertaErrorService {

    private static final Logger logger =
            LoggerFactory.getLogger(AlertaErrorService.class);

    private final AlertaErrorRepository repository;
    private final DestinatariosAlertaService destinatariosService;
    private final EmailService emailService;
    private final SystemLogService systemLogService;
    private final long intervaloMinutos;

    private final Map<String, LocalDateTime> ultimosEnviosMemoria =
            new ConcurrentHashMap<>();

    public AlertaErrorService(
            AlertaErrorRepository repository,
            DestinatariosAlertaService destinatariosService,
            EmailService emailService,
            SystemLogService systemLogService,
            @Value("${ergovida.alertas.error.intervalo-minutos:15}")
            long intervaloMinutos) {
        this.repository = repository;
        this.destinatariosService = destinatariosService;
        this.emailService = emailService;
        this.systemLogService = systemLogService;
        this.intervaloMinutos = Math.max(1, intervaloMinutos);
    }

    public void registrarError(
            String tipo,
            String modulo,
            String mensaje,
            Throwable causa,
            String origenIp) {

        String detalle = construirDetalle(mensaje, causa);

        try {
            systemLogService.registrar(
                    NivelLog.ERROR,
                    origenIp,
                    "[" + valorSeguro(modulo) + "] " + detalle);
        } catch (Exception error) {
            logger.warn(
                    "No se pudo guardar el error en system_logs: {}",
                    error.getMessage());
        }

        notificar(
                clave(tipo, modulo, detalle),
                valorSeguro(tipo),
                valorSeguro(modulo),
                detalle);
    }

    public void registrarError(
            String tipo,
            String modulo,
            String mensaje,
            String origenIp) {
        registrarError(tipo, modulo, mensaje, null, origenIp);
    }

    public void notificarFalloRecordatorios(String resumen, int fallos) {
        String tipo = "Fallo de recordatorios";
        String modulo = "Scheduler de recordatorios";
        String clave = clave(tipo, modulo, "");
        String mensaje = "Envios fallidos: " + fallos + ". " + valorSeguro(resumen);

        int veces = registrarIntento(clave, tipo, modulo, mensaje);
        if (veces < 0) {
            return;
        }

        enviarCorreos(
                clave,
                correos -> emailService.enviarFalloRecordatorios(
                        correos,
                        mensaje,
                        fallos));
    }

    private void notificar(
            String clave,
            String tipo,
            String modulo,
            String mensaje) {

        int veces = registrarIntento(clave, tipo, modulo, mensaje);
        if (veces < 0) {
            return;
        }

        enviarCorreos(
                clave,
                correos -> emailService.enviarAlertaError(
                        correos,
                        tipo,
                        modulo,
                        mensaje,
                        veces));
    }

    /**
     * @return numero de veces que se ha visto el error si se debe enviar el
     *         correo, o -1 si debe agruparse y no enviarse todavia.
     */
    private int registrarIntento(
            String clave,
            String tipo,
            String modulo,
            String mensaje) {

        LocalDateTime ahora = LocalDateTime.now();

        try {
            Optional<AlertaError> existente = repository.findByClave(clave);
            AlertaError alerta;

            if (existente.isPresent()) {
                alerta = existente.get();
            } else {
                alerta = new AlertaError();
                alerta.setClave(clave);
                alerta.setPrimeraVez(ahora);
                alerta.setVeces(0);
            }

            int veces = (alerta.getVeces() == null ? 0 : alerta.getVeces()) + 1;
            alerta.setVeces(veces);
            alerta.setTipo(tipo);
            alerta.setModulo(modulo);
            alerta.setMensaje(mensaje);

            boolean enviar = alerta.getUltimoEnvio() == null
                    || Duration.between(
                            alerta.getUltimoEnvio(),
                            ahora).toMinutes() >= intervaloMinutos;

            if (enviar) {
                alerta.setUltimoEnvio(ahora);
            }
            repository.save(alerta);

            return enviar ? veces : -1;

        } catch (Exception error) {
            logger.warn(
                    "No se pudo agrupar la alerta en MySQL ({}). "
                            + "Se usara agrupacion en memoria.",
                    error.getMessage());

            LocalDateTime ultimo = ultimosEnviosMemoria.get(clave);
            boolean enviar = ultimo == null
                    || Duration.between(ultimo, ahora).toMinutes() >= intervaloMinutos;

            if (enviar) {
                ultimosEnviosMemoria.put(clave, ahora);
                return 1;
            }
            return -1;
        }
    }

    private void enviarCorreos(
            String clave,
            Consumer<List<String>> envio) {
        try {
            List<String> correos = destinatariosService.obtenerCorreos();
            if (correos.isEmpty()) {
                logger.warn(
                        "No hay correos de administradores configurados "
                                + "para enviar la alerta.");
                return;
            }
            envio.accept(correos);
        } catch (Exception error) {
            revertirUltimoEnvio(clave);
            logger.error(
                    "No se pudo enviar la alerta por correo: {}",
                    error.getMessage());
        }
    }

    private void revertirUltimoEnvio(String clave) {
        ultimosEnviosMemoria.remove(clave);
        try {
            repository.findByClave(clave).ifPresent(alerta -> {
                alerta.setUltimoEnvio(null);
                repository.save(alerta);
            });
        } catch (Exception error) {
            logger.warn(
                    "No se pudo reprogramar la alerta tras fallar el correo: {}",
                    error.getMessage());
        }
    }

    private static String construirDetalle(String mensaje, Throwable causa) {
        String base = valorSeguro(mensaje);
        if (causa == null) {
            return base;
        }
        String causaTexto = causa.getClass().getSimpleName();
        if (causa.getMessage() != null && !causa.getMessage().isBlank()) {
            causaTexto += ": " + causa.getMessage().trim();
        }
        if (base.equals("(sin dato)")) {
            return causaTexto;
        }
        return base + " | " + causaTexto;
    }

    private static String clave(String tipo, String modulo, String mensaje) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(
                    (valorSeguro(tipo) + "|" + valorSeguro(modulo) + "|"
                            + valorSeguro(mensaje)).getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hash);
        } catch (Exception error) {
            return Integer.toHexString(
                    (valorSeguro(tipo) + "|" + valorSeguro(modulo) + "|"
                            + valorSeguro(mensaje)).hashCode());
        }
    }

    private static String valorSeguro(String valor) {
        return valor == null || valor.isBlank() ? "(sin dato)" : valor.trim();
    }
}
