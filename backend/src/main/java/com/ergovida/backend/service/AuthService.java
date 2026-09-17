package com.ergovida.backend.service;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import com.ergovida.backend.dto.LoginResponse;
import com.ergovida.backend.model.User;
import com.ergovida.backend.repository.UserRepository;

/**
 * Servicio de autenticación.
 * Implementa HU-01 (Registro), HU-02 (Login) y HU-04 (estado activo).
 */
@Service
public class AuthService {

    private final UserRepository repository;
    private final BCryptPasswordEncoder encoder;

    public AuthService(UserRepository repository, BCryptPasswordEncoder encoder) {
        this.repository = repository;
        this.encoder = encoder;
    }

    /**
     * HU-01: Registro de usuarios.
     * - Valida que el correo no exista.
     * - Encripta la contraseña con BCrypt.
     * - Asigna rol USUARIO y estado activo = true por defecto.
     */
    public User registrar(User user) {
        if (user.getCorreo() == null || user.getCorreo().isBlank()) {
            throw new RuntimeException("El correo es obligatorio.");
        }
        if (user.getPassword() == null || user.getPassword().length() < 6) {
            throw new RuntimeException("La contraseña debe tener mínimo 6 caracteres.");
        }
        if (repository.existsByCorreo(user.getCorreo())) {
            throw new RuntimeException("El correo ya está registrado.");
        }

        user.setPassword(encoder.encode(user.getPassword()));
        user.setRol("USUARIO");
        user.setActivo(true);

        return repository.save(user);
    }

    /**
     * HU-02 + HU-04: Inicio de sesión.
     * - Verifica existencia del usuario.
     * - Verifica que la cuenta esté activa (HU-04).
     * - Compara contraseña con BCrypt.
     * - Mensaje genérico en caso de error.
     */
    public LoginResponse login(String correo, String password) {
        User user = repository.findByCorreo(correo)
                .orElseThrow(() -> new RuntimeException("Credenciales inválidas."));

        if (Boolean.FALSE.equals(user.getActivo())) {
            throw new RuntimeException("La cuenta está deshabilitada. Contacte al administrador.");
        }

        if (!encoder.matches(password, user.getPassword())) {
            throw new RuntimeException("Credenciales inválidas.");
        }

        return new LoginResponse(
                user.getId(),
                user.getNombre(),
                user.getCorreo(),
                user.getRol()
        );
    }
}