package com.ergovida.backend.service;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import com.ergovida.backend.model.DispositivoPush;
import com.ergovida.backend.model.RecordatorioEnvioHistorial;
import com.ergovida.backend.repository.DispositivoPushRepository;
import com.ergovida.backend.repository.RecordatorioEnvioHistorialRepository;

/**
 * Centraliza el envio de notificaciones push y el registro del historial de
 * entregas (push y correo) de los recordatorios.
 */
@Service
public class RecordatorioEntregaService {

    private static final Logger logger =
            LoggerFactory.getLogger(RecordatorioEntregaService.class);

    private final DispositivoPushRepository dispositivoRepository;
    private final RecordatorioEnvioHistorialRepository historialRepository;
    private final FcmPushService pushService;

    public RecordatorioEntregaService(
            DispositivoPushRepository dispositivoRepository,
            RecordatorioEnvioHistorialRepository historialRepository,
            FcmPushService pushService) {
        this.dispositivoRepository = dispositivoRepository;
        this.historialRepository = historialRepository;
        this.pushService = pushService;
    }

    public boolean pushYaEnviado(
            String tipoRecordatorio,
            Long recordatorioId,
            Long horarioId,
            Long usuarioId,
            LocalDate fecha) {

        if (RecordatorioEnvioHistorial.TIPO_PERSONAL.equals(tipoRecordatorio)) {
            return historialRepository
                    .existsByTipoRecordatorioAndHorarioIdAndUsuarioIdAndCanalAndFechaAndExitoTrue(
                            tipoRecordatorio,
                            horarioId,
                            usuarioId,
                            RecordatorioEnvioHistorial.CANAL_PUSH,
                            fecha);
        }

        return historialRepository
                .existsByTipoRecordatorioAndRecordatorioIdAndUsuarioIdAndCanalAndFechaAndExitoTrue(
                        tipoRecordatorio,
                        recordatorioId,
                        usuarioId,
                        RecordatorioEnvioHistorial.CANAL_PUSH,
                        fecha);
    }

    public boolean correoYaEnviado(
            String tipoRecordatorio,
            Long recordatorioId,
            Long horarioId,
            Long usuarioId,
            LocalDate fecha) {

        if (RecordatorioEnvioHistorial.TIPO_PERSONAL.equals(tipoRecordatorio)) {
            return historialRepository
                    .existsByTipoRecordatorioAndHorarioIdAndUsuarioIdAndCanalAndFechaAndExitoTrue(
                            tipoRecordatorio,
                            horarioId,
                            usuarioId,
                            RecordatorioEnvioHistorial.CANAL_EMAIL,
                            fecha);
        }

        return historialRepository
                .existsByTipoRecordatorioAndRecordatorioIdAndUsuarioIdAndCanalAndFechaAndExitoTrue(
                        tipoRecordatorio,
                        recordatorioId,
                        usuarioId,
                        RecordatorioEnvioHistorial.CANAL_EMAIL,
                        fecha);
    }

    public ResultadoEnvioPush enviarPush(
            String tipoRecordatorio,
            Long recordatorioId,
            Long horarioId,
            Long usuarioId,
            String titulo,
            String cuerpo,
            LocalDate fecha) {

        if (!pushService.estaConfigurado()) {
            return ResultadoEnvioPush.vacio();
        }

        List<DispositivoPush> dispositivos =
                dispositivoRepository.findByUsuarioIdAndActivoTrue(usuarioId);

        if (dispositivos.isEmpty()) {
            return ResultadoEnvioPush.vacio();
        }

        Map<String, String> datos = Map.of(
                "tipo", tipoRecordatorio,
                "recordatorioId", String.valueOf(
                        recordatorioId == null ? 0 : recordatorioId),
                "horarioId", String.valueOf(
                        horarioId == null ? 0 : horarioId));

        int intentos = 0;
        int exitos = 0;
        int fallos = 0;

        for (DispositivoPush dispositivo : dispositivos) {
            FcmPushService.ResultadoPush resultado = pushService.enviar(
                    dispositivo.getToken(),
                    titulo,
                    cuerpo,
                    datos);

            if (resultado.omitido()) {
                break;
            }

            intentos++;

            registrar(
                    tipoRecordatorio,
                    recordatorioId,
                    horarioId,
                    usuarioId,
                    RecordatorioEnvioHistorial.CANAL_PUSH,
                    resultado.exito(),
                    resultado.error(),
                    fecha);

            if (resultado.exito()) {
                exitos++;
            } else {
                fallos++;
                if (resultado.tokenInvalido()) {
                    dispositivo.setActivo(false);
                    try {
                        dispositivoRepository.save(dispositivo);
                    } catch (Exception error) {
                        logger.warn(
                                "No se pudo desactivar el token push invalido: {}",
                                error.getMessage());
                    }
                }
            }
        }

        return new ResultadoEnvioPush(intentos, exitos, fallos);
    }

    public void registrarCorreo(
            String tipoRecordatorio,
            Long recordatorioId,
            Long horarioId,
            Long usuarioId,
            boolean exito,
            String error,
            LocalDate fecha) {

        registrar(
                tipoRecordatorio,
                recordatorioId,
                horarioId,
                usuarioId,
                RecordatorioEnvioHistorial.CANAL_EMAIL,
                exito,
                error,
                fecha);
    }

    private void registrar(
            String tipoRecordatorio,
            Long recordatorioId,
            Long horarioId,
            Long usuarioId,
            String canal,
            boolean exito,
            String error,
            LocalDate fecha) {

        try {
            historialRepository.save(new RecordatorioEnvioHistorial(
                    tipoRecordatorio,
                    recordatorioId,
                    horarioId,
                    usuarioId,
                    canal,
                    exito,
                    error,
                    fecha));
        } catch (Exception registroError) {
            logger.warn(
                    "No se pudo guardar el historial de recordatorios: {}",
                    registroError.getMessage());
        }
    }

    public record ResultadoEnvioPush(int intentos, int exitos, int fallos) {

        public static ResultadoEnvioPush vacio() {
            return new ResultadoEnvioPush(0, 0, 0);
        }

        public boolean huboIntento() {
            return intentos > 0;
        }
    }
}
