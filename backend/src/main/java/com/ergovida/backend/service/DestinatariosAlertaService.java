package com.ergovida.backend.service;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.ergovida.backend.model.CorreoAdministrador;
import com.ergovida.backend.repository.CorreoAdministradorRepository;

/**
 * Resuelve los destinatarios de las alertas: primero usa los correos
 * configurados por el administrador en MySQL y, si aun no hay ninguno,
 * recurre a los correos de administrador definidos en configuracion.
 */
@Service
public class DestinatariosAlertaService {

    private static final Logger logger =
            LoggerFactory.getLogger(DestinatariosAlertaService.class);

    private final CorreoAdministradorRepository repository;
    private final List<String> correosRespaldo;

    public DestinatariosAlertaService(
            CorreoAdministradorRepository repository,
            @Value("${ergovida.alertas.correos-respaldo:${ergovida.auth.admin-emails:}}")
            String correosRespaldo) {
        this.repository = repository;
        this.correosRespaldo = parsear(correosRespaldo);
    }

    public List<String> obtenerCorreos() {
        Set<String> correos = new LinkedHashSet<>();

        try {
            for (CorreoAdministrador configurado
                    : repository.findAllByActivoTrueOrderByCorreoAsc()) {
                agregar(correos, configurado.getCorreo());
            }
        } catch (Exception error) {
            logger.warn(
                    "No se pudieron leer los correos de administradores desde MySQL: {}",
                    error.getMessage());
        }

        if (correos.isEmpty()) {
            correos.addAll(correosRespaldo);
        }

        return new ArrayList<>(correos);
    }

    private static List<String> parsear(String valor) {
        List<String> resultado = new ArrayList<>();
        if (valor == null || valor.isBlank()) {
            return resultado;
        }
        for (String parte : valor.split("[,;\\s]+")) {
            String correo = normalizar(parte);
            if (!correo.isEmpty()) {
                resultado.add(correo);
            }
        }
        return resultado;
    }

    private static void agregar(Set<String> correos, String correo) {
        String normalizado = normalizar(correo);
        if (!normalizado.isEmpty()) {
            correos.add(normalizado);
        }
    }

    private static String normalizar(String correo) {
        return correo == null ? "" : correo.trim().toLowerCase(Locale.ROOT);
    }
}
