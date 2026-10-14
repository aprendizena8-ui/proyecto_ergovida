package com.ergovida.backend.controller;

import com.ergovida.backend.dto.PausaRequest;
import com.ergovida.backend.model.PausaRealizada;
import com.ergovida.backend.repository.PausaRealizadaRepository;
import com.ergovida.backend.service.PausaService;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/pausas-realizadas")
@CrossOrigin(origins = "*")
public class PausaRealizadaController {

    @Autowired
    private PausaService pausaService;

    @Autowired
    private PausaRealizadaRepository pausaRealizadaRepository;  // ← AGREGAR ESTO

    @GetMapping
    public List<PausaRealizada> getAll() {
        return pausaRealizadaRepository.findAll();
    }

    @GetMapping("/usuario/{usuarioId}")
    public List<PausaRealizada> getByUsuario(@PathVariable Long usuarioId) {
        return pausaRealizadaRepository.findByUsuarioId(usuarioId);
    }

    @PostMapping
    public ResponseEntity<PausaRealizada> create(@RequestBody PausaRequest req) {
        return ResponseEntity.status(HttpStatus.CREATED).body(pausaService.registrar(req));
    }
}