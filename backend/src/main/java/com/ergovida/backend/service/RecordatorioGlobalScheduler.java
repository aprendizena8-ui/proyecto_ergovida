package com.ergovida.backend.service;

import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

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

    private final RecordatorioGlobalRepository recordatorioRepository;
    private final RecordatorioGlobalEnvioRepository envioRepository;
    private final UserRepository userRepository;
    private final EmailService emailService;

    public RecordatorioGlobalScheduler(
            RecordatorioGlobalRepository recordatorioRepository,
            RecordatorioGlobalEnvioRepository envioRepository,
            UserRepository userRepository,
            EmailService emailService) {
        this.recordatorioRepository = recordatorioRepository;
        this.envioRepository = envioRepository;
        this.userRepository = userRepository;
        this.emailService = emailService;
    }

    @Scheduled(fixedDelay = 30000, initialDelay = 15000)
    public void enviarRecordatoriosGlobales() {
        LocalDateTime ahora = LocalDateTime.now();
        LocalDate hoy = ahora.toLocalDate();
        LocalTime horaActual = ahora.toLocalTime();

        List<RecordatorioGlobal> recordatorios =
                recordatorioRepository.findByActivoTrueOrderByHoraAsc();
        if (recordatorios.isEmpty()) return;

        List<User> usuarios = userRepository.findAll();

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
                if (!puedeRecibirCorreo(usuario)) continue;

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
                    logger.info(
                            "Recordatorio global '{}' enviado a {}",
                            recordatorio.getMensaje(),
                            usuario.getCorreo());
                } catch (Exception error) {
                    logger.error(
                            "No se pudo enviar el recordatorio global a {}: {}",
                            usuario.getCorreo(),
                            error.getMessage());
                }
            }
        }
    }

    private boolean puedeRecibirCorreo(User usuario) {
        return Boolean.TRUE.equals(usuario.getActivo())
                && !Boolean.FALSE.equals(usuario.getRecordatorios())
                && !Boolean.FALSE.equals(usuario.getRecordatoriosCorreo())
                && usuario.getCorreo() != null
                && !usuario.getCorreo().isBlank();
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
