package com.ergovida.backend.repository;

import java.time.LocalDate;

import org.springframework.data.jpa.repository.JpaRepository;

import com.ergovida.backend.model.RecordatorioGlobalEnvio;

public interface RecordatorioGlobalEnvioRepository
        extends JpaRepository<RecordatorioGlobalEnvio, Long> {

    boolean existsByRecordatorioIdAndUsuarioIdAndFecha(
            Long recordatorioId,
            Long usuarioId,
            LocalDate fecha);
}
