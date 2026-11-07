package com.ergovida.backend.dto;

import java.time.LocalDateTime;

public class UsuarioEstadisticaDTO {

    private Long id;
    private String nombre;
    private String correo;
    private String rol;
    private Boolean activo;
    private Long ejerciciosRealizados;
    private Boolean completo;
    private LocalDateTime ultimaActividad;

    public UsuarioEstadisticaDTO(
            Long id,
            String nombre,
            String correo,
            String rol,
            Boolean activo,
            Long ejerciciosRealizados,
            Boolean completo,
            LocalDateTime ultimaActividad) {
        this.id = id;
        this.nombre = nombre;
        this.correo = correo;
        this.rol = rol;
        this.activo = activo;
        this.ejerciciosRealizados = ejerciciosRealizados;
        this.completo = completo;
        this.ultimaActividad = ultimaActividad;
    }

    public UsuarioEstadisticaDTO() {
    }

    public Long getId() {
        return id;
    }

    public String getNombre() {
        return nombre;
    }

    public String getCorreo() {
        return correo;
    }

    public String getRol() {
        return rol;
    }

    public Boolean getActivo() {
        return activo;
    }

    public Long getEjerciciosRealizados() {
        return ejerciciosRealizados;
    }

    public Boolean getCompleto() {
        return completo;
    }

    public LocalDateTime getUltimaActividad() {
        return ultimaActividad;
    }
}
