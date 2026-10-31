package com.ergovida.backend.controller;

import jakarta.servlet.http.HttpServletRequest;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.ergovida.backend.dto.LoginRequest;
import com.ergovida.backend.dto.LoginResponse;
import com.ergovida.backend.dto.RegisterRequest;
import com.ergovida.backend.model.User;
import com.ergovida.backend.model.CodigoVerificacion;
import com.ergovida.backend.repository.CodigoVerificacionRepository;
import com.ergovida.backend.service.AuthService;

import com.ergovida.backend.service.EmailService;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.Random;

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

    @Autowired
    private EmailService emailService;

    @Autowired
    private CodigoVerificacionRepository codigoRepo;

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

        } catch (DataIntegrityViolationException e) {
            return ResponseEntity.badRequest().body("Este correo ya está registrado. Intenta iniciar sesión.");
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

    // Nuevo endpoint para enviar el código
    @PostMapping("/enviar-codigo")
    public ResponseEntity<?> enviarCodigo(@RequestBody Map<String, String> body) {
        String correo = body.get("correo");
        if (correo == null || correo.isEmpty()) {
            return ResponseEntity.badRequest().body("Correo requerido");
        }

        // Generar código de 6 dígitos
        String codigo = String.format("%06d", new Random().nextInt(999999));

        // Guardar en BD
        CodigoVerificacion cv = new CodigoVerificacion();
        cv.setCorreo(correo);
        cv.setCodigo(codigo);
        cv.setFechaCreacion(LocalDateTime.now());
        cv.setExpiraEn(LocalDateTime.now().plusMinutes(15));
        cv.setUsado(false);
        codigoRepo.save(cv);

        // Enviar correo
        try {
            emailService.enviarCodigoVerificacion(correo, codigo);
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Error al enviar el correo: " + e.getMessage());
        }

        return ResponseEntity.ok(Map.of("mensaje", "Código enviado"));
    }

    // Nuevo endpoint para verificar el código
    @PostMapping("/verificar-codigo")
    public ResponseEntity<?> verificarCodigo(@RequestBody Map<String, String> body) {
        String correo = body.get("correo");
        String codigo = body.get("codigo");

        var opt = codigoRepo.findByCorreoAndCodigoAndUsadoFalse(correo, codigo);
        if (opt.isEmpty()) {
            return ResponseEntity.badRequest().body("Código incorrecto");
        }

        CodigoVerificacion cv = opt.get();
        if (cv.getExpiraEn().isBefore(LocalDateTime.now())) {
            return ResponseEntity.badRequest().body("Código expirado");
        }

        cv.setUsado(true);
        codigoRepo.save(cv);

    return ResponseEntity.ok(Map.of("mensaje", "Código verificado"));
}

    // NUEVO ENDPOINT PARA CAMBIAR LA CONTRASEÑA
    @PostMapping("/cambiar-password")
    public ResponseEntity<?> cambiarPassword(@RequestBody Map<String, String> body) {
        String correo = body.get("correo");
        String nuevaPassword = body.get("nuevaPassword");

        if (correo == null || nuevaPassword == null) {
            return ResponseEntity.badRequest().body("Correo y contraseña son obligatorios");
        }
        
        try {
            service.cambiarPassword(correo, nuevaPassword);
            return ResponseEntity.ok(Map.of("mensaje", "Contraseña actualizada"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
}
