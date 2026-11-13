package com.ergovida.backend.model;

import java.time.LocalDateTime;

import jakarta.persistence.*;

/**
 * Agrupa los errores repetidos para no enviar cientos de correos iguales.
 * La clave es un hash estable de tipo + modulo + mensaje.
 */
@Entity
@Table(
        name = "alertas_error",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_alerta_error_clave",
                columnNames = "clave"))
public class AlertaError {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 64)
    private String clave;

    @Column(length = 120)
    private String tipo;

    @Column(length = 190)
    private String modulo;

    @Column(columnDefinition = "TEXT")
    private String mensaje;

    @Column(nullable = false)
    private Integer veces = 0;

    @Column(name = "primera_vez", nullable = false)
    private LocalDateTime primeraVez;

    @Column(name = "ultimo_envio")
    private LocalDateTime ultimoEnvio;

    public AlertaError() {
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getClave() {
        return clave;
    }

    public void setClave(String clave) {
        this.clave = clave;
    }

    public String getTipo() {
        return tipo;
    }

    public void setTipo(String tipo) {
        this.tipo = tipo;
    }

    public String getModulo() {
        return modulo;
    }

    public void setModulo(String modulo) {
        this.modulo = modulo;
    }

    public String getMensaje() {
        return mensaje;
    }

    public void setMensaje(String mensaje) {
        this.mensaje = mensaje;
    }

    public Integer getVeces() {
        return veces;
    }

    public void setVeces(Integer veces) {
        this.veces = veces;
    }

    public LocalDateTime getPrimeraVez() {
        return primeraVez;
    }

    public void setPrimeraVez(LocalDateTime primeraVez) {
        this.primeraVez = primeraVez;
    }

    public LocalDateTime getUltimoEnvio() {
        return ultimoEnvio;
    }

    public void setUltimoEnvio(LocalDateTime ultimoEnvio) {
        this.ultimoEnvio = ultimoEnvio;
    }
}
