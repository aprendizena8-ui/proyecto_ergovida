package com.ergovida.backend.controller;

import com.ergovida.backend.config.RoleGuard;
import com.ergovida.backend.model.Ejercicio;
import com.ergovida.backend.repository.EjercicioRepository;
import com.ergovida.backend.service.RoleService;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

import jakarta.servlet.http.HttpServletRequest;

@RestController
@RequestMapping("/api/ejercicios")
@CrossOrigin(origins = "*")
public class EjercicioController {

    @Autowired
    private EjercicioRepository ejercicioRepository;

    @Autowired
    private RoleGuard roleGuard;

    @GetMapping
    public List<Ejercicio> getAllEjercicios(HttpServletRequest request) {
        roleGuard.requireUser(request);
        return ejercicioRepository.findAll();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Ejercicio> getEjercicioById(
            @PathVariable Long id,
            HttpServletRequest request) {
        roleGuard.requireUser(request);
        return ejercicioRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public Ejercicio createEjercicio(
            @RequestBody Ejercicio ejercicio,
            HttpServletRequest request) {
        roleGuard.requireRole(
                request,
                RoleService.ADMINISTRADOR,
                RoleService.LIDER_SST);
        return ejercicioRepository.save(ejercicio);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Ejercicio> updateEjercicio(
            @PathVariable Long id,
            @RequestBody Ejercicio detalles,
            HttpServletRequest request) {
        roleGuard.requireRole(
                request,
                RoleService.ADMINISTRADOR,
                RoleService.LIDER_SST);

        return ejercicioRepository.findById(id).map(ejercicio -> {
            ejercicio.setNombre(detalles.getNombre());
            ejercicio.setDescripcion(detalles.getDescripcion());
            ejercicio.setDuracion(detalles.getDuracion());
            ejercicio.setCategoria(detalles.getCategoria());
            Ejercicio actualizado = ejercicioRepository.save(ejercicio);
            return ResponseEntity.ok(actualizado);
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteEjercicio(
            @PathVariable Long id,
            HttpServletRequest request) {
        roleGuard.requireRole(
                request,
                RoleService.ADMINISTRADOR,
                RoleService.LIDER_SST);

        return ejercicioRepository.findById(id).map(ejercicio -> {
            ejercicioRepository.delete(ejercicio);
            return ResponseEntity.ok().<Void>build();
        }).orElse(ResponseEntity.notFound().build());
    }
}
