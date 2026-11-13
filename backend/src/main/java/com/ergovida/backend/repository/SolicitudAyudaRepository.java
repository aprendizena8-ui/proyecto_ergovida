package com.ergovida.backend.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.ergovida.backend.model.SolicitudAyuda;

public interface SolicitudAyudaRepository
        extends JpaRepository<SolicitudAyuda, Long> {

    List<SolicitudAyuda> findByUsuarioIdOrderByFechaCreacionDesc(Long usuarioId);

    List<SolicitudAyuda> findAllByOrderByFechaCreacionDesc();

    List<SolicitudAyuda> findByEstadoOrderByFechaCreacionDesc(String estado);
}
