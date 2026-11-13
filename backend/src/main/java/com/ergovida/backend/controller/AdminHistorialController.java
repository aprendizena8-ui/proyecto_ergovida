package com.ergovida.backend.controller;

import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import com.ergovida.backend.config.RoleGuard;
import com.ergovida.backend.model.AlertaError;
import com.ergovida.backend.model.RecordatorioEnvioHistorial;
import com.ergovida.backend.repository.AlertaErrorRepository;
import com.ergovida.backend.repository.RecordatorioEnvioHistorialRepository;
import com.ergovida.backend.service.RoleService;

import jakarta.servlet.http.HttpServletRequest;

@RestController
@RequestMapping("/api/admin")
@CrossOrigin(origins = "*")
public class AdminHistorialController {

    private final RecordatorioEnvioHistorialRepository historialRepository;
    private final AlertaErrorRepository alertaRepository;
    private final RoleGuard roleGuard;

    public AdminHistorialController(
            RecordatorioEnvioHistorialRepository historialRepository,
            AlertaErrorRepository alertaRepository,
            RoleGuard roleGuard) {
        this.historialRepository = historialRepository;
        this.alertaRepository = alertaRepository;
        this.roleGuard = roleGuard;
    }

    @GetMapping("/recordatorios-historial")
    public List<RecordatorioEnvioHistorial> historial(
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
            LocalDate desde,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
            LocalDate hasta,
            HttpServletRequest request) {

        roleGuard.requireRole(request, RoleService.ADMINISTRADOR);

        if (desde != null && hasta != null) {
            if (hasta.isBefore(desde)) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "La fecha 'hasta' no puede ser anterior a 'desde'.");
            }
            return historialRepository
                    .findByFechaBetweenOrderByFechaHoraDesc(desde, hasta);
        }

        return historialRepository.findAllByOrderByFechaHoraDesc();
    }

    @GetMapping("/recordatorios-historial/fallos")
    public List<RecordatorioEnvioHistorial> fallos(HttpServletRequest request) {
        roleGuard.requireRole(request, RoleService.ADMINISTRADOR);
        return historialRepository.findTop200ByExitoFalseOrderByFechaHoraDesc();
    }

    @GetMapping("/recordatorios-historial/resumen")
    public Map<String, Object> resumen(HttpServletRequest request) {
        roleGuard.requireRole(request, RoleService.ADMINISTRADOR);

        LocalDate hoy = LocalDate.now();
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("fecha", hoy);
        respuesta.put(
                "fallosHoy",
                historialRepository.countByFechaAndExitoFalse(hoy));
        return respuesta;
    }

    @GetMapping("/alertas-error")
    public List<AlertaError> alertas(HttpServletRequest request) {
        roleGuard.requireRole(request, RoleService.ADMINISTRADOR);
        return alertaRepository.findAllByOrderByUltimoEnvioDesc();
    }
}
