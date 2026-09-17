const Database = require('better-sqlite3');
const path = require('path');

const db = new Database(path.join(__dirname, 'ragex.db'), { verbose: console.log });

// Inicializar tablas
db.exec(`
  -- Tabla de versiones IPA
  CREATE TABLE IF NOT EXISTS ipa_versions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    app_name TEXT NOT NULL, -- 'FreeFire' o 'FreeFireMax'
    version TEXT NOT NULL, -- '1.0.0', '1.0.1', etc.
    file_name TEXT NOT NULL, -- 'FreeFire-1.0.0.ipa'
    file_size INTEGER NOT NULL, -- bytes
    upload_date INTEGER NOT NULL, -- timestamp
    is_active INTEGER DEFAULT 1, -- 1 = activa, 0 = desactivada
    download_count INTEGER DEFAULT 0,
    notes TEXT, -- notas de version
    UNIQUE(app_name, version)
  );

  -- Tabla de keys
  CREATE TABLE IF NOT EXISTS user_keys (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    key_string TEXT NOT NULL UNIQUE,
    user_name TEXT NOT NULL,
    duration TEXT NOT NULL, -- 'permanent', '1day', '7days', '30days', '90days', '365days'
    created_at INTEGER NOT NULL,
    activated_at INTEGER,
    expires_at INTEGER,
    is_active INTEGER DEFAULT 1,
    device_id TEXT,
    notes TEXT
  );

  -- Tabla de notificaciones
  CREATE TABLE IF NOT EXISTS notifications (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT DEFAULT 'info', -- 'info', 'warning', 'success', 'error'
    target_users TEXT DEFAULT 'all', -- 'all', 'active', 'expired', 'specific_key'
    created_at INTEGER NOT NULL,
    sent_count INTEGER DEFAULT 0
  );

  -- Índices
  CREATE INDEX IF NOT EXISTS idx_ipa_app_name ON ipa_versions(app_name);
  CREATE INDEX IF NOT EXISTS idx_ipa_active ON ipa_versions(is_active);
  CREATE INDEX IF NOT EXISTS idx_keys_active ON user_keys(is_active);
  CREATE INDEX IF NOT EXISTS idx_keys_string ON user_keys(key_string);
`);

console.log('✅ Base de datos inicializada');

module.exports = db;
