package com.ergovida.backend.service;

import java.util.Arrays;
import java.util.Locale;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

/**
 * Resuelve el rol inicial de una cuenta a partir de su correo.
 *
 * El rol queda guardado en la columna `rol` de la tabla `usuarios`; por eso
 * despues se puede modificar desde la base de datos o desde el panel
 * administrador sin cambiar el codigo.
 */
@Service
public class RoleService {

    public static final String ADMINISTRADOR = "ADMINISTRADOR";
    public static final String LIDER_SST = "LIDER_SST";
    public static final String USUARIO = "USUARIO";

    private final Set<String> correosAdministradores;
    private final Set<String> correosLideresSst;

    public RoleService(
            @Value("${ergovida.auth.admin-emails:ergovida.sena@gmail.com}") String adminEmails,
            @Value("${ergovida.auth.leader-emails:kmorenoa@sena.edu.co,aprendizena8@gmail.com}") String leaderEmails) {
        this.correosAdministradores = parsearCorreos(adminEmails);
        this.correosLideresSst = parsearCorreos(leaderEmails);
    }

    public String rolParaCorreo(String correo) {
        String normalizado = normalizarCorreo(correo);
        if (correosAdministradores.contains(normalizado)) {
            return ADMINISTRADOR;
        }
        if (correosLideresSst.contains(normalizado)) {
            return LIDER_SST;
        }
        return USUARIO;
    }

    public static String normalizarRol(String rol) {
        if (rol == null) {
            return "";
        }
        String valor = rol.trim().toUpperCase(Locale.ROOT).replace('-', '_');
        valor = valor.replaceAll("\\s+", "_");
        if ("LIDER_SST".equals(valor) || "LÍDER_SST".equals(valor)) {
            return LIDER_SST;
        }
        return valor;
    }

    public static boolean esRol(String rol, String esperado) {
        return normalizarRol(rol).equals(normalizarRol(esperado));
    }

    private static Set<String> parsearCorreos(String valor) {
        if (valor == null || valor.isBlank()) {
            return Set.of();
        }
        return Arrays.stream(valor.split("[,;\\s]+"))
                .map(RoleService::normalizarCorreo)
                .filter(correo -> !correo.isEmpty())
                .collect(Collectors.toUnmodifiableSet());
    }

    private static String normalizarCorreo(String correo) {
        return correo == null ? "" : correo.trim().toLowerCase(Locale.ROOT);
    }
}
