package com.ergovida.backend.service;

import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import com.ergovida.backend.model.RecordatorioEnvioHistorial;
import com.ergovida.backend.model.RecordatorioGlobal;
import com.ergovida.backend.model.RecordatorioGlobalEnvio;
import com.ergovida.backend.model.User;
import com.ergovida.backend.repository.RecordatorioGlobalEnvioRepository;
import com.ergovida.backend.repository.RecordatorioGlobalRepository;
import com.ergovida.backend.repository.UserRepository;

@Service
@ConditionalOnProperty(
        name = "ergovida.recordatorios.scheduler.enabled",
        havingValue = "true",
        matchIfMissing = true)
public class RecordatorioGlobalScheduler {

    private static final Logger logger =
            LoggerFactory.getLogger(RecordatorioGlobalScheduler.class);

    private static final long VENTANA_MINUTOS = 10;
    private static final int MAX_DETALLES_ALERTA = 10;

    private final RecordatorioGlobalRepository recordatorioRepository;
    private final RecordatorioGlobalEnvioRepository envioRepository;
    private final UserRepository userRepository;
    private final EmailService emailService;
    private final RecordatorioEntregaService entregaService;
    private final AlertaErrorService alertaErrorService;

    public RecordatorioGlobalScheduler(
            RecordatorioGlobalRepository recordatorioRepository,
            RecordatorioGlobalEnvioRepository envioRepository,
            UserRepository userRepository,
            EmailService emailService) {
        this(
                recordatorioRepository,
                envioRepository,
                userRepository,
                emailService,
                null,
                null);
    }

    @Autowired
    public RecordatorioGlobalScheduler(
            RecordatorioGlobalRepository recordatorioRepository,
            RecordatorioGlobalEnvioRepository envioRepository,
            UserRepository userRepository,
            EmailService emailService,
            RecordatorioEntregaService entregaService,
            AlertaErrorService alertaErrorService) {
        this.recordatorioRepository = recordatorioRepository;
        this.envioRepository = envioRepository;
        this.userRepository = userRepository;
        this.emailService = emailService;
        this.entregaService = entregaService;
        this.alertaErrorService = alertaErrorService;
    }

    @Scheduled(cron = "0 * * * * *", zone = "America/Bogota")
    public void enviarRecordatoriosGlobales() {
        LocalDateTime ahora = LocalDateTime.now(ZoneId.of("America/Bogota"));
        LocalDate hoy = ahora.toLocalDate();
        LocalTime horaActual = ahora.toLocalTime();

        List<RecordatorioGlobal> recordatorios =
                recordatorioRepository.findByActivoTrueOrderByHoraAsc();
        if (recordatorios.isEmpty()) return;

        List<User> usuarios = userRepository.findAll();

        int fallos = 0;
        StringBuilder detalles = new StringBuilder();

        for (RecordatorioGlobal recordatorio : recordatorios) {
            LocalTime hora = recordatorio.getHora();
            if (hora == null || !aplicaHoy(recordatorio, hoy)) {
                continue;
            }

            long minutosTarde = Duration.between(hora, horaActual).toMinutes();
            if (minutosTarde < 0 || minutosTarde > VENTANA_MINUTOS) {
                continue;
            }

            for (User usuario : usuarios) {
                String canal = normalizarCanal(recordatorio.getCanal());
                boolean enviarCorreo = !RecordatorioGlobal.CANAL_PUSH.equals(canal)
                        && puedeRecibirCorreo(usuario);
                boolean enviarPush = !RecordatorioGlobal.CANAL_CORREO.equals(canal)
                        && puedeRecibirPush(usuario);

                if (!enviarCorreo && !enviarPush) {
                    continue;
                }

                if (enviarPush
                        && entregaService != null
                        && !entregaService.pushYaEnviado(
                                RecordatorioEnvioHistorial.TIPO_GLOBAL,
                                recordatorio.getId(),
                                null,
                                usuario.getId(),
                                hoy)) {

                    RecordatorioEntregaService.ResultadoEnvioPush resultado =
                            entregaService.enviarPush(
                                    RecordatorioEnvioHistorial.TIPO_GLOBAL,
                                    recordatorio.getId(),
                                    null,
                                    usuario.getId(),
                                    "ErgoVida - Recordatorio de bienestar",
                                    mensajePush(recordatorio),
                                    hoy);

                    if (resultado.fallos() > 0) {
                        fallos += resultado.fallos();
                        agregarDetalle(
                                detalles,
                                "Push a " + usuario.getCorreo() + ": "
                                        + resultado.fallos() + " fallo(s)");
                    }
                }

                if (!enviarCorreo) {
                    continue;
                }

                boolean yaEnviado =
                        envioRepository.existsByRecordatorioIdAndUsuarioIdAndFecha(
                                recordatorio.getId(),
                                usuario.getId(),
                                hoy);
                if (yaEnviado) continue;

                try {
                    emailService.enviarRecordatorioGlobal(
                            usuario.getCorreo().trim(),
                            usuario.getNombre(),
                            recordatorio.getMensaje(),
                            hora);
                    envioRepository.save(new RecordatorioGlobalEnvio(
                            recordatorio.getId(),
                            usuario.getId(),
                            hoy));
                    if (entregaService != null) {
                        entregaService.registrarCorreo(
                                RecordatorioEnvioHistorial.TIPO_GLOBAL,
                                recordatorio.getId(),
                                null,
                                usuario.getId(),
                                true,
                                null,
                                hoy);
                    }
                    logger.info(
                            "Recordatorio global '{}' enviado a {}",
                            recordatorio.getMensaje(),
                            usuario.getCorreo());
                } catch (Exception error) {
                    fallos++;
                    if (entregaService != null) {
                        entregaService.registrarCorreo(
                                RecordatorioEnvioHistorial.TIPO_GLOBAL,
                                recordatorio.getId(),
                                null,
                                usuario.getId(),
                                false,
                                error.getMessage(),
                                hoy);
                    }
                    agregarDetalle(
                            detalles,
                            "Correo a " + usuario.getCorreo() + ": "
                                    + error.getMessage());
                    logger.error(
                            "No se pudo enviar el recordatorio global a {}: {}",
                            usuario.getCorreo(),
                            error.getMessage());
                }
            }
        }

        if (fallos > 0 && alertaErrorService != null) {
            alertaErrorService.notificarFalloRecordatorios(
                    detalles.toString(),
                    fallos);
        }
    }

    private String normalizarCanal(String canal) {
        if (canal == null || canal.isBlank()) {
            return RecordatorioGlobal.CANAL_AMBOS;
        }
        return canal.trim().toUpperCase(java.util.Locale.ROOT);
    }

    private boolean puedeRecibirCorreo(User usuario) {
        return !Boolean.FALSE.equals(usuario.getActivo())
                && !Boolean.FALSE.equals(usuario.getRecordatorios())
                && !Boolean.FALSE.equals(usuario.getRecordatoriosCorreo())
                && usuario.getCorreo() != null
                && !usuario.getCorreo().isBlank();
    }

    private boolean puedeRecibirPush(User usuario) {
        return !Boolean.FALSE.equals(usuario.getActivo())
                && !Boolean.FALSE.equals(usuario.getRecordatorios())
                && !Boolean.FALSE.equals(usuario.getNotificaciones())
                && usuario.getId() != null;
    }

    private String mensajePush(RecordatorioGlobal recordatorio) {
        String mensaje = recordatorio.getMensaje();
        return mensaje == null || mensaje.isBlank()
                ? "Es momento de tu pausa activa. Abre ErgoVida para continuar."
                : mensaje.trim();
    }

    private void agregarDetalle(StringBuilder detalles, String detalle) {
        long lineas = detalles.chars().filter(c -> c == '\n').count();
        if (lineas >= MAX_DETALLES_ALERTA) {
            return;
        }
        if (detalles.length() > 0) {
            detalles.append('\n');
        }
        detalles.append(detalle);
    }

    private boolean aplicaHoy(RecordatorioGlobal recordatorio, LocalDate hoy) {
        String dias = recordatorio.getDiasSemana();
        if (dias == null || dias.isBlank()) return true;

        Set<Integer> diasConfigurados = java.util.Arrays.stream(dias.split(","))
                .map(String::trim)
                .filter(valor -> !valor.isEmpty())
                .map(valor -> {
                    try {
                        return Integer.parseInt(valor);
                    } catch (NumberFormatException error) {
                        return null;
                    }
                })
                .filter(valor -> valor != null)
                .collect(Collectors.toSet());

        return diasConfigurados.isEmpty()
                || diasConfigurados.contains(hoy.getDayOfWeek().getValue());
    }
}
