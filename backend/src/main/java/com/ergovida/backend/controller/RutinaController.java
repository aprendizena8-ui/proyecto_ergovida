package com.ergovida.backend.controller;

import com.ergovida.backend.model.Rutina;
import com.ergovida.backend.repository.EjercicioRepository;
import com.ergovida.backend.repository.RutinaRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/rutinas")
@CrossOrigin(origins = "*")
public class RutinaController {

    @Autowired
    private RutinaRepository rutinaRepository;

    @Autowired
    private EjercicioRepository ejercicioRepository;

    @GetMapping
    public List<Rutina> getAllRutinas() {
        return rutinaRepository.findAll();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Rutina> getRutinaById(@PathVariable Long id) {
        return rutinaRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public Rutina createRutina(@RequestBody Rutina rutina) {
        return rutinaRepository.save(rutina);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Rutina> updateRutina(@PathVariable Long id, @RequestBody Rutina detalles) {
        return rutinaRepository.findById(id).map(rutina -> {
            rutina.setNombre(detalles.getNombre());
            rutina.setDescripcion(detalles.getDescripcion());
            Rutina actualizada = rutinaRepository.save(rutina);
            return ResponseEntity.ok(actualizada);
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteRutina(@PathVariable Long id) {
        return rutinaRepository.findById(id).map(rutina -> {
            rutinaRepository.delete(rutina);
            return ResponseEntity.ok().<Void>build();
        }).orElse(ResponseEntity.notFound().build());
    }

    // Asignar un ejercicio a una rutina existente
    // Endpoint de asignación: Añadir un ejercicio a una rutina
    @PostMapping("/{rutinaId}/ejercicios/{ejercicioId}")
    public ResponseEntity<Rutina> agregarEjercicioARutina(
            @PathVariable Long rutinaId, 
            @PathVariable Long ejercicioId) {
            
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