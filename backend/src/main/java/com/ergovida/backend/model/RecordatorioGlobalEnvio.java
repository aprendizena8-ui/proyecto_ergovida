package com.ergovida.backend.model;

import java.time.LocalDate;

import jakarta.persistence.*;

/**
 * Registra que un recordatorio global ya fue enviado por correo a un usuario
 * en una fecha determinada, para no repetir el envio.
 */
@Entity
@Table(
        name = "recordatorios_globales_envios",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_recordatorio_global_usuario_fecha",
                columnNames = {"recordatorio_id", "usuario_id", "fecha"}))
public class RecordatorioGlobalEnvio {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "recordatorio_id", nullable = false)
    private Long recordatorioId;

    @Column(name = "usuario_id", nullable = false)
    private Long usuarioId;

    @Column(nullable = false)
    private LocalDate fecha;

    public RecordatorioGlobalEnvio() {
    }

    public RecordatorioGlobalEnvio(Long recordatorioId, Long usuarioId, LocalDate fecha) {
        this.recordatorioId = recordatorioId;
        this.usuarioId = usuarioId;
        this.fecha = fecha;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getRecordatorioId() {
        return recordatorioId;
    }

    public void setRecordatorioId(Long recordatorioId) {
        this.recordatorioId = recordatorioId;
    }

    public Long getUsuarioId() {
        return usuarioId;
    }

    public void setUsuarioId(Long usuarioId) {
        this.usuarioId = usuarioId;
    }

    public LocalDate getFecha() {
        return fecha;
    }

    public void setFecha(LocalDate fecha) {
        this.fecha = fecha;
    }
}
