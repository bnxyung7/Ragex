require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path');

// Inicializar DB
require('./db');

// Importar rutas
const { router: authRouter } = require('./routes/auth');
const ipaRouter = require('./routes/ipa');
const keysRouter = require('./routes/keys');
const notificationsRouter = require('./routes/notifications');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Servir archivos estáticos (panel admin)
app.use(express.static(path.join(__dirname, '../public')));

// Rutas API
app.use('/api/auth', authRouter);
app.use('/api/ipa', ipaRouter);
app.use('/api/keys', keysRouter);
app.use('/api/notifications', notificationsRouter);

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: Date.now() });
});

// Catch-all: servir index.html para SPA routing
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, '../public/index.html'));
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({
    success: false,
    message: err.message || 'Error interno del servidor'
  });
});

app.listen(PORT, () => {
  console.log(`🚀 Servidor corriendo en http://localhost:${PORT}`);
  console.log(`📊 Panel admin: http://localhost:${PORT}`);
  console.log(`🔐 Credenciales admin:`);
  console.log(`   Usuario: ${process.env.ADMIN_USERNAME}`);
  console.log(`   Password: ${process.env.ADMIN_PASSWORD}`);
});
