package com.ergovida.backend.controller;

import jakarta.servlet.http.HttpServletRequest;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.ergovida.backend.dto.LoginRequest;
import com.ergovida.backend.dto.LoginResponse;
import com.ergovida.backend.dto.RegisterRequest;
import com.ergovida.backend.model.User;
import com.ergovida.backend.service.AuthService;

/**
 * Endpoints de autenticación.
 *
 * HU-01: POST /api/auth/register
 * HU-02: POST /api/auth/login
 */
@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*")
public class AuthController {

    private final AuthService service;

    public AuthController(AuthService service) {
        this.service = service;
    }

    /**
     * HU-01: Registro de usuario.
     */
    @PostMapping("/register")
    public ResponseEntity<?> register(
            @RequestBody RegisterRequest request) {

        try {

            User user = new User();

            user.setNombre(request.getNombre());
            user.setCorreo(request.getCorreo());
            user.setPassword(request.getPassword());

            User saved = service.registrar(user);

            return ResponseEntity.ok(saved);

        } catch (RuntimeException e) {

            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * HU-02: Inicio de sesión.
     */
    @PostMapping("/login")
    public ResponseEntity<?> login(
            @RequestBody LoginRequest request,
            HttpServletRequest httpRequest) {

        try {

            String origenIp = httpRequest.getRemoteAddr();

            LoginResponse response = service.login(
                    request.getCorreo(),
                    request.getPassword(),
                    origenIp
            );

            return ResponseEntity.ok(response);

        } catch (RuntimeException e) {

            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
}