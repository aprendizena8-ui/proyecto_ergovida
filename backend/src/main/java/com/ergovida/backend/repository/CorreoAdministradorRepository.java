package com.ergovida.backend.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.ergovida.backend.model.CorreoAdministrador;

public interface CorreoAdministradorRepository
        extends JpaRepository<CorreoAdministrador, Long> {

    List<CorreoAdministrador> findAllByOrderByCorreoAsc();

    List<CorreoAdministrador> findAllByActivoTrueOrderByCorreoAsc();

    Optional<CorreoAdministrador> findByCorreoIgnoreCase(String correo);

    boolean existsByCorreoIgnoreCase(String correo);
}
