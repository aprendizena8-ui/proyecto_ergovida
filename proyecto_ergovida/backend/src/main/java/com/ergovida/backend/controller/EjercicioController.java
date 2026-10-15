package com.ergovida.backend.controller;

import com.ergovida.backend.model.Ejercicio;
import com.ergovida.backend.repository.EjercicioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/ejercicios")
@CrossOrigin(origins = "*")
public class EjercicioController {

    @Autowired
    private EjercicioRepository ejercicioRepository;

    @GetMapping
    public List<Ejercicio> getAllEjercicios() {
        return ejercicioRepository.findAll();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Ejercicio> getEjercicioById(@PathVariable Long id) {
        return ejercicioRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public Ejercicio createEjercicio(@RequestBody Ejercicio ejercicio) {
        return ejercicioRepository.save(ejercicio);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Ejercicio> updateEjercicio(@PathVariable Long id, @RequestBody Ejercicio detalles) {
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
    public ResponseEntity<Void> deleteEjercicio(@PathVariable Long id) {
        return ejercicioRepository.findById(id).map(ejercicio -> {
            ejercicioRepository.delete(ejercicio);
            return ResponseEntity.ok().<Void>build();
        }).orElse(ResponseEntity.notFound().build());
    }
}