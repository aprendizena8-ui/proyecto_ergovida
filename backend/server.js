const http = require('http');
const crypto = require('crypto');
const { URL } = require('url');

const users = new Map();
const codigos = new Map();

let nodemailer = null;
try {
  nodemailer = require('nodemailer');
} catch (_) {
  // Sin nodemailer se devuelve el código en la respuesta para no bloquear el flujo.
}

const CODIGO_VIGENCIA_MS = 15 * 60 * 1000;

function normalizarCorreo(valor) {
  return String(valor ?? '').trim().toLowerCase();
}

function generarCodigo() {
  return String(crypto.randomInt(0, 1_000_000)).padStart(6, '0');
}

function correoValido(correo) {
  return /^[\w.+-]+@[\w-]+(\.[\w-]+)+$/.test(correo);
}

async function enviarCorreo(destinatario, codigo) {
  if (!nodemailer) return false;
  const usuario = process.env.SMTP_USER || 'ergovida.sena@gmail.com';
  const password = process.env.SMTP_PASS || 'uyjzbijcqvalmbkd';
  if (!usuario || !password) return false;

  const transporter = nodemailer.createTransport({
    host: 'smtp.gmail.com',
    port: 587,
    secure: false,
    auth: { user: usuario, pass: password },
  });

  await transporter.sendMail({
    from: usuario,
    to: destinatario,
    subject: 'ErgoVida - Código de verificación',
    text:
      `¡Hola!\n\nTu código de verificación es: ${codigo}\n\n` +
      'Ingrésalo en la app. El código vence en 15 minutos.\n\nEquipo ErgoVida',
  });
  return true;
}

function sendJson(res, statusCode, payload) {
  res.writeHead(statusCode, {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
  });
  res.end(JSON.stringify(payload));
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let data = '';

    req.on('data', (chunk) => {
      data += chunk;
      if (data.length > 1_000_000) {
        reject(new Error('Request body too large'));
        req.destroy();
      }
    });

    req.on('end', () => {
      if (!data) {
        resolve({});
        return;
      }

      try {
        resolve(JSON.parse(data));
      } catch (error) {
        reject(new Error('Invalid JSON body'));
      }
    });

    req.on('error', reject);
  });
}

async function handleRequest(req, res) {
  if (req.method === 'OPTIONS') {
    sendJson(res, 200, { success: true });
    return;
  }

  const url = new URL(req.url, 'http://127.0.0.1');

  if (req.method === 'GET' && url.pathname === '/health') {
    sendJson(res, 200, { success: true, status: 'ok' });
    return;
  }

  if (req.method === 'POST' && url.pathname === '/api/auth/register') {
    try {
      const body = await readBody(req);
      const name = String(body.name ?? body.nombre ?? '').trim();
      const email = normalizarCorreo(body.email ?? body.correo);
      const password = String(body.password ?? '').trim();

      if (!name || !email || !password) {
        sendJson(res, 400, { success: false, message: 'Faltan campos obligatorios' });
        return;
      }

      if (!email.includes('@')) {
        sendJson(res, 400, { success: false, message: 'Correo inválido' });
        return;
      }

      if (password.length < 6) {
        sendJson(res, 400, { success: false, message: 'La contraseña debe tener al menos 6 caracteres' });
        return;
      }

      if (users.has(email)) {
        sendJson(res, 409, { success: false, message: 'El usuario ya existe' });
        return;
      }

      const user = { id: Date.now().toString(36), name, email, password, rol: 'USUARIO' };
      users.set(email, user);

      sendJson(res, 201, {
        success: true,
        message: 'Usuario registrado correctamente',
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          nombre: user.name,
          correo: user.email,
          rol: user.rol,
        },
      });
      return;
    } catch (error) {
      sendJson(res, 400, { success: false, message: error.message || 'Error al registrar usuario' });
      return;
    }
  }

  if (req.method === 'POST' && url.pathname === '/api/auth/login') {
    try {
      const body = await readBody(req);
      const email = normalizarCorreo(body.email ?? body.correo);
      const password = String(body.password ?? '').trim();

      if (!email || !password) {
        sendJson(res, 400, { success: false, message: 'Faltan credenciales' });
        return;
      }

      const user = users.get(email);
      if (!user || user.password !== password) {
        sendJson(res, 401, { success: false, message: 'Correo o contraseña incorrectos' });
        return;
      }

      sendJson(res, 200, {
        success: true,
        message: 'Login correcto',
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          nombre: user.name,
          correo: user.email,
          rol: user.rol,
        },
      });
      return;
    } catch (error) {
      sendJson(res, 400, { success: false, message: error.message || 'Error al iniciar sesión' });
      return;
    }
  }

  if (req.method === 'POST' && url.pathname === '/api/auth/enviar-codigo') {
    try {
      const body = await readBody(req);
      const correo = normalizarCorreo(body.correo ?? body.email);
      const tipo = String(body.tipo ?? 'registro').trim().toLowerCase();

      if (!correo) {
        sendJson(res, 400, { success: false, message: 'El correo es obligatorio.' });
        return;
      }

      if (!correoValido(correo)) {
        sendJson(res, 400, { success: false, message: 'Ingresa un correo válido.' });
        return;
      }

      if (tipo === 'recuperacion' && !users.has(correo)) {
        sendJson(res, 404, {
          success: false,
          message: 'No existe una cuenta registrada con ese correo.',
        });
        return;
      }

      if (tipo !== 'recuperacion' && users.has(correo)) {
        sendJson(res, 409, {
          success: false,
          message: 'El correo ya está registrado. Inicia sesión o recupera tu contraseña.',
        });
        return;
      }

      const codigo = generarCodigo();
      const registro = {
        codigo,
        correo,
        tipo,
        expiraEn: Date.now() + CODIGO_VIGENCIA_MS,
        verificado: false,
      };
      codigos.set(correo, registro);

      let enviado = false;
      try {
        enviado = await enviarCorreo(correo, codigo);
      } catch (error) {
        enviado = false;
      }

      if (!enviado) {
        sendJson(res, 200, {
          success: true,
          message: 'No se pudo enviar el correo. Usa el código que aparece en pantalla.',
          codigo,
          correoEnviado: false,
        });
        return;
      }

      sendJson(res, 200, {
        success: true,
        message: 'Código enviado a tu correo.',
        correoEnviado: true,
      });
      return;
    } catch (error) {
      sendJson(res, 400, { success: false, message: error.message || 'Error al enviar el código' });
      return;
    }
  }

  if (req.method === 'POST' && url.pathname === '/api/auth/verificar-codigo') {
    try {
      const body = await readBody(req);
      const correo = normalizarCorreo(body.correo ?? body.email);
      const codigo = String(body.codigo ?? body.code ?? '').trim();
      const registro = codigos.get(correo);

      if (!registro || registro.codigo !== codigo) {
        sendJson(res, 400, { success: false, message: 'Código incorrecto.' });
        return;
      }

      if (registro.expiraEn < Date.now()) {
        codigos.delete(correo);
        sendJson(res, 400, { success: false, message: 'Código expirado. Solicita uno nuevo.' });
        return;
      }

      registro.verificado = true;
      sendJson(res, 200, { success: true, message: 'Código verificado.' });
      return;
    } catch (error) {
      sendJson(res, 400, { success: false, message: error.message || 'Error al verificar el código' });
      return;
    }
  }

  if (req.method === 'POST' && url.pathname === '/api/auth/cambiar-password') {
    try {
      const body = await readBody(req);
      const correo = normalizarCorreo(body.correo ?? body.email);
      const nuevaPassword = String(body.nuevaPassword ?? body.password ?? '').trim();
      const registro = codigos.get(correo);

      if (!registro || !registro.verificado || registro.expiraEn < Date.now()) {
        sendJson(res, 400, {
          success: false,
          message: 'Debes verificar el código antes de cambiar la contraseña.',
        });
        return;
      }

      if (nuevaPassword.length < 6) {
        sendJson(res, 400, {
          success: false,
          message: 'La contraseña debe tener al menos 6 caracteres.',
        });
        return;
      }

      const user = users.get(correo);
      if (!user) {
        sendJson(res, 404, { success: false, message: 'Usuario no encontrado.' });
        return;
      }

      user.password = nuevaPassword;
      codigos.delete(correo);
      sendJson(res, 200, { success: true, message: 'Contraseña actualizada.' });
      return;
    } catch (error) {
      sendJson(res, 400, { success: false, message: error.message || 'Error al cambiar la contraseña' });
      return;
    }
  }

  sendJson(res, 404, { success: false, message: 'Ruta no encontrada' });
}

function createServer() {
  return http.createServer(handleRequest);
}

async function startServer(port = 8080) {
  const server = createServer();
  await new Promise((resolve) => server.listen(port, '127.0.0.1', resolve));
  server.port = server.address().port;
  return server;
}

if (require.main === module) {
  startServer(8080)
    .then(() => {
      console.log('Backend ErgoVida escuchando en http://127.0.0.1:8080');
    })
    .catch((error) => {
      console.error('No se pudo iniciar el backend', error);
      process.exit(1);
    });
}

module.exports = {
  createServer,
  startServer,
  users,
  codigos,
};
