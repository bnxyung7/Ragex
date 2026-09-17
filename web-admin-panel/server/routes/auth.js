const express = require('express');
const jwt = require('jsonwebtoken');
const router = express.Router();

// Login admin
router.post('/login', (req, res) => {
  const { username, password } = req.body;

  // Credenciales desde .env
  if (
    username === process.env.ADMIN_USERNAME &&
    password === process.env.ADMIN_PASSWORD
  ) {
    const token = jwt.sign(
      { username, role: 'admin' },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    return res.json({
      success: true,
      token,
      expiresIn: 86400
    });
  }

  res.status(401).json({
    success: false,
    message: 'Credenciales inválidas'
  });
});

// Middleware para verificar token
function verifyToken(req, res, next) {
  const token = req.headers.authorization?.split(' ')[1]; // Bearer <token>

  if (!token) {
    return res.status(403).json({ success: false, message: 'Token requerido' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    return res.status(401).json({ success: false, message: 'Token inválido o expirado' });
  }
}

module.exports = { router, verifyToken };
