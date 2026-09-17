package com.ergovida.backend.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.ergovida.backend.dto.LoginRequest;
import com.ergovida.backend.dto.RegisterRequest;
import com.ergovida.backend.model.User;
import com.ergovida.backend.service.AuthService;

import com.ergovida.backend.dto.LoginResponse;

@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*")
public class AuthController {

    private final AuthService service;

    public AuthController(AuthService service) {
        this.service = service;
    }

    @PostMapping("/register")
    // public ResponseEntity<User> register(@RequestBody RegisterRequest request) {
    public ResponseEntity<?> register(@RequestBody RegisterRequest request) {

        try {

            User user = new User();

            user.setNombre(request.getNombre());
            user.setCorreo(request.getCorreo());
            user.setPassword(request.getPassword());

            return ResponseEntity.ok(service.registrar(user));

        } catch (RuntimeException e) {

            return ResponseEntity
                    .badRequest()
                    .body(e.getMessage());
        }
    }

    @PostMapping("/login")
    // public ResponseEntity<User> login(@RequestBody LoginRequest request) {
    public ResponseEntity<?> login(@RequestBody LoginRequest request) {

        try {
            // return ResponseEntity.ok(
            LoginResponse response = service.login(
            //     service.login(
                    request.getCorreo(),
                    request.getPassword());
                    // )

            return ResponseEntity.ok(response);

        } catch (RuntimeException e) {

            return ResponseEntity
                    .badRequest()
                    .body(e.getMessage());
        }
    }
}