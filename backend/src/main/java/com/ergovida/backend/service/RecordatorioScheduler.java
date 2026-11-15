package com.ergovida.backend.service;

import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import com.ergovida.backend.model.Horario;
import com.ergovida.backend.model.RecordatorioEnvioHistorial;
import com.ergovida.backend.model.User;
import com.ergovida.backend.repository.HorarioRepository;
import com.ergovida.backend.repository.UserRepository;

@Service
@ConditionalOnProperty(
        name = "ergovida.recordatorios.scheduler.enabled",
        havingValue = "true",
        matchIfMissing = true)
public class RecordatorioScheduler {

    private static final Logger logger =
            LoggerFactory.getLogger(RecordatorioScheduler.class);

    /** Margen para enviar un recordatorio aunque el servidor arranque un poco tarde. */
    private static final long VENTANA_MINUTOS = 10;
    private static final int MAX_DETALLES_ALERTA = 10;

    private final HorarioRepository horarioRepository;
    private final UserRepository userRepository;
    private final EmailService emailService;
    private final RecordatorioEntregaService entregaService;
    private final AlertaErrorService alertaErrorService;

    public RecordatorioScheduler(
            HorarioRepository horarioRepository,
            UserRepository userRepository,
            EmailService emailService) {
        this(horarioRepository, userRepository, emailService, null, null);
    }

    @Autowired
    public RecordatorioScheduler(
            HorarioRepository horarioRepository,
            UserRepository userRepository,
            EmailService emailService,
            RecordatorioEntregaService entregaService,
            AlertaErrorService alertaErrorService) {
        this.horarioRepository = horarioRepository;
        this.userRepository = userRepository;
        this.emailService = emailService;
        this.entregaService = entregaService;
        this.alertaErrorService = alertaErrorService;
    }

    @Scheduled(cron = "0 * * * * *", zone = "America/Bogota")
    public void enviarRecordatoriosPendientes() {
        LocalDateTime ahora = LocalDateTime.now();
        LocalDate hoy = ahora.toLocalDate();
        LocalTime horaActual = ahora.toLocalTime();

        List<Horario> horarios = horarioRepository.findAll();

        int fallos = 0;
        StringBuilder detalles = new StringBuilder();

        for (Horario horario : horarios) {
            LocalTime hora = horario.getHora();
            if (hora == null
                    || horario.getUsuarioId() == null
                    || hoy.equals(horario.getUltimoEnvio())) {
                continue;
            }

            long minutosTarde = Duration.between(hora, horaActual).toMinutes();
            if (minutosTarde < 0 || minutosTarde > VENTANA_MINUTOS) {
                continue;
            }

            Optional<User> usuarioOpt =
                    userRepository.findById(horario.getUsuarioId());
            if (usuarioOpt.isEmpty()) {
                continue;
            }

            User usuario = usuarioOpt.get();
            if (Boolean.FALSE.equals(usuario.getActivo())
                    || Boolean.FALSE.equals(usuario.getRecordatorios())) {
                continue;
            }

            boolean correoHabilitado =
                    !Boolean.FALSE.equals(usuario.getRecordatoriosCorreo())
                    && usuario.getCorreo() != null
                    && !usuario.getCorreo().isBlank();
            boolean pushHabilitado =
                    !Boolean.FALSE.equals(usuario.getNotificaciones());

            if (!correoHabilitado && !pushHabilitado) {
                continue;
            }

            boolean entregado = false;
            boolean correoFallido = false;

            if (pushHabilitado
                    && entregaService != null
                    && !entregaService.pushYaEnviado(
                            RecordatorioEnvioHistorial.TIPO_PERSONAL,
                            null,
                            horario.getId(),
                            usuario.getId(),
                            hoy)) {

                RecordatorioEntregaService.ResultadoEnvioPush resultado =
                        entregaService.enviarPush(
                                RecordatorioEnvioHistorial.TIPO_PERSONAL,
                                null,
                                horario.getId(),
                                usuario.getId(),
                                "ErgoVida - Tu pausa activa",
                                "Es momento de tu pausa activa de las "
                                        + hora + ". Abre ErgoVida para continuar.",
                                hoy);

                if (resultado.exitos() > 0) {
                    entregado = true;
                }
                if (resultado.fallos() > 0) {
                    fallos += resultado.fallos();
                    agregarDetalle(
                            detalles,
                            "Push a " + usuario.getCorreo() + ": "
                                    + resultado.fallos() + " fallo(s)");
                }
            }

            if (correoHabilitado) {
                boolean correoYaEnviado = entregaService != null
                        && entregaService.correoYaEnviado(
                                RecordatorioEnvioHistorial.TIPO_PERSONAL,
                                null,
                                horario.getId(),
                                usuario.getId(),
                                hoy);

                if (!correoYaEnviado) {
                    try {
                        emailService.enviarRecordatorioPausa(
                                usuario.getCorreo().trim(),
                                usuario.getNombre(),
                                hora);
                        entregado = true;
                        if (entregaService != null) {
                            entregaService.registrarCorreo(
                                    RecordatorioEnvioHistorial.TIPO_PERSONAL,
                                    null,
                                    horario.getId(),
                                    usuario.getId(),
                                    true,
                                    null,
                                    hoy);
                        }
                        logger.info(
                                "Recordatorio diario enviado a {} para las {}",
                                usuario.getCorreo(),
                                hora);
                    } catch (Exception error) {
                        correoFallido = true;
                        fallos++;
                        if (entregaService != null) {
                            entregaService.registrarCorreo(
                                    RecordatorioEnvioHistorial.TIPO_PERSONAL,
                                    null,
                                    horario.getId(),
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
                                "No se pudo enviar el recordatorio a {}: {}",
                                usuario.getCorreo(),
                                error.getMessage());
                    }
                } else {
                    entregado = true;
                }
            }

            if (entregado && !correoFallido) {
                horario.setUltimoEnvio(hoy);
                horarioRepository.save(horario);
            }
        }

        if (fallos > 0 && alertaErrorService != null) {
            alertaErrorService.notificarFalloRecordatorios(
                    detalles.toString(),
                    fallos);
        }
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
}
