package com.ergovida.backend.service;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import com.ergovida.backend.model.User;
import com.ergovida.backend.repository.UserRepository;

import com.ergovida.backend.dto.LoginResponse;

@Service
public class AuthService {

    private final UserRepository repository;

    // private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();

    private final BCryptPasswordEncoder encoder;

    // public AuthService(UserRepository repository) {
    //     this.repository = repository;
    // }

    public AuthService(UserRepository repository,
                   BCryptPasswordEncoder encoder) {

    this.repository = repository;
    this.encoder = encoder;
}

    public User registrar(User user) {

        if (repository.existsByCorreo(user.getCorreo())) {
            throw new RuntimeException("El correo ya está registrado.");
        }

        user.setPassword(encoder.encode(user.getPassword()));

        user.setRol("USUARIO");

        user.setActivo(true);

        return repository.save(user);
    }

    // public User login(String correo, String password) {
    public LoginResponse login(String correo, String password) {

        User user = repository.findByCorreo(correo)
                .orElseThrow(() -> new RuntimeException("Usuario no encontrado"));

        if (!encoder.matches(password, user.getPassword())) {
            throw new RuntimeException("Contraseña incorrecta");
        }

        // return user;

        return new LoginResponse(
                user.getId(),
                user.getNombre(),
                user.getCorreo(),
                user.getRol()
        );
    }

}