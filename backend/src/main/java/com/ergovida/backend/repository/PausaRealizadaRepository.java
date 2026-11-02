package com.ergovida.backend.repository;

import com.ergovida.backend.model.PausaRealizada;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import java.util.List;

public interface PausaRealizadaRepository extends JpaRepository<PausaRealizada, Long> {
    List<PausaRealizada> findByUsuarioId(Long usuarioId);

    @Query("SELECT p.usuarioId, COUNT(p) FROM PausaRealizada p WHERE p.usuarioId IS NOT NULL GROUP BY p.usuarioId ORDER BY COUNT(p) DESC")
    List<Object[]> contarPausasPorUsuario();
}