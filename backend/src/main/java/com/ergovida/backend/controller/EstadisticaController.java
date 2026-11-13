package com.ergovida.backend.controller;

import com.ergovida.backend.config.RoleGuard;
import com.ergovida.backend.model.Estadistica;
import com.ergovida.backend.model.User;
import com.ergovida.backend.repository.EstadisticaRepository;
import com.ergovida.backend.service.RoleService;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

import jakarta.servlet.http.HttpServletRequest;

@RestController
@RequestMapping("/api/estadisticas")
@CrossOrigin(origins = "*")
public class EstadisticaController {

    @Autowired
    private EstadisticaRepository estadisticaRepository;

    @Autowired
    private RoleGuard roleGuard;

    @GetMapping
    public List<Estadistica> getAll(HttpServletRequest request) {
        roleGuard.requireRole(
                request,
                RoleService.ADMINISTRADOR,
                RoleService.LIDER_SST);
        return estadisticaRepository.findAll();
    }

    @GetMapping("/usuario/{usuarioId}")
    public List<Estadistica> getByUsuario(
            @PathVariable Long usuarioId,
            HttpServletRequest request) {
        User actor = roleGuard.requireUser(request);
        validarPropietario(actor, usuarioId);
        return estadisticaRepository.findByUsuarioId(usuarioId);
    }

    @PostMapping
    public Estadistica createOrUpdate(
            @RequestBody Estadistica estadistica,
            HttpServletRequest request) {
        User actor = roleGuard.requireUser(request);

        if (estadistica.getUsuarioId() == null
                || !puedeGestionar(actor, estadistica.getUsuarioId())) {
            estadistica.setUsuarioId(actor.getId());
        }

        return estadisticaRepository.save(estadistica);
    }

    private void validarPropietario(User actor, Long usuarioId) {
        if (!puedeGestionar(actor, usuarioId)) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "No tienes permisos para acceder a estas estadísticas.");
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
