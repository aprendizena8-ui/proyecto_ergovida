# Backend local de ErgoVida

Este backend local permite probar el registro e inicio de sesión de la app sin depender de un servicio externo.

## Ejecutar

```powershell
cd backend
node server.js
```

La API queda disponible en:

- `http://127.0.0.1:8080/health`
- `POST http://127.0.0.1:8080/api/auth/register`
- `POST http://127.0.0.1:8080/api/auth/login`

## Ejemplo

```powershell
curl.exe -X POST http://127.0.0.1:8080/api/auth/register -H "Content-Type: application/json" -d "{\"name\":\"Ana\",\"email\":\"ana@ergovida.test\",\"password\":\"123456\"}"
```
