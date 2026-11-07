package com.ergovida.backend.controller;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import com.ergovida.backend.config.RoleGuard;
import com.ergovida.backend.model.RecordatorioGlobal;
import com.ergovida.backend.model.User;
import com.ergovida.backend.repository.RecordatorioGlobalRepository;
import com.ergovida.backend.service.RoleService;

import jakarta.servlet.http.HttpServletRequest;

@RestController
@RequestMapping("/api/recordatorios-globales")
@CrossOrigin(origins = "*")
public class RecordatorioGlobalController {

    private static final String TODOS_LOS_DIAS = "1,2,3,4,5,6,7";

    private final RecordatorioGlobalRepository repository;
    private final RoleGuard roleGuard;

    public RecordatorioGlobalController(
            RecordatorioGlobalRepository repository,
            RoleGuard roleGuard) {
        this.repository = repository;
        this.roleGuard = roleGuard;
    }

    @GetMapping
    public List<RecordatorioGlobal> getAll(
            @RequestParam(required = false) Boolean soloActivos,
            HttpServletRequest request) {
        roleGuard.requireUser(request);

        if (Boolean.TRUE.equals(soloActivos)) {
            return repository.findByActivoTrueOrderByHoraAsc();
        }
        return repository.findAllByOrderByHoraAsc();
    }

    @PostMapping
    public ResponseEntity<RecordatorioGlobal> create(
            @RequestBody RecordatorioGlobal recordatorio,
            HttpServletRequest request) {
        User lider = roleGuard.requireRole(request, RoleService.LIDER_SST);
        validar(recordatorio);

        recordatorio.setId(null);
        recordatorio.setHora(recordatorio.getHora().withSecond(0).withNano(0));
        recordatorio.setDiasSemana(normalizarDias(recordatorio.getDiasSemana()));
        recordatorio.setMensaje(recordatorio.getMensaje().trim());
        recordatorio.setActivo(recordatorio.getActivo() == null ? true : recordatorio.getActivo());
        recordatorio.setCreadoPor(lider.getId());
        recordatorio.setFechaCreacion(LocalDateTime.now());

        return ResponseEntity.ok(repository.save(recordatorio));
    }

    @PutMapping("/{id}")
    public ResponseEntity<RecordatorioGlobal> update(
            @PathVariable Long id,
            @RequestBody RecordatorioGlobal cambios,
            HttpServletRequest request) {
        roleGuard.requireRole(request, RoleService.LIDER_SST);

        return repository.findById(id).map(recordatorio -> {
            if (cambios.getHora() != null) {
                recordatorio.setHora(cambios.getHora().withSecond(0).withNano(0));
            }
            if (cambios.getDiasSemana() != null) {
                recordatorio.setDiasSemana(cambios.getDiasSemana());
            }
            if (cambios.getMensaje() != null) {
                recordatorio.setMensaje(cambios.getMensaje());
            }
            if (cambios.getActivo() != null) {
                recordatorio.setActivo(cambios.getActivo());
            }

            validar(recordatorio);
            recordatorio.setDiasSemana(normalizarDias(recordatorio.getDiasSemana()));
            recordatorio.setMensaje(recordatorio.getMensaje().trim());

            return ResponseEntity.ok(repository.save(recordatorio));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(
            @PathVariable Long id,
            HttpServletRequest request) {
        roleGuard.requireRole(request, RoleService.LIDER_SST);

        return repository.findById(id).map(recordatorio -> {
            repository.delete(recordatorio);
            return ResponseEntity.ok().<Void>build();
        }).orElse(ResponseEntity.notFound().build());
    }

    private void validar(RecordatorioGlobal recordatorio) {
        if (recordatorio.getHora() == null) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "La hora del recordatorio es obligatoria.");
        }
        if (recordatorio.getMensaje() == null || recordatorio.getMensaje().isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "El mensaje del recordatorio es obligatorio.");
        }
        if (recordatorio.getMensaje().trim().length() > 255) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "El mensaje no puede superar 255 caracteres.");
        }
        if (recordatorio.getDiasSemana() != null
                && !recordatorio.getDiasSemana().isBlank()
                && normalizarDias(recordatorio.getDiasSemana()).isEmpty()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Selecciona al menos un día de repetición.");
        }
    }

    private String normalizarDias(String dias) {
        if (dias == null || dias.isBlank()) {
            return TODOS_LOS_DIAS;
        }

        Set<Integer> validos = new LinkedHashSet<>();
        for (String parte : dias.split(",")) {
            try {
                int dia = Integer.parseInt(parte.trim());
                if (dia >= 1 && dia <= 7) {
                    validos.add(dia);
                }
            } catch (NumberFormatException ignored) {
                // Se descartan valores invalidos.
            }
        }

        List<String> ordenados = new ArrayList<>();
        for (int dia = 1; dia <= 7; dia++) {
            if (validos.contains(dia)) {
                ordenados.add(String.valueOf(dia));
            }
        }
        return String.join(",", ordenados);
    }
}
