package com.ergovida.backend.controller;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

import org.springframework.web.bind.annotation.*;

import com.ergovida.backend.config.RoleGuard;
import com.ergovida.backend.dto.UsuarioEstadisticaDTO;
import com.ergovida.backend.model.Estadistica;
import com.ergovida.backend.model.PausaRealizada;
import com.ergovida.backend.model.User;
import com.ergovida.backend.repository.EstadisticaRepository;
import com.ergovida.backend.repository.PausaRealizadaRepository;
import com.ergovida.backend.repository.UserRepository;
import com.ergovida.backend.service.ConteoActividadService;
import com.ergovida.backend.service.RoleService;

import jakarta.servlet.http.HttpServletRequest;

@RestController
@RequestMapping("/api/lider")
@CrossOrigin(origins = "*")
public class LiderController {

    private final UserRepository userRepository;
    private final PausaRealizadaRepository pausaRepository;
    private final EstadisticaRepository estadisticaRepository;
    private final ConteoActividadService conteoActividad;
    private final RoleGuard roleGuard;

    public LiderController(
            UserRepository userRepository,
            PausaRealizadaRepository pausaRepository,
            EstadisticaRepository estadisticaRepository,
            ConteoActividadService conteoActividad,
            RoleGuard roleGuard) {
        this.userRepository = userRepository;
        this.pausaRepository = pausaRepository;
        this.estadisticaRepository = estadisticaRepository;
        this.conteoActividad = conteoActividad;
        this.roleGuard = roleGuard;
    }

    @GetMapping("/estadisticas-usuarios")
    public List<UsuarioEstadisticaDTO> estadisticasUsuarios(HttpServletRequest request) {
        roleGuard.requireRole(request, RoleService.LIDER_SST);

        List<User> usuarios = userRepository.findAll();
        List<UsuarioEstadisticaDTO> resultado = new ArrayList<>();

        for (User usuario : usuarios) {
            List<PausaRealizada> pausas = pausaRepository.findByUsuarioId(usuario.getId());
            List<Estadistica> estadisticas = estadisticaRepository.findByUsuarioId(usuario.getId());

            // Solo los ejercicios con detección confirmada cuentan para SST.
            // Las rutinas se informan aparte y jamás se suman a este total.
            long ejerciciosDetectados = conteoActividad.ejerciciosDetectados(pausas);
            long rutinasAdicionales = conteoActividad.rutinasAdicionales(pausas);
            LocalDateTime ultimaActividad =
                    conteoActividad.ultimaActividadDetectada(pausas);

            for (Estadistica estadistica : estadisticas) {
                if (estadistica.getFecha() != null) {
                    LocalDateTime fecha = estadistica.getFecha().atStartOfDay();
                    if (ultimaActividad == null || fecha.isAfter(ultimaActividad)) {
                        ultimaActividad = fecha;
                    }
                }
            }

            resultado.add(new UsuarioEstadisticaDTO(
                    usuario.getId(),
                    usuario.getNombre(),
                    usuario.getCorreo(),
                    usuario.getRol(),
                    usuario.getActivo(),
                    ejerciciosDetectados,
                    ejerciciosDetectados > 0,
                    rutinasAdicionales,
                    ultimaActividad));
        }

        resultado.sort(Comparator.comparing(
                usuario -> usuario.getNombre() == null ? "" : usuario.getNombre(),
                String.CASE_INSENSITIVE_ORDER));

        return resultado;
    }
}
