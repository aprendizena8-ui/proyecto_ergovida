# Informe de Rendimiento e Implantación - ErgoVida

## 1. Introducción
Este informe detalla los resultados de las pruebas de rendimiento y las pautas de implantación para el sistema ErgoVida, desarrollado como parte de las evidencias del programa ADSO en el SENA.

## 2. Metodología de Pruebas de Carga
Se realizaron pruebas de estrés y rendimiento utilizando **Locust**, evaluando la estabilidad del backend ante solicitudes concurrentes y midiendo métricas críticas como el tiempo medio de respuesta, percentiles P95, P99 y la tasa de errores bajo diferentes niveles de concurrencia.

## 3. Resultados y Tabla Comparativa
A continuación se detallan los resultados obtenidos en las distintas ejecuciones de prueba realizadas sobre la API:

| Escenario / Carga | Usuarios Concurrentes | Tasa de Creación (spawn) | Tiempo Promedio (ms) | Percentil P95 (ms) | Percentil P99 (ms) | Tasa de Errores (%) | Estado |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Prueba Base** | 10 | 2 req/s | 45 ms | 78 ms | 110 ms | 0.0% | Éxito |
| **Carga Normal** | 50 | 5 req/s | 92 ms | 145 ms | 210 ms | 0.0% | Éxito |
| **Pico de Estrés** | 100 | 10 req/s | 185 ms | 290 ms | 420 ms | 0.2% | Aceptable |

## 4. Análisis Técnico
El análisis de percentiles (P95 y P99) demuestra que la arquitectura del backend en Flask y la infraestructura contenedorizada responden de manera óptima bajo condiciones de concurrencia moderada a alta. La ausencia de bloqueos significativos en las consultas concurrentes valida la correcta gestión de conexiones y la estabilidad general de la aplicación.

Asimismo, la ejecución de las pruebas mediante Locust permitió identificar umbrales de saturación estables, asegurando que los tiempos de procesamiento se mantengan dentro de rangos eficientes y adecuados para la experiencia del usuario final en el ecosistema ErgoVida.

## 5. Evidencia Gráfica / Captura de Pantalla
![Captura de Rendimiento y Pruebas]<img width="946" height="616" alt="image" src="https://github.com/user-attachments/assets/136b9e19-557e-4a74-8c4a-f6c96110656e" />


## 6. Conclusiones y Despliegue
La arquitectura basada en contenedores Docker y Flask gestiona eficientemente la concurrencia registrada, garantizando la correcta implantación y disponibilidad del sistema en el entorno de producción.
