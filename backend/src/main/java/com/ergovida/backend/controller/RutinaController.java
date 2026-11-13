package com.ergovida.backend.controller;

import com.ergovida.backend.config.RoleGuard;
import com.ergovida.backend.model.Rutina;
import com.ergovida.backend.repository.EjercicioRepository;
import com.ergovida.backend.repository.RutinaRepository;
import com.ergovida.backend.service.RoleService;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

import jakarta.servlet.http.HttpServletRequest;

@RestController
@RequestMapping("/api/rutinas")
@CrossOrigin(origins = "*")
public class RutinaController {

    @Autowired
    private RutinaRepository rutinaRepository;

    @Autowired
    private EjercicioRepository ejercicioRepository;

    @Autowired
    private RoleGuard roleGuard;

    @GetMapping
    public List<Rutina> getAllRutinas(HttpServletRequest request) {
        roleGuard.requireUser(request);
        return rutinaRepository.findAll();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Rutina> getRutinaById(
            @PathVariable Long id,
            HttpServletRequest request) {
        roleGuard.requireUser(request);
        return rutinaRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public Rutina createRutina(
            @RequestBody Rutina rutina,
            HttpServletRequest request) {
        roleGuard.requireRole(
                request,
                RoleService.ADMINISTRADOR,
                RoleService.LIDER_SST);
        return rutinaRepository.save(rutina);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Rutina> updateRutina(
            @PathVariable Long id,
            @RequestBody Rutina detalles,
            HttpServletRequest request) {
        roleGuard.requireRole(
                request,
                RoleService.ADMINISTRADOR,
                RoleService.LIDER_SST);

        return rutinaRepository.findById(id).map(rutina -> {
            rutina.setNombre(detalles.getNombre());
            rutina.setDescripcion(detalles.getDescripcion());
            Rutina actualizada = rutinaRepository.save(rutina);
            return ResponseEntity.ok(actualizada);
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteRutina(
            @PathVariable Long id,
            HttpServletRequest request) {
        roleGuard.requireRole(
                request,
                RoleService.ADMINISTRADOR,
                RoleService.LIDER_SST);

        return rutinaRepository.findById(id).map(rutina -> {
            rutinaRepository.delete(rutina);
            return ResponseEntity.ok().<Void>build();
        }).orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/{rutinaId}/ejercicios/{ejercicioId}")
    public ResponseEntity<Rutina> agregarEjercicioARutina(
            @PathVariable Long rutinaId,
            @PathVariable Long ejercicioId,
            HttpServletRequest request) {
        roleGuard.requireRole(
                request,
                RoleService.ADMINISTRADOR,
                RoleService.LIDER_SST);

        return rutinaRepository.findById(rutinaId).flatMap(rutina ->
            ejercicioRepository.findById(ejercicioId).map(ejercicio -> {
                if (!rutina.getEjercicios().contains(ejercicio)) {
                    rutina.getEjercicios().add(ejercicio);
                }
                Rutina actualizada = rutinaRepository.save(rutina);
                return ResponseEntity.ok(actualizada);
            })
        ).orElse(ResponseEntity.notFound().build());
    }
}
