package com.ergovida.backend.model;

/**
 * Valores explícitos del tipo de actividad registrada.
 *
 * Solo {@code ejercicio_detectado} cuenta para el seguimiento del Líder SST.
 * Ambos tipos cuentan para los logros de la persona usuaria.
 */
public final class TiposActividad {

    public static final String EJERCICIO_DETECTADO = "ejercicio_detectado";
    public static final String RUTINA_ADICIONAL = "rutina_adicional";

    private TiposActividad() {
    }

    /**
     * Los registros anteriores a la columna {@code tipo} se tratan como
     * ejercicios detectados para no perder su progreso ya acumulado.
     */
    public static String normalizar(String tipo) {
        if (tipo == null || tipo.isBlank()) {
            return EJERCICIO_DETECTADO;
        }
        String valor = tipo.trim().toLowerCase();
        return RUTINA_ADICIONAL.equals(valor)
                ? RUTINA_ADICIONAL
                : EJERCICIO_DETECTADO;
    }

    public static boolean esDetectado(String tipo) {
        return EJERCICIO_DETECTADO.equals(normalizar(tipo));
    }

    public static boolean esRutina(String tipo) {
        return RUTINA_ADICIONAL.equals(normalizar(tipo));
    }
}
