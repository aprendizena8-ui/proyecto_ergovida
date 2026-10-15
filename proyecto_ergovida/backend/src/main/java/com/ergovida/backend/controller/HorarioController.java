package com.ergovida.backend.controller;

import com.ergovida.backend.model.Horario;
import com.ergovida.backend.repository.HorarioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/horarios")
@CrossOrigin(origins = "*")
public class HorarioController {

    @Autowired
    private HorarioRepository horarioRepository;

    @GetMapping
    public List<Horario> getAll() { return horarioRepository.findAll(); }

    @GetMapping("/usuario/{usuarioId}")
    public List<Horario> getByUsuario(@PathVariable Long usuarioId) {
        return horarioRepository.findByUsuarioId(usuarioId);
    }

    @PostMapping
    public Horario create(@RequestBody Horario horario) {
        return horarioRepository.save(horario);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        return horarioRepository.findById(id).map(h -> {
            horarioRepository.delete(h);
            return ResponseEntity.ok().<Void>build();
        }).orElse(ResponseEntity.notFound().build());
    }
}