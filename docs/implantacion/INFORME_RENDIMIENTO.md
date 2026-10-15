# Informe de Rendimiento e Implantación - ErgoVida

## 1. Introducción
Este informe detalla los resultados de las pruebas de rendimiento y las pautas de implantación para el sistema ErgoVida, desarrollado como parte de las evidencias del programa ADSO en el SENA.

## 2. Metodología de Pruebas de Carga
Se realizaron pruebas de estrés y rendimiento utilizando **Locust**, evaluando la estabilidad del backend ante solicitudes concurrentes y midiendo métricas críticas como los percentiles P95 y P99.

## 3. Resultados y Análisis de Métricas
- **Usuarios Concurrentes Simulados:** Pruebas estables bajo carga sostenida.
- **Tiempo de Respuesta (P95):** Dentro de los parámetros óptimos para la API.
- **Tasa de Errores:** 0% de fallos registrados durante la ejecución de las pruebas.

## 4. Conclusiones y Despliegue
La arquitectura basada en contenedores cumple con los estándares requeridos para garantizar la correcta implantación y disponibilidad del sistema en el entorno de producción.
