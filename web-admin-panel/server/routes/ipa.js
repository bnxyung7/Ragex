const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const db = require('../db');
const { verifyToken } = require('./auth');

const router = express.Router();

// Configurar multer para subir IPAs
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = path.join(__dirname, '../uploads');
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    // Formato: FreeFire-1.0.0-<timestamp>.ipa
    const ext = path.extname(file.originalname);
    const timestamp = Date.now();
    const appName = req.body.app_name || 'Unknown';
    const version = req.body.version || '0.0.0';
    cb(null, `${appName}-${version}-${timestamp}${ext}`);
  }
});

const upload = multer({
  storage,
  limits: { fileSize: 500 * 1024 * 1024 }, // Max 500MB
  fileFilter: (req, file, cb) => {
    if (path.extname(file.originalname).toLowerCase() !== '.ipa') {
      return cb(new Error('Solo se permiten archivos .ipa'));
    }
    cb(null, true);
  }
});

// Subir nueva versión IPA
router.post('/upload', verifyToken, upload.single('ipa'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ success: false, message: 'No se subió ningún archivo' });
  }

  const { app_name, version, notes } = req.body;

  if (!app_name || !version) {
    // Borrar archivo subido si faltan datos
    fs.unlinkSync(req.file.path);
    return res.status(400).json({
      success: false,
      message: 'app_name y version son obligatorios'
    });
  }

  try {
    const stmt = db.prepare(`
      INSERT INTO ipa_versions (app_name, version, file_name, file_size, upload_date, notes)
      VALUES (?, ?, ?, ?, ?, ?)
    `);

    const info = stmt.run(
      app_name,
      version,
      req.file.filename,
      req.file.size,
      Date.now(),
      notes || null
    );

    res.json({
      success: true,
      message: `IPA ${app_name} v${version} subido correctamente`,
      ipa: {
        id: info.lastInsertRowid,
        app_name,
        version,
        file_name: req.file.filename,
        file_size: req.file.size
      }
    });
  } catch (err) {
    // Si hay error (ej: version duplicada), borrar archivo
    fs.unlinkSync(req.file.path);

    if (err.message.includes('UNIQUE constraint failed')) {
      return res.status(409).json({
        success: false,
        message: `Ya existe una versión ${version} para ${app_name}`
      });
    }

    console.error('Error al guardar IPA:', err);
    res.status(500).json({ success: false, message: 'Error al guardar IPA' });
  }
});

// Listar todas las versiones de un app
router.get('/versions/:app_name', verifyToken, (req, res) => {
  const { app_name } = req.params;

  const stmt = db.prepare(`
    SELECT * FROM ipa_versions
    WHERE app_name = ?
    ORDER BY upload_date DESC
  `);

  const versions = stmt.all(app_name);

  res.json({
    success: true,
    app_name,
    versions
  });
});

// Activar/desactivar versión
router.patch('/versions/:id/toggle', verifyToken, (req, res) => {
  const { id } = req.params;

  const version = db.prepare('SELECT * FROM ipa_versions WHERE id = ?').get(id);

  if (!version) {
    return res.status(404).json({ success: false, message: 'Versión no encontrada' });
  }

  const newStatus = version.is_active === 1 ? 0 : 1;

  db.prepare('UPDATE ipa_versions SET is_active = ? WHERE id = ?').run(newStatus, id);

  res.json({
    success: true,
    message: `Versión ${version.version} ${newStatus === 1 ? 'activada' : 'desactivada'}`,
    is_active: newStatus
  });
});

// Eliminar versión
router.delete('/versions/:id', verifyToken, (req, res) => {
  const { id } = req.params;

  const version = db.prepare('SELECT * FROM ipa_versions WHERE id = ?').get(id);

  if (!version) {
    return res.status(404).json({ success: false, message: 'Versión no encontrada' });
  }

  // Borrar archivo físico
  const filePath = path.join(__dirname, '../uploads', version.file_name);
  if (fs.existsSync(filePath)) {
    fs.unlinkSync(filePath);
  }

  // Borrar registro
  db.prepare('DELETE FROM ipa_versions WHERE id = ?').run(id);

  res.json({
    success: true,
    message: `Versión ${version.version} eliminada`
  });
});

// Obtener versión activa más reciente (para la app iOS)
router.get('/latest/:app_name', (req, res) => {
  const { app_name } = req.params;

  const stmt = db.prepare(`
    SELECT * FROM ipa_versions
    WHERE app_name = ? AND is_active = 1
    ORDER BY upload_date DESC
    LIMIT 1
  `);

  const version = stmt.get(app_name);

  if (!version) {
    return res.status(404).json({
      success: false,
      message: `No hay versión activa para ${app_name}`
    });
  }

  res.json({
    success: true,
    version
  });
});

// Descargar IPA
router.get('/download/:id', (req, res) => {
  const { id } = req.params;

  const version = db.prepare('SELECT * FROM ipa_versions WHERE id = ?').get(id);

  if (!version) {
    return res.status(404).json({ success: false, message: 'Versión no encontrada' });
  }

  const filePath = path.join(__dirname, '../uploads', version.file_name);

  if (!fs.existsSync(filePath)) {
    return res.status(404).json({ success: false, message: 'Archivo no encontrado' });
  }

  // Incrementar contador de descargas
  db.prepare('UPDATE ipa_versions SET download_count = download_count + 1 WHERE id = ?').run(id);

  res.download(filePath, `${version.app_name}-${version.version}.ipa`);
});

module.exports = router;
