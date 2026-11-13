-- ErgoVida - Alertas por correo, solicitudes de ayuda, push e historial
-- Ejecutar en MySQL Workbench sobre la base de datos ergovida_db.
-- Es idempotente: no elimina ni modifica datos existentes.

-- ---------------------------------------------------------------------------
-- 1. Correos de administradores que reciben alertas y solicitudes de ayuda
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS correos_administradores (
    id BIGINT NOT NULL AUTO_INCREMENT,
    correo VARCHAR(190) NOT NULL,
    nombre VARCHAR(120) NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_correo_administrador (correo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 2. Solicitudes de ayuda enviadas desde Ajustes (usuario y lider SST)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS solicitudes_ayuda (
    id BIGINT NOT NULL AUTO_INCREMENT,
    usuario_id BIGINT NOT NULL,
    nombre VARCHAR(255) NULL,
    correo VARCHAR(255) NULL,
    rol VARCHAR(50) NULL,
    asunto VARCHAR(150) NOT NULL,
    descripcion TEXT NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_resolucion DATETIME NULL,
    PRIMARY KEY (id),
    KEY idx_solicitud_ayuda_usuario (usuario_id),
    KEY idx_solicitud_ayuda_estado (estado),
    KEY idx_solicitud_ayuda_fecha (fecha_creacion)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 3. Tokens de dispositivos para notificaciones push (FCM)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS dispositivos_push (
    id BIGINT NOT NULL AUTO_INCREMENT,
    usuario_id BIGINT NOT NULL,
    token VARCHAR(512) NOT NULL,
    plataforma VARCHAR(30) NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_dispositivo_push_token (token),
    KEY idx_dispositivo_push_usuario (usuario_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 4. Agrupacion de errores para no enviar correos duplicados
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS alertas_error (
    id BIGINT NOT NULL AUTO_INCREMENT,
    clave VARCHAR(64) NOT NULL,
    tipo VARCHAR(120) NULL,
    modulo VARCHAR(190) NULL,
    mensaje TEXT NULL,
    veces INT NOT NULL DEFAULT 0,
    primera_vez DATETIME NOT NULL,
    ultimo_envio DATETIME NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_alerta_error_clave (clave)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 5. Historial de entregas de recordatorios (push y correo)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS recordatorios_envios_historial (
    id BIGINT NOT NULL AUTO_INCREMENT,
    tipo_recordatorio VARCHAR(20) NOT NULL,
    recordatorio_id BIGINT NULL,
    horario_id BIGINT NULL,
    usuario_id BIGINT NOT NULL,
    canal VARCHAR(10) NOT NULL,
    exito BOOLEAN NOT NULL DEFAULT FALSE,
    error TEXT NULL,
    fecha DATE NOT NULL,
    fecha_hora DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_historial_fecha (fecha),
    KEY idx_historial_recordatorio_usuario (
        tipo_recordatorio,
        recordatorio_id,
        usuario_id
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 6. Recordatorios globales y control de envios por usuario
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS recordatorios_globales (
    id BIGINT NOT NULL AUTO_INCREMENT,
    hora TIME NOT NULL,
    dias_semana VARCHAR(20) NULL,
    mensaje VARCHAR(255) NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    creado_por BIGINT NULL,
    fecha_creacion DATETIME NULL,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS recordatorios_globales_envios (
    id BIGINT NOT NULL AUTO_INCREMENT,
    recordatorio_id BIGINT NOT NULL,
    usuario_id BIGINT NOT NULL,
    fecha DATE NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_recordatorio_global_usuario_fecha (
        recordatorio_id,
        usuario_id,
        fecha
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 7. Columnas usadas por los recordatorios (solo si no existen)
-- ---------------------------------------------------------------------------
SET @existe_ultimo_envio = (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'horarios'
      AND COLUMN_NAME = 'ultimo_envio'
);
SET @sql_ultimo_envio = IF(
    @existe_ultimo_envio = 0,
    'ALTER TABLE horarios ADD COLUMN ultimo_envio DATE NULL',
    'SELECT 1'
);
PREPARE stmt_ultimo_envio FROM @sql_ultimo_envio;
EXECUTE stmt_ultimo_envio;
DEALLOCATE PREPARE stmt_ultimo_envio;

SET @existe_recordatorios_correo = (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'usuarios'
      AND COLUMN_NAME = 'recordatorios_correo'
);
SET @sql_recordatorios_correo = IF(
    @existe_recordatorios_correo = 0,
    'ALTER TABLE usuarios ADD COLUMN recordatorios_correo BOOLEAN NOT NULL DEFAULT TRUE',
    'SELECT 1'
);
PREPARE stmt_recordatorios_correo FROM @sql_recordatorios_correo;
EXECUTE stmt_recordatorios_correo;
DEALLOCATE PREPARE stmt_recordatorios_correo;

-- ---------------------------------------------------------------------------
-- 8. Correo administrador inicial (no duplica si ya existe)
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO correos_administradores (
    correo,
    nombre,
    activo,
    fecha_creacion
) VALUES (
    'ergovida.sena@gmail.com',
    'Administrador ErgoVida',
    TRUE,
    NOW()
);
