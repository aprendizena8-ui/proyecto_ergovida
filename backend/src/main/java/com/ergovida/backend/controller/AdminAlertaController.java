package com.ergovida.backend.controller;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import com.ergovida.backend.config.RoleGuard;
import com.ergovida.backend.model.CorreoAdministrador;
import com.ergovida.backend.model.User;
import com.ergovida.backend.repository.CorreoAdministradorRepository;
import com.ergovida.backend.service.DestinatariosAlertaService;
import com.ergovida.backend.service.EmailService;
import com.ergovida.backend.service.RoleService;

import jakarta.servlet.http.HttpServletRequest;

@RestController
@RequestMapping("/api/admin/correos-alertas")
@CrossOrigin(origins = "*")
public class AdminAlertaController {

    private final CorreoAdministradorRepository repository;
    private final DestinatariosAlertaService destinatariosService;
    private final EmailService emailService;
    private final RoleGuard roleGuard;

    public AdminAlertaController(
            CorreoAdministradorRepository repository,
            DestinatariosAlertaService destinatariosService,
            EmailService emailService,
            RoleGuard roleGuard) {
        this.repository = repository;
        this.destinatariosService = destinatariosService;
        this.emailService = emailService;
        this.roleGuard = roleGuard;
    }

    @GetMapping
    public List<CorreoAdministrador> listar(HttpServletRequest request) {
        roleGuard.requireRole(request, RoleService.ADMINISTRADOR);
        return repository.findAllByOrderByCorreoAsc();
    }

    @PostMapping
    public ResponseEntity<CorreoAdministrador> crear(
            @RequestBody CorreoAdministrador entrada,
            HttpServletRequest request) {
        roleGuard.requireRole(request, RoleService.ADMINISTRADOR);

        String correo = normalizarCorreo(entrada.getCorreo());
        validarCorreo(correo);

        if (repository.existsByCorreoIgnoreCase(correo)) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Ese correo ya esta registrado para alertas.");
        }

        CorreoAdministrador nuevo = new CorreoAdministrador();
        nuevo.setCorreo(correo);
        nuevo.setNombre(limpiar(entrada.getNombre(), 120));
        nuevo.setActivo(entrada.getActivo() == null ? true : entrada.getActivo());

        return ResponseEntity.ok(repository.save(nuevo));
    }

    @PutMapping("/{id}")
    public ResponseEntity<CorreoAdministrador> actualizar(
            @PathVariable Long id,
            @RequestBody CorreoAdministrador cambios,
            HttpServletRequest request) {
        roleGuard.requireRole(request, RoleService.ADMINISTRADOR);

        return repository.findById(id).map(actual -> {
            if (cambios.getCorreo() != null) {
                String correo = normalizarCorreo(cambios.getCorreo());
                validarCorreo(correo);

                repository.findByCorreoIgnoreCase(correo)
                        .filter(otro -> !otro.getId().equals(id))
                        .ifPresent(otro -> {
                            throw new ResponseStatusException(
                                    HttpStatus.CONFLICT,
                                    "Ese correo ya esta registrado para alertas.");
                        });

                actual.setCorreo(correo);
            }
            if (cambios.getNombre() != null) {
                actual.setNombre(limpiar(cambios.getNombre(), 120));
            }
            if (cambios.getActivo() != null) {
                actual.setActivo(cambios.getActivo());
            }
            return ResponseEntity.ok(repository.save(actual));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminar(
            @PathVariable Long id,
            HttpServletRequest request) {
        roleGuard.requireRole(request, RoleService.ADMINISTRADOR);

        return repository.findById(id).map(configurado -> {
            repository.delete(configurado);
            return ResponseEntity.ok().<Void>build();
        }).orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/probar")
    public ResponseEntity<Map<String, Object>> enviarPrueba(
            HttpServletRequest request) {
        User admin = roleGuard.requireRole(request, RoleService.ADMINISTRADOR);

        List<String> destinatarios = destinatariosService.obtenerCorreos();
        Map<String, Object> respuesta = new LinkedHashMap<>();

        if (destinatarios.isEmpty()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "No hay correos de administradores configurados.");
        }

        try {
            emailService.enviarCorreoPrueba(destinatarios, admin.getCorreo());
            respuesta.put("mensaje", "Correo de prueba enviado.");
            respuesta.put("destinatarios", destinatarios);
            respuesta.put("correoEnviado", true);
            return ResponseEntity.ok(respuesta);
        } catch (Exception error) {
            respuesta.put(
                    "mensaje",
                    "No se pudo enviar el correo de prueba: "
                            + error.getMessage());
            respuesta.put("destinatarios", destinatarios);
            respuesta.put("correoEnviado", false);
            return ResponseEntity.ok(respuesta);
        }
    }

    private static void validarCorreo(String correo) {
        if (correo.isEmpty()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "El correo es obligatorio.");
        }
        if (!correo.matches("^[\\w.+-]+@[\\w-]+(\\.[\\w-]+)+$")) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Ingresa un correo valido.");
        }
    }

    private static String normalizarCorreo(String correo) {
        return correo == null
                ? ""
                : correo.trim().toLowerCase(Locale.ROOT);
    }

    private static String limpiar(String valor, int maximo) {
        if (valor == null) {
            return null;
        }
        String limpio = valor.trim();
        return limpio.length() > maximo
                ? limpio.substring(0, maximo)
                : limpio;
    }
}
