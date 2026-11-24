-- Ejecutar en MySQL Workbench sobre ergovida_db.
-- Agrega el canal de entrega de los recordatorios globales creados por el Líder SST.
-- Valores permitidos: AMBOS (por defecto), PUSH, CORREO.
-- El backend con ddl-auto=update también crea la columna, este script la deja
-- explícita, con valor por defecto y sin tocar los recordatorios existentes.

SET @existe_canal = (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'recordatorios_globales'
      AND COLUMN_NAME = 'canal'
);

SET @sql_canal = IF(
    @existe_canal = 0,
    'ALTER TABLE recordatorios_globales ADD COLUMN canal VARCHAR(10) NOT NULL DEFAULT ''AMBOS''',
    'SELECT 1'
);
PREPARE stmt_canal FROM @sql_canal;
EXECUTE stmt_canal;
DEALLOCATE PREPARE stmt_canal;

UPDATE recordatorios_globales
SET canal = 'AMBOS'
WHERE canal IS NULL OR TRIM(canal) = '';
