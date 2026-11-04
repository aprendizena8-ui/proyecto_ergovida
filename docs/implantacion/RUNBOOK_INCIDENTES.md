# Runbook de Operaciones e Incidentes (Resiliencia con Nginx)

**Propósito:** Guía de acción para diagnosticar y mitigar fallos en la infraestructura de pruebas de ErgoVida (Nginx + 4 réplicas + Gunicorn).

---

## Incidente 1: Errores 502 Bad Gateway

**Descripción:**
Locust reporta errores HTTP 502. Nginx está arriba pero no puede comunicarse con el backend.

### Diagnóstico:

1. Revise el estado de las réplicas:

   ```bash
   docker compose ps
   ```

   (Busque contenedores en estado `unhealthy` o `restarting`)

2. Revise los logs de Nginx:

   ```bash
   docker compose logs nginx-balanceador --tail=20
   ```

   (Busque `no live upstreams` o `Connection refused`)

### Mitigación:

- **Si todas las réplicas están caídas:** Reinicie Nginx (`docker compose restart nginx-balanceador`) y luego las réplicas (`docker compose up -d api-backend`).
- **Si una réplica está caída:** Nginx la saca automáticamente, pero verifique que las otras 3 estén sanas.

---

## Incidente 2: Worker Timeout (CRITICAL)

**Descripción:** Locust reporta latencias altas o errores 500. En Dozzle o los logs aparece:

```text
[CRITICAL] WORKER TIMEOUT (pid=7)
[INFO] Booting worker with pid: 11
```

### Diagnóstico:

1. El `app.py` tiene un `time.sleep(1.2)` que simula un cálculo pesado.
2. Si Gunicorn tiene configurado `-t 3` (timeout de 3 segundos), las peticiones que tarden más de 3 segundos serán asesinadas por Gunicorn.

### Mitigación:

1. Ajustar el timeout de Gunicorn en el `Dockerfile` o `docker-compose.yml`:

   ```text
   gunicorn -w 4 --threads 4 -t 10 -b 0.0.0.0:5000 app:app
   ```

   (Aumentar `-t` a 10 segundos da más margen).

2. Usar workers asíncronos (Recomendado para producción):

   ```text
   gunicorn -k gevent -w 4 -b 0.0.0.0:5000 app:app
   ```

   (Los workers `gevent` pueden atender varias peticiones simultáneas sin bloquearse con `time.sleep`).

---

## Incidente 3: Contenedores OOM (Out of Memory)

**Descripción:** Un contenedor se apaga abruptamente bajo carga. Locust ve caídas de conexión.

### Diagnóstico:

1. Revise el consumo en vivo:

   ```bash
   docker stats
   ```

2. Verifique si el contenedor fue matado por OOM:

   ```bash
   docker inspect [ID_DEL_CONTENEDOR] | grep -i oom
   ```

### Mitigación:

1. Aumente el límite de memoria en `docker-compose.yml`:

   ```yaml
   deploy:
     resources:
       limits:
         memory: 256M
   ```

2. Reaplique con `docker compose up -d`.

---

## Procedimiento de Emergencia: Rollback

Si una nueva versión del código rompe la API:

1. Haga `git checkout` al commit anterior de `app.py` y `Dockerfile`.
2. Fuerce la recreación de las réplicas:

   ```bash
   docker compose up --build -d --no-deps --force-recreate api-backend
   ```
   