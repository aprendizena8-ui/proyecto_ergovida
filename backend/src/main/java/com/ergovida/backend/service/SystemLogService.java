package com.ergovida.backend.service;

import org.springframework.stereotype.Service;

import com.ergovida.backend.model.NivelLog;
import com.ergovida.backend.model.SystemLog;
import com.ergovida.backend.repository.SystemLogRepository;

@Service
public class SystemLogService {

    private final SystemLogRepository repository;

    public SystemLogService(SystemLogRepository repository) {
        this.repository = repository;
    }

    public void registrar(NivelLog nivel, String origenIp, String mensaje) {
        SystemLog log = new SystemLog(nivel, origenIp, mensaje);
        repository.save(log);
    }
}