package com.ergovida.backend.repository;

import com.ergovida.backend.model.Estadistica;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface EstadisticaRepository extends JpaRepository<Estadistica, Long> {
    List<Estadistica> findByUsuarioId(Long usuarioId);
    Optional<Estadistica> findByUsuarioIdAndFecha(Long usuarioId, LocalDate fecha);
}