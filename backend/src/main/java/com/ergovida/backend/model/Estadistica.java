package com.ergovida.backend.model;

import jakarta.persistence.*;
import java.time.LocalDate;

@Entity
@Table(name = "estadisticas")
public class Estadistica {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "usuario_id")
    private Long usuarioId;

    @Column(name = "pausas_realizadas")
    private Integer pausasRealizadas;

    @Column(name = "minutos_activos")
    private Integer minutosActivos;

    private LocalDate fecha;

    public Estadistica() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getUsuarioId() { return usuarioId; }
    public void setUsuarioId(Long usuarioId) { this.usuarioId = usuarioId; }

    public Integer getPausasRealizadas() { return pausasRealizadas; }
    public void setPausasRealizadas(Integer pausasRealizadas) { this.pausasRealizadas = pausasRealizadas; }

    public Integer getMinutosActivos() { return minutosActivos; }
    public void setMinutosActivos(Integer minutosActivos) { this.minutosActivos = minutosActivos; }

    public LocalDate getFecha() { return fecha; }
    public void setFecha(LocalDate fecha) { this.fecha = fecha; }
}