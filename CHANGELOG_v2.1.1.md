# 🚀 CHANGELOG v2.1.1 - Lanzamiento Oficial

**Fecha**: 17 de Septiembre, 2026  
**Versión**: 2.1.1  
**Build**: Producción

---

## 🎯 Resumen Ejecutivo

Esta versión introduce un **sistema completo de seguridad con encriptación AES-256** para proteger tus patches contra robo, además de nuevas categorías de productos, etiquetas en tiempo real, y mejoras importantes en la interfaz.

---

## 🔐 NUEVA CARACTERÍSTICA: Sistema de Encriptación

### ¿Qué protege?
- **Archivos .3105 encriptados**: Ahora los patches están protegidos con AES-256-GCM
- **Imposible extraer del IPA**: Si alguien descomprime el IPA, solo encuentra archivos .3105e encriptados inútiles
- **Key por usuario**: Cada usuario desencripta con su API key única
- **Desencriptación en memoria**: Los archivos nunca se guardan desencriptados en el dispositivo

### Cómo funciona:
1. **Build time**: Script Python encripta .3105 → .3105e con AES-256
2. **Runtime**: IPA detecta .3105e, desencripta con key del usuario, aplica patch
3. **Sin key válida**: No se puede desencriptar = No se puede usar

### Archivos nuevos:
- `ThreeOneOSFive/helpers/FileEncryptionService.swift` - Servicio de encriptación iOS
- `encrypt_patches.py` - Script para encriptar patches
- `requirements.txt` - Dependencias Python (cryptography)
- `ENCRYPTION_GUIDE.md` - Guía completa de uso

**Uso del script:**
```bash
# Instalar dependencias
pip install -r requirements.txt

# Encriptar todos los patches
python encrypt_patches.py

# Encriptar y eliminar originales (producción)
python encrypt_patches.py --delete
```

---

## 🏷️ NUEVA CARACTERÍSTICA: Etiquetas de Productos en Tiempo Real

### ¿Qué son?
Sistema para marcar productos como **Test**, **Safe** o **Banned** desde el panel admin web, visible en tiempo real en el IPA.

### Características:
- **Control desde web**: Cambia etiquetas sin rebuild
- **Caché inteligente**: 5 minutos de caché para reducir llamadas API
- **3 estados**: 🧪 Test, ✅ Safe, 🚫 Banned
- **Visualización**: Badge colorido debajo del nombre del producto

### Backend endpoints:
- `GET /api/products/tags` - Obtener todas las etiquetas (público)
- `GET /api/products/tags/<id>` - Obtener etiqueta específica
- `POST /api/admin/products/tags/create` - Crear etiqueta (admin)
- `PUT /api/admin/products/tags/<id>` - Actualizar etiqueta (admin)
- `DELETE /api/admin/products/tags/<id>` - Eliminar etiqueta (admin)
- `POST /api/admin/products/tags/bulk-update` - Actualización masiva (admin)

### Panel Admin:
- Nueva pestaña "Etiquetas de Productos"
- Filtros por estado (Test/Safe/Banned)
- Modal crear/editar con formulario completo
- Botones quick-change para cambiar tag en 1 click
- Tabla con búsqueda y filtrado

### IPA:
- Nuevo modelo `ProductTag` en KeyModels.swift
- Servicio `ProductTagService` con caché automático
- Badges visuales en FreeFireView con emoji + nombre

---

## 📂 NUEVAS CATEGORÍAS DE PRODUCTOS

### Antes (v2.1.0):
1. AIMBOT
2. HOLOGRAMA
3. OTROS

### Ahora (v2.1.1):
1. 🎯 **AIMBOT** (scope icon)
2. 🧊 **HOLOGRAMA** (cube.transparent icon)
3. 🎨 **MOD SKIN** (paintbrush.fill icon) ← NUEVO
4. ⭐ **COMBO** (star.fill icon) ← NUEVO
5. ⚙️ **OTROS** (ellipsis.circle icon)

### Carpetas creadas:
```
PreinstalledPatches/
├── FREE_FIRE/
│   ├── AIMBOT/
│   ├── HOLOGRAMA/
│   │   ├── Arma/
│   │   └── Personaje/
│   ├── MOD_SKIN/          ← NUEVO (para texturas)
│   ├── COMBO/             ← NUEVO (para combos)
│   └── OTROS/
└── FREE_FIRE_MAX/
    ├── AIMBOT/
    ├── HOLOGRAMA/
    ├── MOD_SKIN/          ← NUEVO
    ├── COMBO/             ← NUEVO
    └── OTROS/
```

---

## 🆕 NUEVOS PRODUCTOS AGREGADOS

### AIMBOT (4 productos):
- ✅ AIM NECK
- ✅ AIM HEAD
- ✅ AIM BUDY 70%
- ✅ AIM BUDY 90%

### COMBO (4 productos FREE_FIRE + 4 FREE_FIRE_MAX):
- ✅ AIM BUDY + ANTENA
- ✅ AIM DRAG + ANTENA
- ✅ AIM HEAD + ANTENA
- ✅ AIM NECK + ANTENA

### HOLOGRAMA (4 productos nuevos):
- ✅ HOLOGRAMA ARMAS AZUL + BLANCO (Free Fire)
- ✅ HOLOGRAMA PERSONAJE (Free Fire)
- ✅ HOLO ARMAS (Free Fire MAX)
- ✅ HOLOGRAMA ARMA VERDE + NEGRO (Free Fire)
- ✅ HOLOGRAMA PERSONAJE VERDE - NEGRO (Free Fire)

---

## 🔧 MEJORAS Y FIXES

### UI/UX:
- ✅ **Nombres en MAYÚSCULA**: Todos los nombres de productos ahora se muestran en mayúscula para mejor visibilidad
- ✅ **Tabs optimizados**: Solo se muestran Home, Free Fire, Free Fire MAX, Perfil, Support
- ✅ **Tabs privados ocultos**: Files, Patches, Bundle Explorer ya no se muestran (developer-only)

### Bugs Corregidos:
- 🐛 **Fix categorización COMBO**: Prioridad de carpeta sobre nombre de archivo (evita que archivos con "AIM" en COMBO se categoricen como AIMBOT)
- 🐛 **Fix Free Fire MAX visible**: Tab de Free Fire MAX restaurado
- 🐛 **Fix displayName**: Maneja correctamente extensión .3105e doble
- 🐛 **Fix productId**: Genera IDs consistentes para archivos encriptados

### Lógica de Categorización Mejorada:
```swift
// Prioridad 1: Carpeta exacta (más confiable)
if folderName == "AIMBOT" { return .aimbot }
else if folderName == "COMBO" { return .combo }

// Prioridad 2: Nombre de archivo (fallback)
if filename.contains("AIMBOT") { return .aimbot }
```

### Debug Tools:
- ✅ Print de productId en consola para verificar tags
- ✅ Logs de encriptación/desencriptación
- ✅ Cache timestamps en ProductTagService

---

## 🏗️ ARQUITECTURA TÉCNICA

### Encriptación:
- **Algoritmo**: AES-256-GCM
- **Key derivation**: SHA256(userKey + salt)
- **Nonce**: 12 bytes aleatorios por archivo
- **Formato**: nonce(12) + ciphertext + tag (formato SealedBox.combined)

### Backend:
- **Database**: Nueva tabla `product_tags` con SQLAlchemy
- **API**: 9 endpoints (2 públicos, 7 admin)
- **Validación**: JSON schema validation en todos los endpoints

### iOS:
- **Framework**: CryptoKit (nativo Apple)
- **Cache**: UserDefaults con timestamp (5 min TTL)
- **Async**: Task.detached para desencriptación sin bloquear UI
- **Error handling**: Try-catch con mensajes descriptivos

---

## 📊 ESTADÍSTICAS DE CAMBIOS

### Código:
- **Archivos modificados**: 8
- **Archivos nuevos**: 7
- **Líneas de código agregadas**: ~1,200
- **Commits**: 12
- **Pushes**: 12

### Productos:
- **Total patches**: 20+
- **Nuevas categorías**: 2 (MOD SKIN, COMBO)
- **Carpetas nuevas**: 4 (2 por juego)

---

## 🚀 PRÓXIMOS PASOS (Post-Lanzamiento)

### Inmediato:
1. ✅ **Compilar IPA v2.1.1** en CodeMagic
2. ✅ **Subir a distribución** (TestFlight/TrollStore)
3. ✅ **Crear tags de productos** en panel admin
4. ✅ **Probar encriptación** con usuarios beta

### Corto Plazo:
- 🔄 **Encriptar patches legacy**: Ejecutar `encrypt_patches.py --delete`
- 🔄 **Monitorear logs**: Verificar desencriptación funciona
- 🔄 **Feedback usuarios**: Ajustar tags según uso real

### Mediano Plazo:
- 📥 **Sistema de descarga**: Patches premium descargables desde servidor
- 🛡️ **Anti-extraction**: Detector de manipulación del IPA
- 📊 **Analytics**: Trackear qué patches se usan más

---

## 📝 NOTAS DE MIGRACIÓN

### Para Desarrolladores:
1. Instalar Python dependencies: `pip install -r requirements.txt`
2. Encriptar patches: `python encrypt_patches.py`
3. Compilar IPA normalmente (Xcode reconoce .3105e)
4. Probar en dispositivo con key válida

### Para Usuarios:
- **Sin cambios**: Todo funciona igual
- **Requisito**: Key válida para desencriptar patches
- **Beneficio**: Patches protegidos contra robo

---

## 🎉 CRÉDITOS

**Desarrollado por**: Equipo Ragex  
**Versión**: 2.1.1  
**Fecha de lanzamiento**: Septiembre 17, 2026  
**Build target**: iOS 15.0+  
**Compatibilidad**: iPhone, iPad

---

## 📞 SOPORTE

- **Panel Admin**: https://ragex.deno.dev/admin
- **GitHub**: https://github.com/bnxyung7/Ragex
- **Backend**: https://github.com/bnxyung7/XkeyAPI

---

**¡Gracias por usar Ragex v2.1.1! 🚀🔐**
