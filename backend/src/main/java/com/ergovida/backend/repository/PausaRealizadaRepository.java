package com.ergovida.backend.repository;

import com.ergovida.backend.model.PausaRealizada;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface PausaRealizadaRepository extends JpaRepository<PausaRealizada, Long> {
    List<PausaRealizada> findByUsuarioId(Long usuarioId);
}