package com.ergovida.backend.dto;

public record PausaRequest(Long usuarioId, Long ejercicioId, Boolean completada) {}