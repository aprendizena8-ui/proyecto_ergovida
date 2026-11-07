package com.ergovida.backend.controller;

import java.util.List;
import java.util.Locale;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import com.ergovida.backend.config.RoleGuard;
import com.ergovida.backend.model.User;
import com.ergovida.backend.repository.EstadisticaRepository;
import com.ergovida.backend.repository.HorarioRepository;
import com.ergovida.backend.repository.PausaRealizadaRepository;
import com.ergovida.backend.repository.UserRepository;
import com.ergovida.backend.service.RoleService;

import jakarta.servlet.http.HttpServletRequest;

@RestController
@RequestMapping("/api/users")
@CrossOrigin(origins = "*")
public class UserController {

    private final UserRepository userRepository;
    private final PausaRealizadaRepository pausaRepository;
    private final HorarioRepository horarioRepository;
    private final EstadisticaRepository estadisticaRepository;
    private final RoleGuard roleGuard;
    private final RoleService roleService;

    public UserController(
            UserRepository userRepository,
            PausaRealizadaRepository pausaRepository,
            HorarioRepository horarioRepository,
            EstadisticaRepository estadisticaRepository,
            RoleGuard roleGuard,
            RoleService roleService) {
        this.userRepository = userRepository;
        this.pausaRepository = pausaRepository;
        this.horarioRepository = horarioRepository;
        this.estadisticaRepository = estadisticaRepository;
        this.roleGuard = roleGuard;
        this.roleService = roleService;
    }

    // 1. GET: Consultar todos los usuarios (solo administrador y líder SST)
    @GetMapping
    public List<User> getAllUsers(HttpServletRequest request) {
        roleGuard.requireRole(request, RoleService.ADMINISTRADOR, RoleService.LIDER_SST);
        return userRepository.findAll();
    }

    // 2. GET: Consultar usuario por ID (el propio usuario, administrador o líder)
    @GetMapping("/{id}")
    public ResponseEntity<User> getUserById(
            @PathVariable Long id,
            HttpServletRequest request) {
        User actor = roleGuard.requireUser(request);
        validarAcceso(actor, id, true);
        return userRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // 3. PUT: Actualizar perfil de usuario
    @PutMapping("/{id}")
    public ResponseEntity<?> updateUser(
            @PathVariable Long id,
            @RequestBody User userDetails,
            HttpServletRequest request) {
        User actor = roleGuard.requireUser(request);
        validarAcceso(actor, id, false);

        boolean esAdmin = roleGuard.esAdmin(actor);

        return userRepository.findById(id).map(user -> {
            if (userDetails.getNombre() != null) user.setNombre(userDetails.getNombre());
            if (userDetails.getFotoPerfil() != null) user.setFotoPerfil(userDetails.getFotoPerfil());
            if (userDetails.getAvatar() != null) user.setAvatar(userDetails.getAvatar());
            if (userDetails.getNotificaciones() != null) user.setNotificaciones(userDetails.getNotificaciones());
            if (userDetails.getRecordatorios() != null) user.setRecordatorios(userDetails.getRecordatorios());
            if (userDetails.getRecordatoriosCorreo() != null) user.setRecordatoriosCorreo(userDetails.getRecordatoriosCorreo());

            // El correo solo se actualiza si quien edita es el dueño de la cuenta
            // o un administrador. Un usuario normal no puede cambiarlo por un
            // correo reservado (administrador o lider SST).
            if (userDetails.getCorreo() != null) {
                String nuevoCorreo = userDetails.getCorreo().trim().toLowerCase(Locale.ROOT);
                String rolReservado = roleService.rolParaCorreo(nuevoCorreo);
                if (!esAdmin && !RoleService.USUARIO.equals(rolReservado)) {
                    throw new ResponseStatusException(
                            HttpStatus.FORBIDDEN,
                            "Ese correo está reservado para un rol especial.");
                }
                user.setCorreo(nuevoCorreo);
            }

            // Rol y estado solo los puede cambiar un administrador. Así un
            // usuario normal no puede elevar sus permisos desde la app.
            if (esAdmin) {
                if (userDetails.getRol() != null) {
                    user.setRol(RoleService.normalizarRol(userDetails.getRol()));
                }
                if (userDetails.getActivo() != null) user.setActivo(userDetails.getActivo());
            }

            User updatedUser = userRepository.save(user);
            return ResponseEntity.ok(updatedUser);
        }).orElse(ResponseEntity.notFound().build());
    }

    // 4. DELETE: Eliminar un usuario por ID (administrador o la propia cuenta)
    @DeleteMapping("/{id}")
    @Transactional
    public ResponseEntity<?> deleteUser(
            @PathVariable Long id,
            HttpServletRequest request) {
        User actor = roleGuard.requireUser(request);
        validarAcceso(actor, id, false);

        return userRepository.findById(id).map(user -> {
            // Las tablas relacionadas tienen claves foraneas sin cascada.
            // Se eliminan primero sus registros para poder borrar la cuenta.
            pausaRepository.deleteByUsuarioId(id);
            horarioRepository.deleteByUsuarioId(id);
            estadisticaRepository.deleteByUsuarioId(id);
            userRepository.delete(user);
            return ResponseEntity.ok().build();
        }).orElse(ResponseEntity.notFound().build());
    }

    private void validarAcceso(User actor, Long idObjetivo, boolean permitirLider) {
        boolean esPropio = actor.getId() != null && actor.getId().equals(idObjetivo);
        boolean esAdmin = roleGuard.esAdmin(actor);
        boolean esLider = permitirLider && roleGuard.esLiderSst(actor);

        if (!esPropio && !esAdmin && !esLider) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "No tienes permisos para acceder a este usuario.");
        }
    }
}
