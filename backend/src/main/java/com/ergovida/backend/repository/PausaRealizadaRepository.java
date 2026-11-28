package com.ergovida.backend.repository;

import com.ergovida.backend.model.PausaRealizada;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

public interface PausaRealizadaRepository extends JpaRepository<PausaRealizada, Long> {
    List<PausaRealizada> findByUsuarioId(Long usuarioId);

    @Transactional
    long deleteByUsuarioId(Long usuarioId);

    @Query("SELECT p.usuarioId, COUNT(p) FROM PausaRealizada p WHERE p.usuarioId IS NOT NULL GROUP BY p.usuarioId ORDER BY COUNT(p) DESC")
    List<Object[]> contarPausasPorUsuario();

    /** Ranking SST: exclusivamente ejercicios detectados y confirmados. */
    @Query("SELECT p.usuarioId, COUNT(p) FROM PausaRealizada p "
            + "WHERE p.usuarioId IS NOT NULL AND p.tipo = :tipo "
            + "AND p.completada = true GROUP BY p.usuarioId ORDER BY COUNT(p) DESC")
    List<Object[]> contarEjerciciosDetectadosPorUsuario(@Param("tipo") String tipo);
}
