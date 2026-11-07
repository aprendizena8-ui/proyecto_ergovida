package com.ergovida.backend.repository;

import com.ergovida.backend.model.Horario;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalTime;
import java.util.List;

public interface HorarioRepository extends JpaRepository<Horario, Long> {
    List<Horario> findByUsuarioId(Long usuarioId);

    @Transactional
    long deleteByUsuarioId(Long usuarioId);

    List<Horario> findByHoraBetween(LocalTime inicio, LocalTime fin);
}