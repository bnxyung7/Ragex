const express = require('express');
const db = require('../db');
const { verifyToken } = require('./auth');

const router = express.Router();

// Generar nueva key
router.post('/generate', verifyToken, (req, res) => {
  const { user_name, duration, notes } = req.body;

  if (!user_name || !duration) {
    return res.status(400).json({
      success: false,
      message: 'user_name y duration son obligatorios'
    });
  }

  // Generar key única formato: JUSTINRAGEX-XXX-YYY
  const keyString = generateUniqueKey();
  const createdAt = Date.now();

  try {
    const stmt = db.prepare(`
      INSERT INTO user_keys (key_string, user_name, duration, created_at, notes)
      VALUES (?, ?, ?, ?, ?)
    `);

    const info = stmt.run(keyString, user_name, duration, createdAt, notes || null);

    res.json({
      success: true,
      message: 'Key generada correctamente',
      key: {
        id: info.lastInsertRowid,
        key_string: keyString,
        user_name,
        duration,
        created_at: createdAt
      }
    });
  } catch (err) {
    console.error('Error al generar key:', err);
    res.status(500).json({ success: false, message: 'Error al generar key' });
  }
});

// Listar todas las keys
router.get('/list', verifyToken, (req, res) => {
  const keys = db.prepare(`
    SELECT * FROM user_keys
    ORDER BY created_at DESC
  `).all();

  res.json({
    success: true,
    keys
  });
});

// Activar/desactivar key
router.patch('/:id/toggle', verifyToken, (req, res) => {
  const { id } = req.params;

  const key = db.prepare('SELECT * FROM user_keys WHERE id = ?').get(id);

  if (!key) {
    return res.status(404).json({ success: false, message: 'Key no encontrada' });
  }

  const newStatus = key.is_active === 1 ? 0 : 1;

  db.prepare('UPDATE user_keys SET is_active = ? WHERE id = ?').run(newStatus, id);

  res.json({
    success: true,
    message: `Key ${key.key_string} ${newStatus === 1 ? 'activada' : 'desactivada'}`,
    is_active: newStatus
  });
});

// Eliminar key
router.delete('/:id', verifyToken, (req, res) => {
  const { id } = req.params;

  const key = db.prepare('SELECT * FROM user_keys WHERE id = ?').get(id);

  if (!key) {
    return res.status(404).json({ success: false, message: 'Key no encontrada' });
  }

  db.prepare('DELETE FROM user_keys WHERE id = ?').run(id);

  res.json({
    success: true,
    message: `Key ${key.key_string} eliminada`
  });
});

// Validar key (endpoint para la app iOS)
router.post('/validate', (req, res) => {
  const { key_string, device_id } = req.body;

  if (!key_string) {
    return res.status(400).json({ success: false, message: 'key_string es obligatorio' });
  }

  const key = db.prepare('SELECT * FROM user_keys WHERE key_string = ?').get(key_string);

  if (!key) {
    return res.status(404).json({ success: false, message: 'Key no encontrada' });
  }

  if (key.is_active === 0) {
    return res.status(403).json({ success: false, message: 'Key desactivada' });
  }

  // Si es primera activación, registrar device_id y calcular expires_at
  if (!key.activated_at) {
    const activatedAt = Date.now();
    let expiresAt = null;

    if (key.duration !== 'permanent') {
      const days = parseDuration(key.duration);
      expiresAt = activatedAt + (days * 24 * 60 * 60 * 1000);
    }

    db.prepare(`
      UPDATE user_keys
      SET activated_at = ?, expires_at = ?, device_id = ?
      WHERE id = ?
    `).run(activatedAt, expiresAt, device_id || null, key.id);

    return res.json({
      success: true,
      message: 'Key activada correctamente',
      key: {
        key_string: key.key_string,
        user_name: key.user_name,
        duration: key.duration,
        activated_at: activatedAt,
        expires_at: expiresAt
      }
    });
  }

  // Verificar expiración
  if (key.expires_at && Date.now() > key.expires_at) {
    return res.status(403).json({
      success: false,
      message: 'Key expirada',
      expired: true,
      expires_at: key.expires_at
    });
  }

  // Key válida
  res.json({
    success: true,
    message: 'Key válida',
    key: {
      key_string: key.key_string,
      user_name: key.user_name,
      duration: key.duration,
      activated_at: key.activated_at,
      expires_at: key.expires_at,
      remaining_days: key.expires_at ? Math.ceil((key.expires_at - Date.now()) / (24 * 60 * 60 * 1000)) : null
    }
  });
});

// Helper: generar key única
function generateUniqueKey() {
  let keyString;
  let attempts = 0;

  do {
    const segment1 = Math.floor(Math.random() * 1000).toString().padStart(3, '0');
    const segment2 = Math.floor(Math.random() * 1000).toString().padStart(3, '0');
    keyString = `JUSTINRAGEX-${segment1}-${segment2}`;

    const existing = db.prepare('SELECT id FROM user_keys WHERE key_string = ?').get(keyString);

    if (!existing) break;

    attempts++;
    if (attempts > 100) {
      throw new Error('No se pudo generar una key única después de 100 intentos');
    }
  } while (true);

  return keyString;
}

// Helper: parsear duración
function parseDuration(duration) {
  const match = duration.match(/^(\d+)(day|days)$/);
  if (!match) return 0;
  return parseInt(match[1]);
}

module.exports = router;
