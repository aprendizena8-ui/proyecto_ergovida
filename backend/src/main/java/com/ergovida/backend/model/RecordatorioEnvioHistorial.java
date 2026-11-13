package com.ergovida.backend.model;

import java.time.LocalDate;
import java.time.LocalDateTime;

import jakarta.persistence.*;

/**
 * Historial de entregas de recordatorios (push o correo), con el resultado
 * de cada intento. Permite auditar envios y detectar fallos.
 */
@Entity
@Table(
        name = "recordatorios_envios_historial",
        indexes = {
                @Index(name = "idx_historial_fecha", columnList = "fecha"),
                @Index(
                        name = "idx_historial_recordatorio_usuario",
                        columnList = "tipo_recordatorio,recordatorio_id,usuario_id")
        })
public class RecordatorioEnvioHistorial {

    public static final String TIPO_GLOBAL = "GLOBAL";
    public static final String TIPO_PERSONAL = "PERSONAL";
    public static final String CANAL_PUSH = "PUSH";
    public static final String CANAL_EMAIL = "EMAIL";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tipo_recordatorio", nullable = false, length = 20)
    private String tipoRecordatorio;

    @Column(name = "recordatorio_id")
    private Long recordatorioId;

    @Column(name = "horario_id")
    private Long horarioId;

    @Column(name = "usuario_id", nullable = false)
    private Long usuarioId;

    @Column(nullable = false, length = 10)
    private String canal;

    @Column(nullable = false)
    private Boolean exito = false;

    @Column(columnDefinition = "TEXT")
    private String error;

    @Column(nullable = false)
    private LocalDate fecha;

    @Column(name = "fecha_hora", nullable = false)
    private LocalDateTime fechaHora;

    public RecordatorioEnvioHistorial() {
    }

    public RecordatorioEnvioHistorial(
            String tipoRecordatorio,
            Long recordatorioId,
            Long horarioId,
            Long usuarioId,
            String canal,
            boolean exito,
            String error,
            LocalDate fecha) {
        this.tipoRecordatorio = tipoRecordatorio;
        this.recordatorioId = recordatorioId;
        this.horarioId = horarioId;
        this.usuarioId = usuarioId;
        this.canal = canal;
        this.exito = exito;
        this.error = error;
        this.fecha = fecha;
        this.fechaHora = LocalDateTime.now();
    }

    @PrePersist
    public void prePersist() {
        if (fechaHora == null) {
            fechaHora = LocalDateTime.now();
        }
        if (fecha == null) {
            fecha = LocalDate.now();
        }
        if (exito == null) {
            exito = false;
        }
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getTipoRecordatorio() {
        return tipoRecordatorio;
    }

    public void setTipoRecordatorio(String tipoRecordatorio) {
        this.tipoRecordatorio = tipoRecordatorio;
    }

    public Long getRecordatorioId() {
        return recordatorioId;
    }

    public void setRecordatorioId(Long recordatorioId) {
        this.recordatorioId = recordatorioId;
    }

    public Long getHorarioId() {
        return horarioId;
    }

    public void setHorarioId(Long horarioId) {
        this.horarioId = horarioId;
    }

    public Long getUsuarioId() {
        return usuarioId;
    }

    public void setUsuarioId(Long usuarioId) {
        this.usuarioId = usuarioId;
    }

    public String getCanal() {
        return canal;
    }

    public void setCanal(String canal) {
        this.canal = canal;
    }

    public Boolean getExito() {
        return exito;
    }

    public void setExito(Boolean exito) {
        this.exito = exito;
    }

    public String getError() {
        return error;
    }

    public void setError(String error) {
        this.error = error;
    }

    public LocalDate getFecha() {
        return fecha;
    }

    public void setFecha(LocalDate fecha) {
        this.fecha = fecha;
    }

    public LocalDateTime getFechaHora() {
        return fechaHora;
    }

    public void setFechaHora(LocalDateTime fechaHora) {
        this.fechaHora = fechaHora;
    }
}
