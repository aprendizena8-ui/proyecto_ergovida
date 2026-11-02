package com.ergovida.backend.controller;

import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.ergovida.backend.dto.RankingEntry;
import com.ergovida.backend.model.User;
import com.ergovida.backend.repository.PausaRealizadaRepository;
import com.ergovida.backend.repository.UserRepository;

@RestController
@RequestMapping("/api/ranking")
@CrossOrigin(origins = "*")
public class RankingController {

    private final PausaRealizadaRepository pausaRepository;
    private final UserRepository userRepository;

    public RankingController(
            PausaRealizadaRepository pausaRepository,
            UserRepository userRepository) {
        this.pausaRepository = pausaRepository;
        this.userRepository = userRepository;
    }

    @GetMapping
    public List<RankingEntry> getRanking() {
        Map<Long, User> usuarios = userRepository.findAll().stream()
                .collect(Collectors.toMap(User::getId, Function.identity()));

        return pausaRepository.contarPausasPorUsuario().stream()
                .map(fila -> {
                    Long usuarioId = ((Number) fila[0]).longValue();
                    Long total = ((Number) fila[1]).longValue();
                    User usuario = usuarios.get(usuarioId);
                    String nombre = usuario != null && usuario.getNombre() != null
                            ? usuario.getNombre()
                            : "Usuario";
                    return new RankingEntry(
                            usuarioId,
                            nombre,
                            usuario != null ? usuario.getAvatar() : null,
                            usuario != null ? usuario.getFotoPerfil() : null,
                            total
                    );
                })
                .filter(entry -> entry.getTotalPausas() != null && entry.getTotalPausas() > 0)
                .sorted(Comparator.comparing(RankingEntry::getTotalPausas).reversed())
                .toList();
    }
}
