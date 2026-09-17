# 📱 Ragex Admin Panel

Panel administrativo web para gestionar IPAs, keys de usuario y notificaciones de la app Ragex.

## 🚀 Características

### 📦 Gestión de IPAs
- Subir nuevas versiones de Free Fire y Free Fire MAX
- Activar/desactivar versiones específicas
- Sistema de versionado (1.0.0, 1.0.1, etc.)
- Estadísticas de descargas
- Notas de versión

### 🔑 Gestión de Keys
- Generar keys únicas (formato: JUSTINRAGEX-XXX-YYY)
- Duraciones: permanente, 1/7/30/90/365 días
- Activar/desactivar keys
- Ver estado de expiración
- Notas por key

### 🔔 Sistema de Notificaciones
- Enviar notificaciones push a usuarios
- Tipos: info, success, warning, error
- Destinatarios: todos, activos, expirados
- Historial de notificaciones

## 📋 Requisitos

- Node.js 18+ 
- NPM o Yarn

## 🛠️ Instalación

1. **Instalar dependencias:**
```bash
cd web-admin-panel/server
npm install
```

2. **Configurar variables de entorno:**
```bash
cp .env.example .env
```

Edita `.env`:
```env
PORT=3000
JWT_SECRET=tu_secreto_super_seguro_cambialo_en_produccion
ADMIN_USERNAME=admin
ADMIN_PASSWORD=admin3105
```

3. **Iniciar servidor:**
```bash
npm start
# O en desarrollo con auto-reload:
npm run dev
```

4. **Abrir panel:**
Navega a `http://localhost:3000`

## 📊 Base de Datos

SQLite automático en `server/ragex.db`

Tablas:
- `ipa_versions` - Versiones de IPAs subidas
- `user_keys` - Keys de usuario
- `notifications` - Notificaciones

## 🔐 API Endpoints

### Auth
- `POST /api/auth/login` - Login admin

### IPAs
- `POST /api/ipa/upload` - Subir IPA (multipart/form-data)
- `GET /api/ipa/versions/:app_name` - Listar versiones
- `PATCH /api/ipa/versions/:id/toggle` - Activar/desactivar
- `DELETE /api/ipa/versions/:id` - Eliminar versión
- `GET /api/ipa/latest/:app_name` - Obtener última versión activa (público)
- `GET /api/ipa/download/:id` - Descargar IPA

### Keys
- `POST /api/keys/generate` - Generar key
- `GET /api/keys/list` - Listar todas las keys
- `PATCH /api/keys/:id/toggle` - Activar/desactivar
- `DELETE /api/keys/:id` - Eliminar key
- `POST /api/keys/validate` - Validar key (público, para app iOS)

### Notificaciones
- `POST /api/notifications/create` - Crear notificación
- `GET /api/notifications/list` - Listar todas
- `GET /api/notifications/active` - Obtener activas (público, últimos 7 días)
- `DELETE /api/notifications/:id` - Eliminar notificación

## 🔗 Integración con App iOS

### Validar Key
```swift
let url = URL(string: "https://tu-servidor.com/api/keys/validate")!
var request = URLRequest(url: url)
request.httpMethod = "POST"
request.setValue("application/json", forHTTPHeaderField: "Content-Type")

let body: [String: Any] = [
    "key_string": "JUSTINRAGEX-123-456",
    "device_id": UIDevice.current.identifierForVendor?.uuidString ?? ""
]

request.httpBody = try? JSONSerialization.data(withJSONObject: body)

URLSession.shared.dataTask(with: request) { data, response, error in
    // Procesar respuesta
}.resume()
```

### Obtener Última Versión IPA
```swift
let url = URL(string: "https://tu-servidor.com/api/ipa/latest/FreeFire")!

URLSession.shared.dataTask(with: url) { data, response, error in
    if let data = data,
       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
       let version = json["version"] as? [String: Any] {
        let versionString = version["version"] as? String
        let downloadURL = "https://tu-servidor.com/api/ipa/download/\(version["id"])"
    }
}.resume()
```

### Obtener Notificaciones
```swift
let url = URL(string: "https://tu-servidor.com/api/notifications/active")!

URLSession.shared.dataTask(with: url) { data, response, error in
    // Mostrar notificaciones al usuario
}.resume()
```

## 🌐 Despliegue

### Servidor VPS / Dedicado
```bash
# Instalar PM2
npm install -g pm2

# Iniciar servidor
cd web-admin-panel/server
pm2 start index.js --name ragex-admin

# Auto-start on boot
pm2 startup
pm2 save
```

### Nginx Reverse Proxy
```nginx
server {
    listen 80;
    server_name tu-dominio.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

## 📝 Credenciales por Defecto

**Usuario:** `admin`  
**Contraseña:** `admin3105`

⚠️ **CAMBIAR en producción editando `.env`**

## 🔒 Seguridad

- JWT tokens con expiración 24h
- Bcrypt para passwords (futuro)
- CORS configurado
- Archivos `.ipa` solo accesibles vía API
- Validación de extensiones de archivo

## 📦 Estructura de Archivos

```
web-admin-panel/
├── server/
│   ├── index.js              # Express server
│   ├── db.js                 # SQLite database setup
│   ├── routes/
│   │   ├── auth.js           # Autenticación
│   │   ├── ipa.js            # Gestión IPAs
│   │   ├── keys.js           # Gestión keys
│   │   └── notifications.js  # Notificaciones
│   ├── uploads/              # IPAs subidos
│   ├── ragex.db              # Base de datos (auto-generada)
│   ├── package.json
│   ├── .env                  # Config (no commitear)
│   └── .env.example
└── public/
    ├── index.html            # Panel admin UI
    ├── css/
    │   └── admin.css
    └── js/
        └── admin.js
```

## 🐛 Troubleshooting

**Error: Cannot find module 'better-sqlite3'**
```bash
npm install
```

**Puerto 3000 en uso:**
Edita `PORT` en `.env`

**Error de permisos en uploads/:**
```bash
chmod 755 server/uploads
```

## 📞 Soporte

Creado por Justin Carlos para Ragex  
Versión: 1.0.0
