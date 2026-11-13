package com.ergovida.backend.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.ergovida.backend.model.DispositivoPush;

public interface DispositivoPushRepository
        extends JpaRepository<DispositivoPush, Long> {

    List<DispositivoPush> findByUsuarioIdAndActivoTrue(Long usuarioId);

    Optional<DispositivoPush> findByToken(String token);

    List<DispositivoPush> findByUsuarioId(Long usuarioId);
}
