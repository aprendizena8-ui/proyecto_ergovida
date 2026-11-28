package com.ergovida.backend.dto;

public record PausaRequest(
        Long usuarioId,
        Long ejercicioId,
        Boolean completada,
        String tipo) {

    /** Compatibilidad con clientes que aún no envían el tipo explícito. */
    public PausaRequest(Long usuarioId, Long ejercicioId, Boolean completada) {
        this(usuarioId, ejercicioId, completada, null);
    }
}
