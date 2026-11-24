package com.ergovida.backend.service;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

class RoleServiceTest {

    private final RoleService roleService = new RoleService(
            "ergovida.sena@gmail.com,admin2@sena.edu.co",
            " Kmorenoa@Sena.edu.co ");

    @Test
    void asignaAdministradorSinDistinguirMayusculasNiEspacios() {
        assertEquals(
                RoleService.ADMINISTRADOR,
                roleService.rolParaCorreo("  ERGOVIDA.SENA@GMAIL.COM "));
        assertEquals(
                RoleService.ADMINISTRADOR,
                roleService.rolParaCorreo("admin2@sena.edu.co"));
    }

    @Test
    void asignaLiderSstSinDistinguirMayusculasNiEspacios() {
        assertEquals(
                RoleService.LIDER_SST,
                roleService.rolParaCorreo(" KMORENOA@sena.edu.co "));
    }

    @Test
    void elRestoDeCorreosSonUsuarios() {
        assertEquals(
                RoleService.USUARIO,
                roleService.rolParaCorreo(" persona@example.com "));
    }
}
