package com.ergovida.backend.repository;

import com.ergovida.backend.model.CodigoVerificacion;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface CodigoVerificacionRepository extends JpaRepository<CodigoVerificacion, Long> {
    Optional<CodigoVerificacion> findByCorreoAndCodigoAndUsadoFalse(String correo, String codigo);
    Optional<CodigoVerificacion> findTopByCorreoOrderByFechaCreacionDesc(String correo);
}
