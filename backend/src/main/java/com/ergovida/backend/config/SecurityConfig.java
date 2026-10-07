package com.ergovida.backend.config;

import java.util.List;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

@Configuration
public class SecurityConfig {

    @Bean
    BCryptPasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOriginPatterns(List.of("http://localhost:*", "*"));
        configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(List.of("*"));
        configuration.setAllowCredentials(false);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }

    @Bean
    SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .httpBasic(httpBasic -> httpBasic.disable()) // Desactiva el prompt/mecanismo de autenticación básica
            .formLogin(form -> form.disable())           // Desactiva el formulario de login por defecto
            .authorizeHttpRequests(auth -> auth
                    .requestMatchers("/api/**").permitAll() // Permite el acceso a todos los endpoints de la API
                    // .requestMatchers("/api/auth/**").permitAll()
                    // .requestMatchers("/api/health").permitAll()
                    // .requestMatchers("/api/users/**").permitAll()
                    // .requestMatchers("/api/ejercicios/**").permitAll()
                    // .requestMatchers("/api/rutinas/**").permitAll()
                    // .requestMatchers("/api/horarios/**").permitAll()
                    // .requestMatchers("/api/estadisticas/**").permitAll()
                    // .requestMatchers("/api/pausas-realizadas/**").permitAll()
                    .anyRequest().permitAll()
            );

        return http.build();
    }
}