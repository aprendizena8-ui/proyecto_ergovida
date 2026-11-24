package com.ergovida.backend.service;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.List;

import org.junit.jupiter.api.Test;

import com.ergovida.backend.model.RecordatorioGlobal;
import com.ergovida.backend.model.RecordatorioGlobalEnvio;
import com.ergovida.backend.model.User;
import com.ergovida.backend.repository.RecordatorioGlobalEnvioRepository;
import com.ergovida.backend.repository.RecordatorioGlobalRepository;
import com.ergovida.backend.repository.UserRepository;

class RecordatorioGlobalSchedulerTest {

    private static final ZoneId ZONA_BOGOTA = ZoneId.of("America/Bogota");

    private final RecordatorioGlobalRepository recordatorioRepository =
            mock(RecordatorioGlobalRepository.class);
    private final RecordatorioGlobalEnvioRepository envioRepository =
            mock(RecordatorioGlobalEnvioRepository.class);
    private final UserRepository userRepository =
            mock(UserRepository.class);
    private final EmailService emailService =
            mock(EmailService.class);

    private final RecordatorioGlobalScheduler scheduler =
            new RecordatorioGlobalScheduler(
                    recordatorioRepository,
                    envioRepository,
                    userRepository,
                    emailService);

    @Test
    void enviaElRecordatorioGlobalATodosLosUsuariosActivos() {
        LocalTime hora = LocalTime.now(ZONA_BOGOTA).withSecond(0).withNano(0);
        RecordatorioGlobal recordatorio = recordatorio(hora, "1,2,3,4,5,6,7");
        User ana = usuario(1L, "Ana", "ana@example.com", true);
        User luis = usuario(2L, "Luis", "luis@example.com", true);

        when(recordatorioRepository.findByActivoTrueOrderByHoraAsc())
                .thenReturn(List.of(recordatorio));
        when(userRepository.findAll()).thenReturn(List.of(ana, luis));

        scheduler.enviarRecordatoriosGlobales();

        verify(emailService).enviarRecordatorioGlobal(
                "ana@example.com", "Ana", "Pausa activa", hora);
        verify(emailService).enviarRecordatorioGlobal(
                "luis@example.com", "Luis", "Pausa activa", hora);
        verify(envioRepository, times(2)).save(any(RecordatorioGlobalEnvio.class));
    }

    @Test
    void omiteUsuariosInactivosOSinCorreo() {
        LocalTime hora = LocalTime.now(ZONA_BOGOTA).withSecond(0).withNano(0);
        RecordatorioGlobal recordatorio = recordatorio(hora, "1,2,3,4,5,6,7");
        User inactivo = usuario(1L, "Ana", "ana@example.com", false);
        User sinCorreo = usuario(2L, "Luis", " ", true);

        when(recordatorioRepository.findByActivoTrueOrderByHoraAsc())
                .thenReturn(List.of(recordatorio));
        when(userRepository.findAll()).thenReturn(List.of(inactivo, sinCorreo));

        scheduler.enviarRecordatoriosGlobales();

        verifyNoInteractions(emailService);
        verify(envioRepository, never()).save(any(RecordatorioGlobalEnvio.class));
    }

    @Test
    void noRepiteElEnvioDelMismoUsuarioElMismoDia() {
        LocalTime hora = LocalTime.now(ZONA_BOGOTA).withSecond(0).withNano(0);
        RecordatorioGlobal recordatorio = recordatorio(hora, "1,2,3,4,5,6,7");
        User ana = usuario(1L, "Ana", "ana@example.com", true);

        when(recordatorioRepository.findByActivoTrueOrderByHoraAsc())
                .thenReturn(List.of(recordatorio));
        when(userRepository.findAll()).thenReturn(List.of(ana));
        when(envioRepository.existsByRecordatorioIdAndUsuarioIdAndFecha(
                eq(recordatorio.getId()), eq(ana.getId()), any(LocalDate.class)))
                .thenReturn(true);

        scheduler.enviarRecordatoriosGlobales();

        verifyNoInteractions(emailService);
        verify(envioRepository, never()).save(any(RecordatorioGlobalEnvio.class));
    }

    @Test
    void omiteRecordatoriosQueNoAplicanHoy() {
        LocalTime hora = LocalTime.now(ZONA_BOGOTA).withSecond(0).withNano(0);
        int manana = LocalDate.now(ZONA_BOGOTA).getDayOfWeek().getValue() % 7 + 1;
        RecordatorioGlobal recordatorio = recordatorio(hora, String.valueOf(manana));
        User ana = usuario(1L, "Ana", "ana@example.com", true);

        when(recordatorioRepository.findByActivoTrueOrderByHoraAsc())
                .thenReturn(List.of(recordatorio));
        when(userRepository.findAll()).thenReturn(List.of(ana));

        scheduler.enviarRecordatoriosGlobales();

        verifyNoInteractions(emailService);
        verify(userRepository, never()).findById(anyLong());
    }

    private RecordatorioGlobal recordatorio(LocalTime hora, String dias) {
        RecordatorioGlobal recordatorio = new RecordatorioGlobal();
        recordatorio.setId(10L);
        recordatorio.setHora(hora);
        recordatorio.setDiasSemana(dias);
        recordatorio.setMensaje("Pausa activa");
        recordatorio.setActivo(true);
        return recordatorio;
    }

    private User usuario(Long id, String nombre, String correo, boolean activo) {
        User usuario = new User();
        usuario.setId(id);
        usuario.setNombre(nombre);
        usuario.setCorreo(correo);
        usuario.setActivo(activo);
        usuario.setRecordatorios(true);
        usuario.setRecordatoriosCorreo(true);
        return usuario;
    }
}
