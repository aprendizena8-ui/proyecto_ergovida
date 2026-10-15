const http = require('http');
const { URL } = require('url');

const users = new Map();

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
      const name = String(body.name ?? '').trim();
      const email = String(body.email ?? '').trim().toLowerCase();
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

      const user = { id: Date.now().toString(36), name, email, password };
      users.set(email, user);

      sendJson(res, 201, {
        success: true,
        message: 'Usuario registrado correctamente',
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
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
      const email = String(body.email ?? '').trim().toLowerCase();
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
        },
      });
      return;
    } catch (error) {
      sendJson(res, 400, { success: false, message: error.message || 'Error al iniciar sesión' });
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
};
