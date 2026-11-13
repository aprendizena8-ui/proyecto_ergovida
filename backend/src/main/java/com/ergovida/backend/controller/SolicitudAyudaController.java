package com.ergovida.backend.controller;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import com.ergovida.backend.config.RoleGuard;
import com.ergovida.backend.model.SolicitudAyuda;
import com.ergovida.backend.model.User;
import com.ergovida.backend.repository.SolicitudAyudaRepository;
import com.ergovida.backend.service.DestinatariosAlertaService;
import com.ergovida.backend.service.EmailService;
import com.ergovida.backend.service.RoleService;

import jakarta.servlet.http.HttpServletRequest;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*")
public class SolicitudAyudaController {

    private final SolicitudAyudaRepository repository;
    private final DestinatariosAlertaService destinatariosService;
    private final EmailService emailService;
    private final RoleGuard roleGuard;

    public SolicitudAyudaController(
            SolicitudAyudaRepository repository,
            DestinatariosAlertaService destinatariosService,
            EmailService emailService,
            RoleGuard roleGuard) {
        this.repository = repository;
        this.destinatariosService = destinatariosService;
        this.emailService = emailService;
        this.roleGuard = roleGuard;
    }

    @PostMapping("/solicitudes-ayuda")
    public ResponseEntity<Map<String, Object>> crear(
            @RequestBody Map<String, String> body,
            HttpServletRequest request) {

        User usuario = roleGuard.requireUser(request);

        String asunto = limpiar(body.get("asunto"), 150);
        String descripcion = limpiar(body.get("descripcion"), 5000);

        if (asunto.isEmpty()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "El asunto es obligatorio.");
        }
        if (descripcion.isEmpty()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "La descripcion del problema no puede estar vacia.");
        }

        SolicitudAyuda solicitud = new SolicitudAyuda();
        solicitud.setUsuarioId(usuario.getId());
        solicitud.setNombre(usuario.getNombre());
        solicitud.setCorreo(usuario.getCorreo());
        solicitud.setRol(RoleService.normalizarRol(usuario.getRol()));
        solicitud.setAsunto(asunto);
        solicitud.setDescripcion(descripcion);
        solicitud.setEstado(SolicitudAyuda.ESTADO_PENDIENTE);
        solicitud.setFechaCreacion(LocalDateTime.now());

        SolicitudAyuda guardada = repository.save(solicitud);

        boolean correoEnviado = false;
        List<String> destinatarios = destinatariosService.obtenerCorreos();
        try {
            emailService.enviarSolicitudAyuda(guardada, destinatarios);
            correoEnviado = true;
        } catch (Exception error) {
            // La solicitud queda guardada aunque falle el SMTP.
        }

        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("id", guardada.getId());
        respuesta.put("estado", guardada.getEstado());
        respuesta.put("correoEnviado", correoEnviado);
        respuesta.put(
                "mensaje",
                "Tu solicitud fue enviada. El equipo administrador la revisara.");
        return ResponseEntity.ok(respuesta);
    }

    @GetMapping("/solicitudes-ayuda/mis-solicitudes")
    public List<SolicitudAyuda> misSolicitudes(HttpServletRequest request) {
        User usuario = roleGuard.requireUser(request);
        return repository.findByUsuarioIdOrderByFechaCreacionDesc(usuario.getId());
    }

    @GetMapping("/admin/solicitudes-ayuda")
    public List<SolicitudAyuda> listarTodas(
            @RequestParam(required = false) String estado,
            HttpServletRequest request) {
        roleGuard.requireRole(request, RoleService.ADMINISTRADOR);

        if (estado != null && !estado.isBlank()) {
            return repository.findByEstadoOrderByFechaCreacionDesc(
                    normalizarEstado(estado));
        }
        return repository.findAllByOrderByFechaCreacionDesc();
    }

    @PutMapping("/admin/solicitudes-ayuda/{id}/estado")
    public ResponseEntity<SolicitudAyuda> cambiarEstado(
            @PathVariable Long id,
            @RequestBody Map<String, String> body,
            HttpServletRequest request) {
        roleGuard.requireRole(request, RoleService.ADMINISTRADOR);

        String estado = normalizarEstado(body.get("estado"));

        return repository.findById(id).map(solicitud -> {
            solicitud.setEstado(estado);
            if (SolicitudAyuda.ESTADO_RESUELTA.equals(estado)) {
                solicitud.setFechaResolucion(LocalDateTime.now());
            } else {
                solicitud.setFechaResolucion(null);
            }
            return ResponseEntity.ok(repository.save(solicitud));
        }).orElse(ResponseEntity.notFound().build());
    }

    private static String normalizarEstado(String estado) {
        String valor = estado == null
                ? ""
                : estado.trim().toUpperCase(Locale.ROOT);
        if (!SolicitudAyuda.ESTADO_PENDIENTE.equals(valor)
                && !SolicitudAyuda.ESTADO_RESUELTA.equals(valor)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "El estado debe ser PENDIENTE o RESUELTA.");
        }
        return valor;
    }

    private static String limpiar(String valor, int maximo) {
        if (valor == null) {
            return "";
        }
        String limpio = valor.trim();
        return limpio.length() > maximo
                ? limpio.substring(0, maximo)
                : limpio;
    }
}
