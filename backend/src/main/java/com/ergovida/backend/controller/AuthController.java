package com.ergovida.backend.controller;

import jakarta.servlet.http.HttpServletRequest;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
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
import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Locale;
import java.util.Map;

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

    private static final Logger logger = LoggerFactory.getLogger(AuthController.class);
    private static final SecureRandom RANDOM = new SecureRandom();
    private static final int MINUTOS_VIGENCIA_CODIGO = 15;

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

            return ResponseEntity.ok(Map.of(
                    "id", saved.getId(),
                    "nombre", saved.getNombre(),
                    "correo", saved.getCorreo(),
                    "rol", saved.getRol()
            ));

        } catch (DataIntegrityViolationException e) {
            return ResponseEntity.status(409)
                    .body(Map.of("mensaje", "Este correo ya está registrado. Intenta iniciar sesión."));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("mensaje", e.getMessage()));
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

            return ResponseEntity.badRequest().body(Map.of("mensaje", e.getMessage()));
        }
    }

    /**
     * Genera y envía un código de verificación.
     *
     * El campo opcional "tipo" indica si el código es para "registro"
     * (valor por defecto) o para "recuperacion". En recuperación se exige que
     * la cuenta exista para no confundir al usuario.
     */
    @PostMapping("/enviar-codigo")
    public ResponseEntity<?> enviarCodigo(@RequestBody Map<String, String> body) {
        String correo = normalizarCorreo(body.get("correo"));
        String tipo = body.getOrDefault("tipo", "registro").trim().toLowerCase(Locale.ROOT);

        if (correo.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("mensaje", "El correo es obligatorio."));
        }

        if (!correoValido(correo)) {
            return ResponseEntity.badRequest().body(Map.of("mensaje", "Ingresa un correo válido."));
        }

        if ("recuperacion".equals(tipo) && !service.existeCorreo(correo)) {
            return ResponseEntity.status(404)
                    .body(Map.of("mensaje", "No existe una cuenta registrada con ese correo."));
        }

        if (!"recuperacion".equals(tipo) && service.existeCorreo(correo)) {
            return ResponseEntity.status(409)
                    .body(Map.of("mensaje", "El correo ya está registrado. Inicia sesión o recupera tu contraseña."));
        }

        // Invalida códigos anteriores sin usar para que solo sirva el más reciente.
        for (CodigoVerificacion anterior : codigoRepo.findByCorreoAndUsadoFalse(correo)) {
            anterior.setUsado(true);
            codigoRepo.save(anterior);
        }

        String codigo = String.format("%06d", RANDOM.nextInt(1_000_000));

        CodigoVerificacion cv = new CodigoVerificacion();
        cv.setCorreo(correo);
        cv.setCodigo(codigo);
        cv.setFechaCreacion(LocalDateTime.now());
        cv.setExpiraEn(LocalDateTime.now().plusMinutes(MINUTOS_VIGENCIA_CODIGO));
        cv.setUsado(false);
        codigoRepo.save(cv);

        try {
            emailService.enviarCodigoVerificacion(correo, codigo);
        } catch (Exception e) {
            logger.error("No se pudo enviar el correo de verificación a {}: {}", correo, e.getMessage());
            // El flujo no se bloquea: se devuelve el código para que la app pueda
            // mostrarlo mientras se corrige la configuración de correo.
            return ResponseEntity.ok(Map.of(
                    "mensaje", "No se pudo enviar el correo. Usa el código que aparece en pantalla.",
                    "codigo", codigo,
                    "correoEnviado", false
            ));
        }

        return ResponseEntity.ok(Map.of(
                "mensaje", "Código enviado a tu correo.",
                "correoEnviado", true
        ));
    }

    /**
     * Verifica un código de 6 dígitos y lo marca como usado.
     */
    @PostMapping("/verificar-codigo")
    public ResponseEntity<?> verificarCodigo(@RequestBody Map<String, String> body) {
        String correo = normalizarCorreo(body.get("correo"));
        String codigo = body.get("codigo") == null ? "" : body.get("codigo").trim();

        if (correo.isEmpty() || codigo.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("mensaje", "Correo y código son obligatorios."));
        }

        var opt = codigoRepo.findByCorreoAndCodigoAndUsadoFalse(correo, codigo);
        if (opt.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("mensaje", "Código incorrecto."));
        }

        CodigoVerificacion cv = opt.get();
        if (cv.getExpiraEn() == null || cv.getExpiraEn().isBefore(LocalDateTime.now())) {
            cv.setUsado(true);
            codigoRepo.save(cv);
            return ResponseEntity.badRequest().body(Map.of("mensaje", "Código expirado. Solicita uno nuevo."));
        }

        cv.setUsado(true);
        codigoRepo.save(cv);

        return ResponseEntity.ok(Map.of("mensaje", "Código verificado."));
    }

    /**
     * Cambia la contraseña. Solo se permite si el correo fue verificado
     * recientemente mediante un código.
     */
    @PostMapping("/cambiar-password")
    public ResponseEntity<?> cambiarPassword(@RequestBody Map<String, String> body) {
        String correo = normalizarCorreo(body.get("correo"));
        String nuevaPassword = body.get("nuevaPassword");

        if (correo.isEmpty() || nuevaPassword == null || nuevaPassword.isBlank()) {
            return ResponseEntity.badRequest()
                    .body(Map.of("mensaje", "Correo y contraseña son obligatorios."));
        }

        boolean verificado = codigoRepo.existsByCorreoAndUsadoTrueAndExpiraEnAfter(
                correo,
                LocalDateTime.now()
        );

        if (!verificado) {
            return ResponseEntity.badRequest()
                    .body(Map.of("mensaje", "Debes verificar el código antes de cambiar la contraseña."));
        }

        try {
            service.cambiarPassword(correo, nuevaPassword);
            return ResponseEntity.ok(Map.of("mensaje", "Contraseña actualizada."));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("mensaje", e.getMessage()));
        }
    }

    private String normalizarCorreo(String correo) {
        return correo == null ? "" : correo.trim().toLowerCase(Locale.ROOT);
    }

    private boolean correoValido(String correo) {
        return correo.matches("^[\\w.+-]+@[\\w-]+(\\.[\\w-]+)+$");
    }
}
