package com.ergovida.backend.controller;

import com.ergovida.backend.config.RoleGuard;
import com.ergovida.backend.model.Horario;
import com.ergovida.backend.model.User;
import com.ergovida.backend.repository.HorarioRepository;
import com.ergovida.backend.service.RoleService;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

import jakarta.servlet.http.HttpServletRequest;

@RestController
@RequestMapping("/api/horarios")
@CrossOrigin(origins = "*")
public class HorarioController {

    @Autowired
    private HorarioRepository horarioRepository;

    @Autowired
    private RoleGuard roleGuard;

    @GetMapping
    public List<Horario> getAll(HttpServletRequest request) {
        roleGuard.requireRole(
                request,
                RoleService.ADMINISTRADOR,
                RoleService.LIDER_SST);
        return horarioRepository.findAll();
    }

    @GetMapping("/usuario/{usuarioId}")
    public List<Horario> getByUsuario(
            @PathVariable Long usuarioId,
            HttpServletRequest request) {
        User actor = roleGuard.requireUser(request);
        validarPropietario(actor, usuarioId);
        return horarioRepository.findByUsuarioId(usuarioId);
    }

    @PostMapping
    public Horario create(
            @RequestBody Horario horario,
            HttpServletRequest request) {
        User actor = roleGuard.requireUser(request);

        if (horario.getUsuarioId() == null) {
            horario.setUsuarioId(actor.getId());
        } else {
            validarPropietario(actor, horario.getUsuarioId());
        }

        return horarioRepository.save(horario);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(
            @PathVariable Long id,
            HttpServletRequest request) {
        User actor = roleGuard.requireUser(request);

        return horarioRepository.findById(id).map(horario -> {
            validarPropietario(actor, horario.getUsuarioId());
            horarioRepository.delete(horario);
            return ResponseEntity.ok().<Void>build();
        }).orElse(ResponseEntity.notFound().build());
    }

    private void validarPropietario(User actor, Long usuarioId) {
        boolean esPropio = actor.getId() != null
                && actor.getId().equals(usuarioId);

        if (!esPropio
                && !roleGuard.esAdmin(actor)
                && !roleGuard.esLiderSst(actor)) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "No tienes permisos para acceder a este horario.");
        }
    }
}
