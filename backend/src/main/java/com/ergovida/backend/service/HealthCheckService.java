package com.ergovida.backend.service;

import java.sql.Connection;
import java.sql.PreparedStatement;
import javax.sql.DataSource;

import org.springframework.stereotype.Service;

@Service
public class HealthCheckService {

    private final DataSource dataSource;

    public HealthCheckService(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    public boolean comprobarBaseDatos() {
        try (
            Connection connection = dataSource.getConnection();
            PreparedStatement statement = connection.prepareStatement("SELECT 1")
        ) {
            statement.executeQuery();
            return true;

        } catch (Exception e) {
            return false;
        }
    }
}