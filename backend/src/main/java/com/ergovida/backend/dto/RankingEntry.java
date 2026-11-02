package com.ergovida.backend.dto;

public class RankingEntry {

    private Long usuarioId;
    private String nombre;
    private String avatar;
    private String fotoPerfil;
    private Long totalPausas;

    public RankingEntry() {
    }

    public RankingEntry(Long usuarioId, String nombre, String avatar, String fotoPerfil, Long totalPausas) {
        this.usuarioId = usuarioId;
        this.nombre = nombre;
        this.avatar = avatar;
        this.fotoPerfil = fotoPerfil;
        this.totalPausas = totalPausas;
    }

    public Long getUsuarioId() {
        return usuarioId;
    }

    public void setUsuarioId(Long usuarioId) {
        this.usuarioId = usuarioId;
    }

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }

    public String getAvatar() {
        return avatar;
    }

    public void setAvatar(String avatar) {
        this.avatar = avatar;
    }

    public String getFotoPerfil() {
        return fotoPerfil;
    }

    public void setFotoPerfil(String fotoPerfil) {
        this.fotoPerfil = fotoPerfil;
    }

    public Long getTotalPausas() {
        return totalPausas;
    }

    public void setTotalPausas(Long totalPausas) {
        this.totalPausas = totalPausas;
    }
}
