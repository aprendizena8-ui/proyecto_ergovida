package com.ergovida.backend.service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import com.ergovida.backend.model.Horario;
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

    private final HorarioRepository horarioRepository;
    private final UserRepository userRepository;
    private final EmailService emailService;

    public RecordatorioScheduler(
            HorarioRepository horarioRepository,
            UserRepository userRepository,
            EmailService emailService) {
        this.horarioRepository = horarioRepository;
        this.userRepository = userRepository;
        this.emailService = emailService;
    }

    @Scheduled(fixedDelay = 30000, initialDelay = 10000)
    public void enviarRecordatoriosPendientes() {
        LocalDateTime ahora = LocalDateTime.now();
        LocalDate hoy = ahora.toLocalDate();
        LocalTime inicioMinuto = ahora.toLocalTime().withSecond(0).withNano(0);
        LocalTime finMinuto = inicioMinuto.plusSeconds(59).withNano(999_999_999);

        List<Horario> horarios =
                horarioRepository.findByHoraBetween(inicioMinuto, finMinuto);

        for (Horario horario : horarios) {
            if (horario.getUsuarioId() == null
                    || hoy.equals(horario.getUltimoEnvio())) {
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

            String correo = usuario.getCorreo();
            if (correo == null || correo.isBlank()) {
                continue;
            }

            try {
                emailService.enviarRecordatorioPausa(
                        correo,
                        usuario.getNombre(),
                        horario.getHora());
                horario.setUltimoEnvio(hoy);
                horarioRepository.save(horario);
                logger.info(
                        "Recordatorio enviado a {} para las {}",
                        correo,
                        horario.getHora());
            } catch (Exception error) {
                logger.error(
                        "No se pudo enviar el recordatorio a {}: {}",
                        correo,
                        error.getMessage());
            }
        }
    }
}
