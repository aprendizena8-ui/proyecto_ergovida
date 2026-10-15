const test = require('node:test');
const assert = require('node:assert/strict');

const { startServer } = require('../server.js');

async function requestJson(server, method, path, body) {
  const base = `http://127.0.0.1:${server.port}`;
  const response = await fetch(`${base}${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
    },
    body: body ? JSON.stringify(body) : undefined,
  });

  const text = await response.text();
  return {
    status: response.status,
    body: text ? JSON.parse(text) : null,
  };
}

test('POST /api/auth/register registra un usuario', async () => {
  const server = await startServer(0);

  try {
    const result = await requestJson(server, 'POST', '/api/auth/register', {
      name: 'Ana',
      email: 'ana@ergovida.test',
      password: '123456',
    });

    assert.equal(result.status, 201);
    assert.equal(result.body.success, true);
    assert.equal(result.body.user.email, 'ana@ergovida.test');
  } finally {
    await server.close();
  }
});

test('POST /api/auth/login valida credenciales', async () => {
  const server = await startServer(0);

  try {
    await requestJson(server, 'POST', '/api/auth/register', {
      name: 'Luis',
      email: 'luis@ergovida.test',
      password: 'abcdef',
    });

    const valid = await requestJson(server, 'POST', '/api/auth/login', {
      email: 'luis@ergovida.test',
      password: 'abcdef',
    });

    assert.equal(valid.status, 200);
    assert.equal(valid.body.success, true);
    assert.equal(valid.body.user.email, 'luis@ergovida.test');

    const invalid = await requestJson(server, 'POST', '/api/auth/login', {
      email: 'luis@ergovida.test',
      password: 'wrong',
    });

    assert.equal(invalid.status, 401);
    assert.equal(invalid.body.success, false);
  } finally {
    await server.close();
  }
});
