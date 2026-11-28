-- Migración: tipificar los registros de actividad.
--
-- Cómo ejecutarlo en MySQL Workbench:
--   1. Conectarse a localhost:3306 y abrir el esquema ergovida_db.
--   2. Archivo > Abrir script SQL > este archivo.
--   3. Ejecutar con el rayo (Ctrl+Shift+Enter).
--   4. La última consulta debe mostrar solo `ejercicio_detectado`.
--
-- Es seguro ejecutarlo más de una vez: la columna se crea solo si no existe
-- (por ejemplo, si Hibernate ya la añadió con ddl-auto=update).
--
-- Antes del script `pausas_realizadas` no indicaba si el registro venía de un
-- ejercicio con detección o de una rutina adicional. Las rutinas antiguas no
-- se guardaban en esta tabla (solo localmente), por lo que todas las filas
-- existentes corresponden a ejercicios del catálogo y se clasifican como
-- `ejercicio_detectado` para conservar todo el progreso del Líder SST y de
-- los logros. No borra ni modifica ningún otro dato.

USE ergovida_db;

SET @existe_tipo := (
    SELECT COUNT(*)
      FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
       AND TABLE_NAME = 'pausas_realizadas'
       AND COLUMN_NAME = 'tipo'
);

SET @sql_tipo := IF(
    @existe_tipo = 0,
    'ALTER TABLE pausas_realizadas ADD COLUMN tipo VARCHAR(32) NULL',
    'SELECT 1'
);

PREPARE stmt_tipo FROM @sql_tipo;
EXECUTE stmt_tipo;
DEALLOCATE PREPARE stmt_tipo;

UPDATE pausas_realizadas
   SET tipo = 'ejercicio_detectado'
 WHERE tipo IS NULL OR tipo = '';

-- Verificación: `sin_tipo` debe ser 0 y la única fila debe ser
-- `ejercicio_detectado` (después aparecerá `rutina_adicional`).
SELECT
    SUM(tipo IS NULL OR tipo = '') AS sin_tipo,
    COUNT(*) AS registros_totales
  FROM pausas_realizadas;

SELECT tipo, COUNT(*) AS registros
  FROM pausas_realizadas
 GROUP BY tipo;
