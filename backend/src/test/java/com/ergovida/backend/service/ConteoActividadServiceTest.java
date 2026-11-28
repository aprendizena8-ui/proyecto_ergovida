package com.ergovida.backend.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.time.LocalDateTime;
import java.util.List;

import org.junit.jupiter.api.Test;

import com.ergovida.backend.model.PausaRealizada;
import com.ergovida.backend.model.TiposActividad;

class ConteoActividadServiceTest {

    private final ConteoActividadService service = new ConteoActividadService();

    @Test
    void laRutinaNoCuentaParaSstPeroSiParaLogros() {
        List<PausaRealizada> pausas = List.of(registro(TiposActividad.RUTINA_ADICIONAL, true));

        assertEquals(0, service.ejerciciosDetectados(pausas));
        assertEquals(1, service.rutinasAdicionales(pausas));
        assertEquals(1, service.ejerciciosDetectados(pausas) + service.rutinasAdicionales(pausas));
        assertFalse(service.ejerciciosDetectados(pausas) > 0);
    }

    @Test
    void elEjercicioDetectadoCuentaParaTodo() {
        List<PausaRealizada> pausas = List.of(registro(TiposActividad.EJERCICIO_DETECTADO, true));

        assertEquals(1, service.ejerciciosDetectados(pausas));
        assertEquals(0, service.rutinasAdicionales(pausas));
        assertTrue(service.ejerciciosDetectados(pausas) > 0);
        assertNotNull(service.ultimaActividadDetectada(pausas));
    }

    @Test
    void unEjercicioAbiertoPeroNoConfirmadoNoCuenta() {
        List<PausaRealizada> pausas = List.of(registro(TiposActividad.EJERCICIO_DETECTADO, false));

        assertEquals(0, service.ejerciciosDetectados(pausas));
        assertEquals(0, service.rutinasAdicionales(pausas));
    }

    @Test
    void losRegistrosAntiguosSinTipoConservanSuProgreso() {
        List<PausaRealizada> pausas = List.of(registro(null, true));

        assertEquals(1, service.ejerciciosDetectados(pausas));
        assertTrue(TiposActividad.esDetectado(null));
    }

    private PausaRealizada registro(String tipo, boolean completada) {
        PausaRealizada p = new PausaRealizada();
        p.setUsuarioId(1L);
        p.setEjercicioId(tipo == null ? 1L : 0L);
        p.setCompletada(completada);
        p.setFecha(LocalDateTime.of(2026, 11, 27, 10, 0));
        if (tipo != null) {
            p.setTipo(tipo);
        }
        return p;
    }
}
