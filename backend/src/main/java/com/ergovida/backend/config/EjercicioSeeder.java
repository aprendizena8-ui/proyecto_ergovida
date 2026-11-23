package com.ergovida.backend.config;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import com.ergovida.backend.model.Ejercicio;
import com.ergovida.backend.repository.EjercicioRepository;

/**
 * Deja disponible el catálogo base de ejercicios en cualquier instalación.
 *
 * La app crea los ejercicios que faltan cuando el usuario tiene rol de
 * administrador o líder SST. Este seeder garantiza que los usuarios normales
 * también encuentren los registros y puedan registrar sus pausas.
 */
@Component
public class EjercicioSeeder implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(EjercicioSeeder.class);

    private final EjercicioRepository ejercicioRepository;

    public EjercicioSeeder(EjercicioRepository ejercicioRepository) {
        this.ejercicioRepository = ejercicioRepository;
    }

    @Override
    public void run(String... args) {
        Set<String> existentes = ejercicioRepository.findAll().stream()
                .map(Ejercicio::getNombre)
                .filter(nombre -> nombre != null && !nombre.isBlank())
                .map(EjercicioSeeder::normalizar)
                .collect(Collectors.toSet());

        List<Ejercicio> faltantes = new ArrayList<>();
        for (EjercicioBase base : CATALOGO) {
            if (existentes.contains(normalizar(base.nombre()))) {
                continue;
            }
            Ejercicio ejercicio = new Ejercicio();
            ejercicio.setNombre(base.nombre());
            ejercicio.setDescripcion(base.descripcion());
            ejercicio.setDuracion(base.duracion());
            ejercicio.setCategoria(base.categoria());
            faltantes.add(ejercicio);
        }

        if (!faltantes.isEmpty()) {
            ejercicioRepository.saveAll(faltantes);
            log.info("Catálogo de ejercicios: {} registros creados.", faltantes.size());
        }
    }

    private static String normalizar(String nombre) {
        return nombre.trim().toLowerCase(Locale.ROOT);
    }

    private record EjercicioBase(
            String nombre,
            String descripcion,
            int duracion,
            String categoria) {
    }

    private static final List<EjercicioBase> CATALOGO = List.of(
            new EjercicioBase(
                    "Estiramiento de Cuello",
                    "Libera la tensión del cuello con inclinaciones laterales suaves y controladas.",
                    2,
                    "Cuello"),
            new EjercicioBase(
                    "Movilidad de Hombros",
                    "Activa la circulación de hombros y espalda alta con encogimientos y círculos.",
                    3,
                    "Hombros"),
            new EjercicioBase(
                    "Descanso Visual",
                    "Reduce la fatiga visual alternando la mirada lejana con el descanso ocular.",
                    1,
                    "Vista"),
            new EjercicioBase(
                    "Movilidad de Muñecas",
                    "Previene molestias por teclado y mouse movilizando tus muñecas.",
                    2,
                    "Muñecas"),
            new EjercicioBase(
                    "Elevación de Brazos",
                    "Moviliza hombros y brazos con elevaciones completas por encima de la cabeza.",
                    2,
                    "Brazos"),
            new EjercicioBase(
                    "Flexión de Codos",
                    "Activa brazos y antebrazos con flexiones de codo controladas junto al cuerpo.",
                    2,
                    "Brazos"),
            new EjercicioBase(
                    "Apertura de Pecho",
                    "Contrarresta la postura encorvada abriendo el pecho y juntando los omóplatos.",
                    3,
                    "Espalda"),
            new EjercicioBase(
                    "Inclinación Lateral de Tronco",
                    "Estira la espalda y los costados con inclinaciones laterales suaves del tronco.",
                    3,
                    "Espalda"),
            new EjercicioBase(
                    "Rotación de Cuello",
                    "Mejora la movilidad cervical girando la cabeza a cada lado sin mover los hombros.",
                    2,
                    "Cuello"),
            new EjercicioBase(
                    "Flexión y Extensión de Cuello",
                    "Alivia la tensión cervical alternando la barbilla al pecho y la mirada al techo.",
                    2,
                    "Cuello"),
            new EjercicioBase(
                    "Círculos de Brazos",
                    "Activa hombros y espalda alta dibujando círculos amplios con los brazos extendidos.",
                    2,
                    "Hombros"),
            new EjercicioBase(
                    "Elevación Lateral de Brazos",
                    "Fortalece los hombros elevando los brazos hasta la altura de la línea del hombro.",
                    2,
                    "Hombros"),
            new EjercicioBase(
                    "Abrazo de Oso",
                    "Estira la espalda alta cruzando los brazos frente al pecho como un abrazo.",
                    2,
                    "Espalda"),
            new EjercicioBase(
                    "Prensa de Palmas",
                    "Activa pecho y brazos presionando las palmas juntas frente al esternón.",
                    2,
                    "Pecho"),
            new EjercicioBase(
                    "Estiramiento Cruzado de Hombro",
                    "Libera la parte posterior del hombro llevando un brazo cruzado al pecho.",
                    3,
                    "Hombros"),
            new EjercicioBase(
                    "Postura de Cactus",
                    "Corrige la postura con codos en cruz y antebrazos hacia arriba, juntando omóplatos.",
                    3,
                    "Espalda"),
            new EjercicioBase(
                    "Encogimiento Alterno de Hombros",
                    "Relaja cuello y hombros subiendo un hombro a la vez de forma controlada.",
                    2,
                    "Hombros"),
            new EjercicioBase(
                    "Apertura de Dedos",
                    "Estimula manos y antebrazos abriendo y cerrando los dedos por completo.",
                    2,
                    "Manos"),
            new EjercicioBase(
                    "Círculos de Antebrazos",
                    "Moviliza codos y muñecas dibujando círculos con los antebrazos junto al cuerpo.",
                    2,
                    "Codos"),
            new EjercicioBase(
                    "Toques de Hombro Alternos",
                    "Mejora la coordinación y movilidad de hombros tocando el hombro opuesto.",
                    2,
                    "Hombros"));
}
