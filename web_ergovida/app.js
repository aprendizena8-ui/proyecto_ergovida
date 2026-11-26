/* =========================================================================
   CONFIGURACIÓN - CAMBIA AQUÍ LOS ENLACES ANTES DE PUBLICAR
   ========================================================================= */
// Enlace directo del APK en Google Drive:
// https://drive.google.com/uc?export=download&id=ID_DEL_ARCHIVO
const URL_APK = 'https://drive.google.com/drive/folders/1FbnS1FyhcKu23kuCUeZ0rAPx8gpL5wuA?usp=sharing';
// URL de la app desplegada en la web (reemplaza el dominio de ejemplo).
const URL_WEB = 'https://ejemplo.com/ergovida-app/';
const SITE_URL = 'https://ejemplo.com/ergovida/'; // usado para el canonical
/* ========================================================================= */

(function () {
  'use strict';

  // Aplica los enlaces a TODOS los botones (hero + sección final).
  document.querySelectorAll('[data-download="apk"]').forEach(function (link) {
    link.setAttribute('href', URL_APK);
  });
  document.querySelectorAll('[data-download="windows"]').forEach(function (link) {
    link.setAttribute('href', URL_WEB);
  });

  // Detección sencilla por User-Agent. Ningún botón se oculta nunca.
  var ua = navigator.userAgent || '';
  var device = 'unknown';

  if (/iPhone|iPad|iPod/i.test(ua)) {
    device = 'ios';
  } else if (/Android/i.test(ua)) {
    device = 'android';
  } else if (/Windows|Win32|Win64|Macintosh|Mac OS X|X11|Linux/i.test(ua)) {
    device = 'desktop';
  }

  document.documentElement.setAttribute('data-device', device);

  if (device === 'ios') {
    var notice = document.getElementById('ios-notice');
    if (notice) notice.hidden = false;
  }

  document.querySelectorAll('link[rel="canonical"]').forEach(function (link) {
    link.setAttribute('href', SITE_URL);
  });

  // Aviso temporal mientras queden valores de ejemplo.
  var pendiente = /TU_ID_DEL_APK|ejemplo\.com/i.test(URL_APK + ' ' + URL_WEB);
  var aviso = document.getElementById('setup-note');
  if (aviso) aviso.hidden = !pendiente;

  if (pendiente) {
    console.warn('ErgoVida: configura URL_APK y URL_WEB en app.js antes de publicar.');
  }
})();
