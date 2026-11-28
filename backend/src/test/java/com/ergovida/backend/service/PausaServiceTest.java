package com.ergovida.backend.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.ergovida.backend.dto.PausaRequest;
import com.ergovida.backend.model.Ejercicio;
import com.ergovida.backend.model.Estadistica;
import com.ergovida.backend.model.PausaRealizada;
import com.ergovida.backend.model.TiposActividad;
import com.ergovida.backend.repository.EjercicioRepository;
import com.ergovida.backend.repository.EstadisticaRepository;
import com.ergovida.backend.repository.PausaRealizadaRepository;
import com.ergovida.backend.repository.UserRepository;

@ExtendWith(MockitoExtension.class)
class PausaServiceTest {

    @Mock
    private PausaRealizadaRepository pausaRepo;
    @Mock
    private EstadisticaRepository estadisticaRepo;
    @Mock
    private EjercicioRepository ejercicioRepo;
    @Mock
    private UserRepository userRepo;

    @InjectMocks
    private PausaService service;

    @Test
    void guardaRutinaSinTocarEstadisticasSst() {
        when(userRepo.existsById(1L)).thenReturn(true);
        when(pausaRepo.save(any(PausaRealizada.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        PausaRealizada guardada = service.registrar(
                new PausaRequest(1L, 0L, true, TiposActividad.RUTINA_ADICIONAL));

        ArgumentCaptor<PausaRealizada> captor = ArgumentCaptor.forClass(PausaRealizada.class);
        verify(pausaRepo).save(captor.capture());
        assertEquals(TiposActividad.RUTINA_ADICIONAL, captor.getValue().getTipo());
        assertNull(captor.getValue().getEjercicioId());
        assertEquals(TiposActividad.RUTINA_ADICIONAL, guardada.getTipo());
        verify(estadisticaRepo, never()).save(any(Estadistica.class));
        verify(ejercicioRepo, never()).findById(any());
    }

    @Test
    void guardaEjercicioDetectadoYActualizaEstadisticas() {
        Ejercicio ejercicio = new Ejercicio();
        ejercicio.setId(10L);
        ejercicio.setDuracion(5);

        when(userRepo.existsById(1L)).thenReturn(true);
        when(ejercicioRepo.findById(10L)).thenReturn(Optional.of(ejercicio));
        when(estadisticaRepo.findByUsuarioIdAndFecha(any(), any()))
                .thenReturn(Optional.empty());
        when(pausaRepo.save(any(PausaRealizada.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        PausaRealizada guardada = service.registrar(
                new PausaRequest(1L, 10L, true, TiposActividad.EJERCICIO_DETECTADO));

        ArgumentCaptor<PausaRealizada> captor = ArgumentCaptor.forClass(PausaRealizada.class);
        verify(pausaRepo).save(captor.capture());
        assertEquals(TiposActividad.EJERCICIO_DETECTADO, captor.getValue().getTipo());
        assertEquals(10L, captor.getValue().getEjercicioId());
        assertEquals(TiposActividad.EJERCICIO_DETECTADO, guardada.getTipo());

        ArgumentCaptor<Estadistica> stats = ArgumentCaptor.forClass(Estadistica.class);
        verify(estadisticaRepo).save(stats.capture());
        assertEquals(1, stats.getValue().getPausasRealizadas());
        assertEquals(5, stats.getValue().getMinutosActivos());
    }

    @Test
    void unRegistroSinTipoSeClasificaComoEjercicioDetectado() {
        Ejercicio ejercicio = new Ejercicio();
        ejercicio.setId(10L);
        when(userRepo.existsById(1L)).thenReturn(true);
        when(ejercicioRepo.findById(10L)).thenReturn(Optional.of(ejercicio));
        when(pausaRepo.save(any(PausaRealizada.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        PausaRealizada guardada = service.registrar(new PausaRequest(1L, 10L, false, null));

        assertEquals(TiposActividad.EJERCICIO_DETECTADO, guardada.getTipo());
        verify(estadisticaRepo, never()).save(any(Estadistica.class));
    }
}
