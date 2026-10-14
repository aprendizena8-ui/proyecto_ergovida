package com.ergovida.backend.service;

import com.ergovida.backend.dto.PausaRequest;
import com.ergovida.backend.model.*;
import com.ergovida.backend.repository.*;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Service
public class PausaService {
    private final PausaRealizadaRepository pausaRepo;
    private final EstadisticaRepository estadisticaRepo;
    private final EjercicioRepository ejercicioRepo;
    private final UserRepository userRepo;

    public PausaService(PausaRealizadaRepository pausaRepo, EstadisticaRepository estadisticaRepo,
                        EjercicioRepository ejercicioRepo, UserRepository userRepo) {
        this.pausaRepo = pausaRepo;
        this.estadisticaRepo = estadisticaRepo;
        this.ejercicioRepo = ejercicioRepo;
        this.userRepo = userRepo;
    }

    @Transactional
    public PausaRealizada registrar(PausaRequest req) {
        if (req.usuarioId() == null || req.ejercicioId() == null)
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "usuarioId y ejercicioId son obligatorios");
        if (!userRepo.existsById(req.usuarioId()))
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Usuario no existe");
        Ejercicio ej = ejercicioRepo.findById(req.ejercicioId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Ejercicio no existe"));

        boolean completada = Boolean.TRUE.equals(req.completada());
        PausaRealizada p = new PausaRealizada();
        p.setUsuarioId(req.usuarioId());
        p.setEjercicioId(req.ejercicioId());
        p.setFecha(LocalDateTime.now());
        p.setCompletada(completada);
        p = pausaRepo.save(p);

        if (completada) {
            Estadistica e = estadisticaRepo.findByUsuarioIdAndFecha(req.usuarioId(), LocalDate.now())
                    .orElseGet(() -> {
                        Estadistica n = new Estadistica();
                        n.setUsuarioId(req.usuarioId());
                        n.setFecha(LocalDate.now());
                        n.setPausasRealizadas(0);
                        n.setMinutosActivos(0);
                        return n;
                    });
            e.setPausasRealizadas(e.getPausasRealizadas() + 1);
            e.setMinutosActivos(e.getMinutosActivos() + (ej.getDuracion() == null ? 0 : ej.getDuracion()));
            estadisticaRepo.save(e);
        }
        return p;
    }
}