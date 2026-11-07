package com.ergovida.backend.config;

import java.util.Locale;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;

import com.ergovida.backend.model.User;
import com.ergovida.backend.repository.UserRepository;
import com.ergovida.backend.service.RoleService;

import jakarta.servlet.http.HttpServletRequest;

/**
 * Valida en el servidor la identidad y el rol enviados por la app.
 *
 * La app adjunta `X-Usuario-Id` y `X-Usuario-Correo` en cada llamada a la API.
 * El rol siempre se consulta en MySQL, nunca se confia en un rol enviado por
 * el cliente.
 */
@Component
public class RoleGuard {

    public static final String HEADER_USUARIO_ID = "X-Usuario-Id";
    public static final String HEADER_USUARIO_CORREO = "X-Usuario-Correo";

    private final UserRepository userRepository;

    public RoleGuard(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public User requireUser(HttpServletRequest request) {
        User usuario = buscarUsuario(request);

        if (usuario == null) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "Sesión no válida. Inicia sesión nuevamente.");
        }

        if (Boolean.FALSE.equals(usuario.getActivo())) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "La cuenta está deshabilitada.");
        }

        return usuario;
    }

    public User requireRole(HttpServletRequest request, String... rolesPermitidos) {
        User usuario = requireUser(request);
        String rol = RoleService.normalizarRol(usuario.getRol());

        for (String permitido : rolesPermitidos) {
            if (rol.equals(RoleService.normalizarRol(permitido))) {
                return usuario;
            }
        }

        throw new ResponseStatusException(
                HttpStatus.FORBIDDEN,
                "No tienes permisos para realizar esta acción.");
    }

    public boolean esAdmin(User usuario) {
        return RoleService.esRol(usuario.getRol(), RoleService.ADMINISTRADOR);
    }

    public boolean esLiderSst(User usuario) {
        return RoleService.esRol(usuario.getRol(), RoleService.LIDER_SST);
    }

    private User buscarUsuario(HttpServletRequest request) {
        String idHeader = request.getHeader(HEADER_USUARIO_ID);
        String correoHeader = request.getHeader(HEADER_USUARIO_CORREO);

        if (idHeader == null || idHeader.isBlank()
                || correoHeader == null || correoHeader.isBlank()) {
            return null;
        }

        try {
            Long id = Long.parseLong(idHeader.trim());
            String correo = correoHeader.trim().toLowerCase(Locale.ROOT);
            return userRepository.findById(id)
                    .filter(usuario -> usuario.getCorreo() != null
                            && usuario.getCorreo().trim().toLowerCase(Locale.ROOT).equals(correo))
                    .orElse(null);
        } catch (NumberFormatException ignored) {
            return null;
        }
    }
}
