package com.ergovida.backend.repository;

import com.ergovida.backend.model.Estadistica;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface EstadisticaRepository extends JpaRepository<Estadistica, Long> {
    List<Estadistica> findByUsuarioId(Long usuarioId);
}