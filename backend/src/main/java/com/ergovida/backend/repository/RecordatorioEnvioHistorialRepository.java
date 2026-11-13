package com.ergovida.backend.repository;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.ergovida.backend.model.RecordatorioEnvioHistorial;

public interface RecordatorioEnvioHistorialRepository
        extends JpaRepository<RecordatorioEnvioHistorial, Long> {

    boolean existsByTipoRecordatorioAndRecordatorioIdAndUsuarioIdAndCanalAndFechaAndExitoTrue(
            String tipoRecordatorio,
            Long recordatorioId,
            Long usuarioId,
            String canal,
            LocalDate fecha);

    boolean existsByTipoRecordatorioAndHorarioIdAndUsuarioIdAndCanalAndFechaAndExitoTrue(
            String tipoRecordatorio,
            Long horarioId,
            Long usuarioId,
            String canal,
            LocalDate fecha);

    List<RecordatorioEnvioHistorial> findAllByOrderByFechaHoraDesc();

    List<RecordatorioEnvioHistorial> findByFechaBetweenOrderByFechaHoraDesc(
            LocalDate desde,
            LocalDate hasta);

    List<RecordatorioEnvioHistorial> findTop200ByExitoFalseOrderByFechaHoraDesc();

    long countByFechaAndExitoFalse(LocalDate fecha);

    List<RecordatorioEnvioHistorial> findByFechaHoraAfter(LocalDateTime desde);
}
