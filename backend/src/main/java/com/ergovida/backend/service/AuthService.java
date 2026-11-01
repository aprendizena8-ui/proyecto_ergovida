package com.ergovida.backend.service;

import java.util.Locale;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import com.ergovida.backend.dto.LoginResponse;
import com.ergovida.backend.model.NivelLog;
import com.ergovida.backend.model.User;
import com.ergovida.backend.repository.UserRepository;

/**
 * Servicio de autenticación.
 *
 * Implementa HU-01 (Registro), HU-02 (Login) y HU-04 (estado activo).
 */
@Service
public class AuthService {

    private final UserRepository repository;
    private final BCryptPasswordEncoder encoder;
    private final SystemLogService systemLogService;

    public AuthService(
            UserRepository repository,
            BCryptPasswordEncoder encoder,
            SystemLogService systemLogService) {

        this.repository = repository;
        this.encoder = encoder;
        this.systemLogService = systemLogService;
    }

    /**
     * HU-01: Registro de usuarios.
     */
    public User registrar(User user) {

        String correo = normalizarCorreo(user.getCorreo());
        if (correo.isEmpty()) {
            throw new RuntimeException("El correo es obligatorio.");
        }

        if (user.getNombre() == null || user.getNombre().isBlank()) {
            throw new RuntimeException("El nombre es obligatorio.");
        }

        if (user.getPassword() == null || user.getPassword().length() < 6) {
            throw new RuntimeException(
                    "La contraseña debe tener mínimo 6 caracteres."
            );
        }

        if (repository.existsByCorreo(correo)) {
            throw new RuntimeException("El correo ya está registrado. Intenta iniciar sesión.");
        }

        user.setNombre(user.getNombre().trim());
        user.setCorreo(correo);
        user.setPassword(encoder.encode(user.getPassword()));
        user.setRol("USUARIO");
        user.setActivo(true);

        return repository.save(user);
    }

    public boolean existeCorreo(String correo) {
        return repository.existsByCorreo(normalizarCorreo(correo));
    }

    /**
     * HU-02 + HU-04: Inicio de sesión.
     */
    public LoginResponse login(
            String correo,
            String password,
            String origenIp) {

        String correoNormalizado = normalizarCorreo(correo);

        User user = repository.findByCorreo(correoNormalizado)
                .orElseThrow(() -> new RuntimeException(
                        "Credenciales inválidas."
                ));

        if (Boolean.FALSE.equals(user.getActivo())) {
            throw new RuntimeException(
                    "La cuenta está deshabilitada. Contacte al administrador."
            );
        }

        if (!encoder.matches(password, user.getPassword())) {

            systemLogService.registrar(
                    NivelLog.WARNING,
                    origenIp,
                    "Intento de login fallido: contraseña incorrecta para el correo " + correoNormalizado
            );

            throw new RuntimeException("Credenciales inválidas.");
        }

        return new LoginResponse(
                user.getId(),
                user.getNombre(),
                user.getCorreo(),
                user.getRol()
        );
    }

    public void cambiarPassword(String correo, String nuevaPassword) {
        User user = repository.findByCorreo(normalizarCorreo(correo))
                .orElseThrow(() -> new RuntimeException("Usuario no encontrado"));
        if (nuevaPassword == null || nuevaPassword.length() < 6) {
            throw new RuntimeException("La contraseña debe tener mínimo 6 caracteres.");
        }
        user.setPassword(encoder.encode(nuevaPassword));
        repository.save(user);
    }

    private String normalizarCorreo(String correo) {
        return correo == null ? "" : correo.trim().toLowerCase(Locale.ROOT);
    }
}
