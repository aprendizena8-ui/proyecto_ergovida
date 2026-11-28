package com.ergovida.backend.controller;

import com.ergovida.backend.config.RoleGuard;
import com.ergovida.backend.dto.PausaRequest;
import com.ergovida.backend.model.PausaRealizada;
import com.ergovida.backend.model.User;
import com.ergovida.backend.repository.PausaRealizadaRepository;
import com.ergovida.backend.service.PausaService;
import com.ergovida.backend.service.RoleService;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

import jakarta.servlet.http.HttpServletRequest;

@RestController
@RequestMapping("/api/pausas-realizadas")
@CrossOrigin(origins = "*")
public class PausaRealizadaController {

    @Autowired
    private PausaService pausaService;

    @Autowired
    private PausaRealizadaRepository pausaRealizadaRepository;

    @Autowired
    private RoleGuard roleGuard;

    @GetMapping
    public List<PausaRealizada> getAll(HttpServletRequest request) {
        roleGuard.requireRole(
                request,
                RoleService.ADMINISTRADOR,
                RoleService.LIDER_SST);
        return pausaRealizadaRepository.findAll();
    }

    @GetMapping("/usuario/{usuarioId}")
    public List<PausaRealizada> getByUsuario(
            @PathVariable Long usuarioId,
            HttpServletRequest request) {
        User actor = roleGuard.requireUser(request);
        validarPropietario(actor, usuarioId);
        return pausaRealizadaRepository.findByUsuarioId(usuarioId);
    }

    @PostMapping
    public ResponseEntity<PausaRealizada> create(
            @RequestBody PausaRequest req,
            HttpServletRequest request) {
        User actor = roleGuard.requireUser(request);

        Long usuarioId = req.usuarioId();
        if (usuarioId == null || !puedeGestionar(actor, usuarioId)) {
            usuarioId = actor.getId();
        }

        PausaRequest seguro = new PausaRequest(
                usuarioId,
                req.ejercicioId(),
                req.completada(),
                req.tipo());

        return ResponseEntity.status(HttpStatus.CREATED)
                .body(pausaService.registrar(seguro));
    }

    private void validarPropietario(User actor, Long usuarioId) {
        if (!puedeGestionar(actor, usuarioId)) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "No tienes permisos para acceder a estas pausas.");
        }
    }

    private boolean puedeGestionar(User actor, Long usuarioId) {
        boolean esPropio = actor.getId() != null
                && actor.getId().equals(usuarioId);
        return esPropio
                || roleGuard.esAdmin(actor)
                || roleGuard.esLiderSst(actor);
    }
}
