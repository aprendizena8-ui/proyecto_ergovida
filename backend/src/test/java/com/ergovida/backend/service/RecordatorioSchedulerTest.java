package com.ergovida.backend.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.Test;

import com.ergovida.backend.model.Horario;
import com.ergovida.backend.model.User;
import com.ergovida.backend.repository.HorarioRepository;
import com.ergovida.backend.repository.UserRepository;

class RecordatorioSchedulerTest {

    private final HorarioRepository horarioRepository =
            mock(HorarioRepository.class);
    private final UserRepository userRepository =
            mock(UserRepository.class);
    private final EmailService emailService =
            mock(EmailService.class);

    private final RecordatorioScheduler scheduler =
            new RecordatorioScheduler(
                    horarioRepository,
                    userRepository,
                    emailService);

    @Test
    void enviaElCorreoYRegistraElEnvio() {
        LocalTime hora = LocalTime.now().withSecond(0).withNano(0);
        Horario horario = horario(2L, hora);
        User usuario = usuario(2L, true);

        when(horarioRepository.findByHoraBetween(
                any(LocalTime.class),
                any(LocalTime.class))).thenReturn(List.of(horario));
        when(userRepository.findById(2L)).thenReturn(Optional.of(usuario));

        scheduler.enviarRecordatoriosPendientes();

        verify(emailService).enviarRecordatorioPausa(
                "ana@example.com",
                "Ana",
                hora);
        assertEquals(LocalDate.now(), horario.getUltimoEnvio());
        verify(horarioRepository).save(horario);
    }

    @Test
    void omiteUsuariosConRecordatoriosDesactivados() {
        Horario horario = horario(
                2L,
                LocalTime.now().withSecond(0).withNano(0));
        User usuario = usuario(2L, false);

        when(horarioRepository.findByHoraBetween(
                any(LocalTime.class),
                any(LocalTime.class))).thenReturn(List.of(horario));
        when(userRepository.findById(2L)).thenReturn(Optional.of(usuario));

        scheduler.enviarRecordatoriosPendientes();

        verifyNoInteractions(emailService);
        verify(horarioRepository, never()).save(any(Horario.class));
    }

    @Test
    void noRepiteUnRecordatorioYaEnviadoElMismoDia() {
        Horario horario = horario(
                2L,
                LocalTime.now().withSecond(0).withNano(0));
        horario.setUltimoEnvio(LocalDate.now());

        when(horarioRepository.findByHoraBetween(
                any(LocalTime.class),
                any(LocalTime.class))).thenReturn(List.of(horario));

        scheduler.enviarRecordatoriosPendientes();

        verifyNoInteractions(emailService);
        verify(userRepository, never()).findById(anyLong());
    }

    private Horario horario(Long usuarioId, LocalTime hora) {
        Horario horario = new Horario();
        horario.setId(1L);
        horario.setUsuarioId(usuarioId);
        horario.setHora(hora);
        return horario;
    }

    private User usuario(Long id, boolean recordatorios) {
        User usuario = new User();
        usuario.setId(id);
        usuario.setNombre("Ana");
        usuario.setCorreo("ana@example.com");
        usuario.setActivo(true);
        usuario.setRecordatorios(recordatorios);
        return usuario;
    }
}
