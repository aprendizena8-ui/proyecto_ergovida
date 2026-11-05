# Manual de Instalación y Despliegue - ErgoVida (Resiliencia Local)

## 1. Descripción del Proyecto
Este documento describe cómo levantar la infraestructura de pruebas de resiliencia para el **Backend de ErgoVida** en un clúster local con Docker Compose. Incluye balanceo de carga con Nginx, réplicas de la API, observabilidad con Dozzle y pruebas de carga con Locust.

## 2. Arquitectura del Sistema
- **Proxy Inverso:** Nginx (Puerto 80)
- **Backend:** Flask + Gunicorn (4 réplicas, Puerto interno 5000, con límite de 0.15 CPUs y 128MB RAM)
- **Observabilidad:** Dozzle (Puerto 8080)
- **Pruebas de Carga:** Locust (se ejecuta de forma local en el equipo)

## 3. Prerrequisitos de Software
Antes de iniciar, asegúrese de tener instalado:
- **Docker Desktop** (v20.10 o superior) con Docker Compose v2.
- **Python 3.10+** (para ejecutar Locust).
- **Git**.
- Sistema Operativo: Windows 10/11 con WSL2.

## 4. Pasos de Instalación

### Paso 1: Clonar el repositorio
```bash
git clone https://github.com/aprendizena8-ui/proyecto_ergovida.git
cd proyecto_ergovida
```

### Paso 2: Instalar dependencias de Locust (Local)
Abra una terminal fuera de Docker (en su equipo) y ejecute:

```bash
pip install locust
```

### Paso 3: Desplegar la infraestructura
Levante todos los servicios (Nginx, 4 réplicas de la API y Dozzle) en segundo plano:

```bash
docker compose up --build -d
```

Tiempo estimado: 1-2 minutos (la primera vez descarga las imágenes).

### Paso 4: Verificar que todo esté corriendo
Ejecute:

```bash
docker compose ps
```

Debe ver:
- 1 contenedor `nginx-balanceador` (Up).
- 4 contenedores `api-backend-X` (Up).
- 1 contenedor `dozzle-monitor` (Up).

### Paso 5: Probar el Healthcheck
```bash
curl.exe -i http://localhost/health
```

Debe devolver `HTTP/1.1 200 OK` y el texto `OK`.

## 5. Ejecución de Pruebas con Locust
En una terminal (fuera de Docker), ejecute:

```bash
python -m locust -f locustfile.py
```

Abra su navegador en http://localhost:8089.

Configure:
- **Number of users:** 15 (o 50, según la prueba).
- **Spawn rate:** 5 usuarios/segundo.
- **Host:** `http://localhost`

Presione **Start**.

## 6. Comandos Útiles
- **Ver logs en vivo:** Abrir http://localhost:8080 (Dozzle).
- **Apagar todo:**
  ```bash
  docker compose down
  ```
- **Ver logs de una réplica específica:**
  ```bash
  docker compose logs -f api-backend-1
  ```