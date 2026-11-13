package com.ergovida.backend.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.ergovida.backend.model.AlertaError;

public interface AlertaErrorRepository
        extends JpaRepository<AlertaError, Long> {

    Optional<AlertaError> findByClave(String clave);

    List<AlertaError> findAllByOrderByUltimoEnvioDesc();
}
