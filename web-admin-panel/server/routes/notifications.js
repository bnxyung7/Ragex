const express = require('express');
const db = require('../db');
const { verifyToken } = require('./auth');

const router = express.Router();

// Crear notificación
router.post('/create', verifyToken, (req, res) => {
  const { title, message, type, target_users } = req.body;

  if (!title || !message) {
    return res.status(400).json({
      success: false,
      message: 'title y message son obligatorios'
    });
  }

  try {
    const stmt = db.prepare(`
      INSERT INTO notifications (title, message, type, target_users, created_at)
      VALUES (?, ?, ?, ?, ?)
    `);

    const info = stmt.run(
      title,
      message,
      type || 'info',
      target_users || 'all',
      Date.now()
    );

    res.json({
      success: true,
      message: 'Notificación creada correctamente',
      notification: {
        id: info.lastInsertRowid,
        title,
        message,
        type: type || 'info',
        target_users: target_users || 'all'
      }
    });
  } catch (err) {
    console.error('Error al crear notificación:', err);
    res.status(500).json({ success: false, message: 'Error al crear notificación' });
  }
});

// Listar notificaciones
router.get('/list', verifyToken, (req, res) => {
  const notifications = db.prepare(`
    SELECT * FROM notifications
    ORDER BY created_at DESC
    LIMIT 100
  `).all();

  res.json({
    success: true,
    notifications
  });
});

// Obtener notificaciones activas (endpoint para la app iOS)
router.get('/active', (req, res) => {
  // Solo notificaciones de las últimas 7 días
  const sevenDaysAgo = Date.now() - (7 * 24 * 60 * 60 * 1000);

  const notifications = db.prepare(`
    SELECT id, title, message, type, target_users, created_at
    FROM notifications
    WHERE created_at > ?
    ORDER BY created_at DESC
  `).all(sevenDaysAgo);

  res.json({
    success: true,
    notifications
  });
});

// Eliminar notificación
router.delete('/:id', verifyToken, (req, res) => {
  const { id } = req.params;

  const notification = db.prepare('SELECT * FROM notifications WHERE id = ?').get(id);

  if (!notification) {
    return res.status(404).json({ success: false, message: 'Notificación no encontrada' });
  }

  db.prepare('DELETE FROM notifications WHERE id = ?').run(id);

  res.json({
    success: true,
    message: 'Notificación eliminada'
  });
});

module.exports = router;
