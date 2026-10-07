package com.ergovida.backend.controller;

import com.ergovida.backend.model.PausaRealizada;
import com.ergovida.backend.repository.PausaRealizadaRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/pausas-realizadas")
@CrossOrigin(origins = "*")
public class PausaRealizadaController {

    @Autowired
    private PausaRealizadaRepository pausaRealizadaRepository;

    @GetMapping
    public List<PausaRealizada> getAll() { return pausaRealizadaRepository.findAll(); }

    @GetMapping("/usuario/{usuarioId}")
    public List<PausaRealizada> getByUsuario(@PathVariable Long usuarioId) {
        return pausaRealizadaRepository.findByUsuarioId(usuarioId);
    }

    @PostMapping
    public PausaRealizada create(@RequestBody PausaRealizada pausa) {
        return pausaRealizadaRepository.save(pausa);
    }
}