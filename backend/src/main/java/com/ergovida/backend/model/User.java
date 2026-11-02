package com.ergovida.backend.model;

import jakarta.persistence.*;

@Entity
@Table(name = "usuarios")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String nombre;

    @Column(unique = true)
    private String correo;

    private String password;

    private String rol;

    private String fotoPerfil;

    private String avatar;

    private Boolean activo;

    private Boolean notificaciones = true;

    private Boolean recordatorios = true;

    @Column(name = "recordatorios_correo")
    private Boolean recordatoriosCorreo = true;

    public User() {
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id=id;
    }

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre=nombre;
    }

    public String getCorreo() {
        return correo;
    }

    public void setCorreo(String correo) {
        this.correo=correo;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password=password;
    }

    public String getRol() {
        return rol;
    }

    public void setRol(String rol) {
        this.rol=rol;
    }

    public String getFotoPerfil() {
        return fotoPerfil;
    }

    public void setFotoPerfil(String fotoPerfil) {
        this.fotoPerfil=fotoPerfil;
    }

    public String getAvatar() {
        return avatar;
    }

    public void setAvatar(String avatar) {
        this.avatar=avatar;
    }

    public Boolean getActivo() {
        return activo;
    }

    public void setActivo(Boolean activo) {
        this.activo=activo;
    }

    public Boolean getNotificaciones() {
        return notificaciones;
    }

    public void setNotificaciones(Boolean notificaciones) {
        this.notificaciones=notificaciones;
    }

    public Boolean getRecordatorios() {
        return recordatorios;
    }

    public void setRecordatorios(Boolean recordatorios) {
        this.recordatorios=recordatorios;
    }

    public Boolean getRecordatoriosCorreo() {
        return recordatoriosCorreo;
    }

    public void setRecordatoriosCorreo(Boolean recordatoriosCorreo) {
        this.recordatoriosCorreo=recordatoriosCorreo;
    }
}