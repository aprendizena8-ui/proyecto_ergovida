# Manual de Instalación y Despliegue - ErgoVida

## 1. Descripción del Proyecto
Este documento describe el proceso de despliegue del sistema **ErgoVida**, una aplicación de escritorio para pausas activas inteligentes, compuesta por un Frontend en Flutter, un Backend en Spring Boot y una Base de Datos MySQL.

## 2. Arquitectura del Sistema
- **Frontend:** Flutter (Dart) para Windows (ejecutable `.exe`).
- **Backend:** Spring Boot (Java 17) expuesto en el puerto `8080`.
- **Base de Datos:** MySQL 8.0 en el puerto `3306`.
- **Servicio de Correos:** Gmail SMTP (para verificación de correos).

## 3. Prerrequisitos de Software
Antes de iniciar, asegúrese de tener instalado:
* **Flutter SDK** (v3.0 o superior)
* **Java JDK 17**
* **Maven** (incluido en el proyecto con `mvnw`)
* **MySQL 8.0** (con MySQL Workbench o phpMyAdmin)
* **Visual Studio 2022 Community** (Obligatorio). Descárguelo de [https://visualstudio.microsoft.com/es/downloads/](https://visualstudio.microsoft.com/es/downloads/).
  - ** Importante:** Durante la instalación, asegúrese de seleccionar la carga de trabajo **"Desarrollo para el escritorio con C++"** (Desktop development with C++). Sin esto, Flutter no podrá compilar la app para Windows.
* **Visual Studio Code** (Recomendado) con la extensión de Flutter y Dart.
* **Git**
* Sistema Operativo: Windows 10 / 11

## 4. Pasos de Instalación

### Paso 1: Clonar el repositorio
```bash
git clone https://github.com/aprendizena8-ui/proyecto_ergovida.git
cd proyecto_ergovida
```

### Paso 2: Configuración de la Base de Datos
1. Abra MySQL y cree la base de datos vacía:

   ```sql
   CREATE DATABASE IF NOT EXISTS ergovida_db;
   ```

El backend (Spring Boot) creará automáticamente todas las tablas necesarias gracias a `spring.jpa.hibernate.ddl-auto=update`.

### Paso 3: Configuración del Backend
1. Vaya a la carpeta `backend/src/main/resources/`.
2. Verifique que el archivo `application.properties` tenga los datos correctos de conexión:

   ```properties
   spring.datasource.url=jdbc:mysql://localhost:3306/ergovida_db
   spring.datasource.username=root
   spring.datasource.password=
   ```

3. Verifique la configuración de correo (necesaria para verificación):

   ```properties
   spring.mail.username=ergovida.sena@gmail.com
   spring.mail.password=uyjzbijcqvalmbkd
   ```

### Paso 4: Ejecutar el Backend
Desde la carpeta `backend`, ejecute:

```bash
.\mvnw spring-boot:run
```

El servidor estará disponible en `http://localhost:8080`.

### Paso 5: Ejecutar el Frontend (Flutter)
Desde la carpeta raíz del proyecto, ejecute:

```bash
flutter pub get
flutter run -d windows
```

## 5. Verificación de Despliegue (Smoke Tests)

1. **Verificar estado del backend:**
   Abra en el navegador o Postman:

   ```text
   GET http://localhost:8080/api/health
   ```

   (Debe devolver `200 OK` con `{"status":"UP"}`)

2. **Verificar conexión con la base de datos:**
   El backend deberá conectarse sin errores (ver logs `HikariPool-1 - Start completed`).

3. **Probar el flujo de usuario:**
   * Registrarse con un correo real.
   * Recibir el código de verificación en el correo.
   * Iniciar sesión exitosamente.

## 6. Comandos de Operación Diaria

* **Reiniciar Backend:** `Ctrl + C` y volver a ejecutar `.\mvnw spring-boot:run`
* **Detener Backend:** `Ctrl + C`
* **Compilar app Flutter (release):** `flutter build windows --release`
* **Ubicación del .exe generado:** `build\windows\x64\runner\Release\`