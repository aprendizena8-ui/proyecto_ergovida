package com.ergovida.backend.model;

import java.time.LocalDateTime;

import jakarta.persistence.*;

@Entity
@Table(name = "system_logs")
public class SystemLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "fecha_hora", nullable = false)
    private LocalDateTime fechaHora;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private NivelLog nivel;

    @Column(name = "origen_ip", length = 45)
    private String origenIp;

    @Column(columnDefinition = "TEXT", nullable = false)
    private String mensaje;

    public SystemLog() {
    }

    public SystemLog(NivelLog nivel, String origenIp, String mensaje) {
        this.fechaHora = LocalDateTime.now();
        this.nivel = nivel;
        this.origenIp = origenIp;
        this.mensaje = mensaje;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public LocalDateTime getFechaHora() {
        return fechaHora;
    }

    public void setFechaHora(LocalDateTime fechaHora) {
        this.fechaHora = fechaHora;
    }

    public NivelLog getNivel() {
        return nivel;
    }

    public void setNivel(NivelLog nivel) {
        this.nivel = nivel;
    }

    public String getOrigenIp() {
        return origenIp;
    }

    public void setOrigenIp(String origenIp) {
        this.origenIp = origenIp;
    }

    public String getMensaje() {
        return mensaje;
    }

    public void setMensaje(String mensaje) {
        this.mensaje = mensaje;
    }
}