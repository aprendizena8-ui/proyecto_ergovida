package com.ergovida.backend.controller;

import com.ergovida.backend.model.Rutina;
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
}