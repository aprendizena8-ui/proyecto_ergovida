package com.ergovida.backend.service;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.stereotype.Service;

import com.ergovida.backend.model.PausaRealizada;
import com.ergovida.backend.model.TiposActividad;

/**
 * Reglas de conteo compartidas por el Líder SST y el ranking.
 *
 * Un ejercicio solo cuenta cuando la detección confirmó que se realizó
 * ({@code tipo = ejercicio_detectado} y {@code completada = true}). Las rutinas
 * adicionales se devuelven aparte, como dato informativo, y nunca se suman.
 */
@Service
public class ConteoActividadService {

    public long ejerciciosDetectados(List<PausaRealizada> pausas) {
        return pausas.stream()
                .filter(p -> TiposActividad.esDetectado(p.getTipo()))
                .filter(p -> Boolean.TRUE.equals(p.getCompletada()))
                .count();
    }

    public long rutinasAdicionales(List<PausaRealizada> pausas) {
        return pausas.stream()
                .filter(p -> TiposActividad.esRutina(p.getTipo()))
                .filter(p -> Boolean.TRUE.equals(p.getCompletada()))
                .count();
    }

    public LocalDateTime ultimaActividadDetectada(List<PausaRealizada> pausas) {
        return pausas.stream()
                .filter(p -> TiposActividad.esDetectado(p.getTipo()))
                .filter(p -> Boolean.TRUE.equals(p.getCompletada()))
                .map(PausaRealizada::getFecha)
                .filter(fecha -> fecha != null)
                .max(LocalDateTime::compareTo)
                .orElse(null);
    }
}
