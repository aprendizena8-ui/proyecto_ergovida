# ErgoVida — página informativa (landing del QR)

Sitio estático sin frameworks ni compilación: `index.html`, `styles.css`, `app.js` y `assets/`. No incluye instalables pesados: el botón móvil abre el APK alojado en Google Drive y el botón de escritorio abre la app desplegada en la web.

## 1. Configura los dos enlaces

Abre **`app.js`**. Las tres primeras variables son la única fuente de verdad:

```js
const URL_APK = 'https://drive.google.com/uc?export=download&id=TU_ID_DEL_APK';
const URL_WEB = 'https://ejemplo.com/ergovida-app/';
const SITE_URL = 'https://ejemplo.com/ergovida/';
```

### APK en Google Drive
Ya hay un APK compilado en `descargas/ErgoVida-v1.0.0-release.apk` (**153,4 MB**, SHA-256 `5AD06FFBFFA03A5BE92207E5BE6AAAA0DF163E67710450D34F5EB59A3FD77165`). Está compilado para **Android arm64** (la mayoría de los celulares actuales) e incluye la corrección del arranque en Android (pantalla negra). No lo subas a la landing: el botón debe apuntar a Drive.

1. Sube el APK a Drive.
2. Clic derecho → **Compartir** → **Cualquier persona con el enlace puede verlo** → copiar enlace.
3. El enlace se ve así: `https://drive.google.com/file/d/ABC123xyz/view?usp=sharing`.
4. Copia solo el ID (`ABC123xyz`) y pégalo en `URL_APK` reemplazando `TU_ID_DEL_APK`.
5. Prueba el enlace en un celular Android: debe descargar el `.apk`, no abrir un visor. Si Drive muestra una advertencia de escaneo, pulsa **Descargar de todas formas**.

### App en la web
Reemplaza `URL_WEB` por la URL donde despliegues la app (por ejemplo `https://ergovida-app.netlify.app`). El botón de escritorio abre esa página; no hay ZIP ni instalador.

Mientras queden valores de ejemplo, aparece un aviso amarillo arriba. Al reemplazarlos, el aviso desaparece solo.

### Open Graph / WhatsApp
WhatsApp no ejecuta JavaScript, así que edita también en `index.html`:
- `og:url` y `link rel="canonical"` → URL final de esta landing.
- `og:image` y `twitter:image` → URL absoluta de `assets/images/og-image.png`.

### Contenido editable
- Capturas de ejemplo: `assets/images/captura-01.png`, `captura-02.png`, `captura-03.png` (720×1280). Sobrescríbelas conservando los nombres.
- Correo y créditos: sección `#contacto` de `index.html`.
- Colores: variables al inicio de `styles.css` (paleta tomada de `lib/core/theme/app_theme.dart`).

## 2. Publicar la landing (Netlify, gratis)

1. Crea cuenta en <https://app.netlify.com/signup>.
2. Arrastra la carpeta `web_ergovida` a <https://app.netlify.com/drop>. **Antes:** saca de esa carpeta todo lo que no sea la landing (por ejemplo la subcarpeta `descargas/`, que contiene un JDK de tu equipo y no debe publicarse). Publica únicamente `index.html`, `styles.css`, `app.js`, `netlify.toml`, `assets/` y este `README.md`.
3. Para actualizaciones:
   ```powershell
   npm install -g netlify-cli
   netlify login
   netlify init
   netlify deploy --prod --dir=web_ergovida
   ```
4. Añade un dominio propio en *Site settings → Domain management* (HTTPS gratis).
5. Usa esa URL fija en el QR. Si cambian los enlaces de descarga, solo se edita `app.js`: el QR no se reimprime.

> GitHub Pages solo publica la raíz del repo o `docs/`; si lo usas, copia el contenido de `web_ergovida` a `docs/` o usa una GitHub Action. Netlify es más simple aquí.

## 3. QR para el pendón

1. Copia la URL final ya publicada (con `https://`) y ábrela en el celular.
2. Genera el QR en <https://www.qr-code-generator.com/> o <https://goqr.me/>.
3. Ajustes: corrección de errores **H**, **2000×2000 px** o SVG, margen blanco de 4 módulos, negro sobre blanco.
4. Tamaño físico mínimo: **8–10 cm**. Guarda el SVG para reimprimir sin pérdida.
5. Prueba el QR impreso desde 2–3 celulares antes de llevarlo a imprenta.

## 4. Verificación

- `node --check app.js` → sintaxis OK.
- Probado en Chrome headless a 390×844 (celular) y 1440×900 (escritorio): sin scroll horizontal, ambos botones visibles, detección Android/iOS/desktop correcta e imágenes cargadas.
- Con `F12 → Device toolbar` (Ctrl+Shift+M) puedes repetir la prueba con iPhone 12 / Pixel 5 y Desktop.

## Archivos

| Archivo | Para qué sirve |
| --- | --- |
| `index.html` | Contenido, metadatos y Open Graph |
| `app.js` | **Enlaces de Drive y de la app web** + detección de dispositivo |
| `styles.css` | Diseño mobile first y paleta ErgoVida |
| `assets/images/logo_ergovida.jpg` | Copia del logo oficial |
| `assets/images/captura-0X.png` | Capturas de ejemplo reemplazables |
| `assets/images/og-image.png` | Vista previa al compartir (1200×630) |
| `netlify.toml` | Configuración de publicación en Netlify |
