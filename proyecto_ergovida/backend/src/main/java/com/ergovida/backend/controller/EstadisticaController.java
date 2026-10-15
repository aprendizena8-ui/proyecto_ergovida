package com.ergovida.backend.controller;

import com.ergovida.backend.model.Estadistica;
import com.ergovida.backend.repository.EstadisticaRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/estadisticas")
@CrossOrigin(origins = "*")
public class EstadisticaController {

    @Autowired
    private EstadisticaRepository estadisticaRepository;

    @GetMapping
    public List<Estadistica> getAll() { return estadisticaRepository.findAll(); }

    @GetMapping("/usuario/{usuarioId}")
    public List<Estadistica> getByUsuario(@PathVariable Long usuarioId) {
        return estadisticaRepository.findByUsuarioId(usuarioId);
    }

    @PostMapping
    public Estadistica createOrUpdate(@RequestBody Estadistica estadistica) {
        return estadisticaRepository.save(estadistica);
    }
}