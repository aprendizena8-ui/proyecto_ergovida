package com.ergovida.backend.repository;

import com.ergovida.backend.model.Horario;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface HorarioRepository extends JpaRepository<Horario, Long> {
    List<Horario> findByUsuarioId(Long usuarioId);
}