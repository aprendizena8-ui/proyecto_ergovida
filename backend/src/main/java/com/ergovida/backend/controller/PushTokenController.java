package com.ergovida.backend.controller;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import com.ergovida.backend.config.RoleGuard;
import com.ergovida.backend.model.DispositivoPush;
import com.ergovida.backend.model.User;
import com.ergovida.backend.repository.DispositivoPushRepository;

import jakarta.servlet.http.HttpServletRequest;

@RestController
@RequestMapping("/api/push")
@CrossOrigin(origins = "*")
public class PushTokenController {

    private final DispositivoPushRepository repository;
    private final RoleGuard roleGuard;

    public PushTokenController(
            DispositivoPushRepository repository,
            RoleGuard roleGuard) {
        this.repository = repository;
        this.roleGuard = roleGuard;
    }

    @PostMapping("/tokens")
    public ResponseEntity<Map<String, Object>> registrar(
            @RequestBody Map<String, String> body,
            HttpServletRequest request) {

        User usuario = roleGuard.requireUser(request);

        String token = body.get("token") == null
                ? ""
                : body.get("token").trim();
        String plataforma = body.get("plataforma") == null
                ? ""
                : body.get("plataforma").trim().toLowerCase(Locale.ROOT);

        if (token.isEmpty()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "El token del dispositivo es obligatorio.");
        }
        if (token.length() > 512) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "El token del dispositivo no es valido.");
        }
        if (plataforma.length() > 30) {
            plataforma = plataforma.substring(0, 30);
        }

        DispositivoPush dispositivo = repository.findByToken(token)
                .orElseGet(DispositivoPush::new);

        dispositivo.setUsuarioId(usuario.getId());
        dispositivo.setToken(token);
        dispositivo.setPlataforma(plataforma.isEmpty() ? null : plataforma);
        dispositivo.setActivo(true);
        if (dispositivo.getFechaRegistro() == null) {
            dispositivo.setFechaRegistro(LocalDateTime.now());
        }
        dispositivo.setFechaActualizacion(LocalDateTime.now());

        DispositivoPush guardado = repository.save(dispositivo);

        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("id", guardado.getId());
        respuesta.put("mensaje", "Token de notificaciones registrado.");
        return ResponseEntity.ok(respuesta);
    }

    @DeleteMapping("/tokens")
    public ResponseEntity<Void> eliminar(
            @RequestBody Map<String, String> body,
            HttpServletRequest request) {

        User usuario = roleGuard.requireUser(request);
        String token = body.get("token") == null
                ? ""
                : body.get("token").trim();

        if (token.isEmpty()) {
            return ResponseEntity.badRequest().build();
        }

        repository.findByToken(token)
                .filter(dispositivo -> dispositivo.getUsuarioId()
                        .equals(usuario.getId()))
                .ifPresent(dispositivo -> {
                    dispositivo.setActivo(false);
                    repository.save(dispositivo);
                });

        return ResponseEntity.ok().build();
    }
}
