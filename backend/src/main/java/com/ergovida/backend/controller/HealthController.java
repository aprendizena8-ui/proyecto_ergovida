package com.ergovida.backend.controller;

import java.lang.management.ManagementFactory;
import java.lang.management.RuntimeMXBean;
import java.util.HashMap;
import java.util.Map;

import jakarta.servlet.http.HttpServletRequest;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.ergovida.backend.service.HealthCheckService;

@RestController
@RequestMapping("/api")
public class HealthController {

    private final HealthCheckService healthCheckService;

    public HealthController(HealthCheckService healthCheckService) {
        this.healthCheckService = healthCheckService;
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health(
        HttpServletRequest httpRequest) {

        RuntimeMXBean runtimeMXBean = ManagementFactory.getRuntimeMXBean();

        long uptime = runtimeMXBean.getUptime();

        String origenIp = httpRequest.getRemoteAddr();

        boolean databaseUp = healthCheckService.comprobarBaseDatos(origenIp);

        Map<String, Object> response = new HashMap<>();

        response.put("status", databaseUp ? "UP" : "DOWN");
        response.put("uptime", uptime);
        response.put("database", databaseUp ? "UP" : "DOWN");

        if (databaseUp) {
            return ResponseEntity.ok(response);
        }

        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                .body(response);
    }
}