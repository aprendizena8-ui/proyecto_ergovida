-- Ejecutar en MySQL Workbench sobre la base de datos ergovida_db.
-- La tabla `usuarios` ya tiene la columna `rol`; no es necesario alterarla.

CREATE TABLE IF NOT EXISTS recordatorios_globales (
    id BIGINT NOT NULL AUTO_INCREMENT,
    hora TIME NOT NULL,
    dias_semana VARCHAR(20) NOT NULL DEFAULT '1,2,3,4,5,6,7',
    mensaje VARCHAR(255) NOT NULL,
    activo BIT(1) NOT NULL DEFAULT b'1',
    creado_por BIGINT NULL,
    fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Controla que cada usuario reciba una sola vez al dia cada recordatorio global.
CREATE TABLE IF NOT EXISTS recordatorios_globales_envios (
    id BIGINT NOT NULL AUTO_INCREMENT,
    recordatorio_id BIGINT NOT NULL,
    usuario_id BIGINT NOT NULL,
    fecha DATE NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_recordatorio_global_usuario_fecha (
        recordatorio_id, usuario_id, fecha
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Opcional: si alguna cuenta especial ya existía con otro rol, se puede
-- corregir manualmente. No se ejecuta automáticamente para no sobrescribir
-- cambios hechos por el administrador.
-- UPDATE usuarios SET rol = 'ADMINISTRADOR'
-- WHERE LOWER(TRIM(correo)) = 'ergovida.sena@gmail.com';
-- UPDATE usuarios SET rol = 'LIDER_SST'
-- WHERE LOWER(TRIM(correo)) IN ('kmorenoa@sena.edu.co', 'aprendizena8@gmail.com');
