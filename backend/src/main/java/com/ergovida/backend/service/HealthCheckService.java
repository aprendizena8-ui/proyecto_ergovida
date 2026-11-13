package com.ergovida.backend.service;

import java.sql.Connection;
import java.sql.PreparedStatement;

import javax.sql.DataSource;

import org.springframework.stereotype.Service;

import com.ergovida.backend.model.NivelLog;

@Service
public class HealthCheckService {

    private final DataSource dataSource;
    private final SystemLogService systemLogService;
    private final AlertaErrorService alertaErrorService;

    public HealthCheckService(
        DataSource dataSource,
        SystemLogService systemLogService,
        AlertaErrorService alertaErrorService) {

        this.dataSource = dataSource;
        this.systemLogService = systemLogService;
        this.alertaErrorService = alertaErrorService;
    }

    public boolean comprobarBaseDatos(String origenIp) {

        try (
            Connection connection = dataSource.getConnection();
            PreparedStatement statement = connection.prepareStatement("SELECT 1")
        ) {

            statement.executeQuery();

            return true;

        } catch (Exception e) {

            try {

                systemLogService.registrar(
                        NivelLog.ERROR,
                        origenIp,
                        "Error de conexión a la base de datos: " + e.getMessage()
                );

            } catch (Exception logException) {

                System.err.println(
                        "No fue posible guardar el error de conexión en system_logs: "
                                + logException.getMessage()
                );
            }

            if (alertaErrorService != null) {
                alertaErrorService.registrarError(
                        "Base de datos",
                        "HealthCheckService",
                        "Error de conexión a la base de datos",
                        e,
                        origenIp
                );
            }
            
            return false;
        }
    }
}