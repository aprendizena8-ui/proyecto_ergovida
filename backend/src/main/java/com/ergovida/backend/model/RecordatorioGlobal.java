package com.ergovida.backend.model;

import java.time.LocalDateTime;
import java.time.LocalTime;

import jakarta.persistence.*;

/**
 * Recordatorio creado por el Líder de SST y visible para todos los usuarios.
 *
 * `diasSemana` guarda los dias ISO separados por coma: 1 = lunes ... 7 = domingo.
 */
@Entity
@Table(name = "recordatorios_globales")
public class RecordatorioGlobal {

    public static final String CANAL_AMBOS = "AMBOS";
    public static final String CANAL_PUSH = "PUSH";
    public static final String CANAL_CORREO = "CORREO";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private LocalTime hora;

    @Column(name = "dias_semana", length = 20)
    private String diasSemana;

    @Column(length = 255)
    private String mensaje;

    /** Canal de entrega: PUSH, CORREO o AMBOS. */
    @Column(length = 10)
    private String canal = CANAL_AMBOS;

    private Boolean activo = true;

    @Column(name = "creado_por")
    private Long creadoPor;

    @Column(name = "fecha_creacion")
    private LocalDateTime fechaCreacion;

    public RecordatorioGlobal() {
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public LocalTime getHora() {
        return hora;
    }

    public void setHora(LocalTime hora) {
        this.hora = hora;
    }

    public String getDiasSemana() {
        return diasSemana;
    }

    public void setDiasSemana(String diasSemana) {
        this.diasSemana = diasSemana;
    }

    public String getMensaje() {
        return mensaje;
    }

    public void setMensaje(String mensaje) {
        this.mensaje = mensaje;
    }

    public String getCanal() {
        return canal;
    }

    public void setCanal(String canal) {
        this.canal = canal;
    }

    public Boolean getActivo() {
        return activo;
    }

    public void setActivo(Boolean activo) {
        this.activo = activo;
    }

    public Long getCreadoPor() {
        return creadoPor;
    }

    public void setCreadoPor(Long creadoPor) {
        this.creadoPor = creadoPor;
    }

    public LocalDateTime getFechaCreacion() {
        return fechaCreacion;
    }

    public void setFechaCreacion(LocalDateTime fechaCreacion) {
        this.fechaCreacion = fechaCreacion;
    }
}
