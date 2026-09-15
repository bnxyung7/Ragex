# Sistema de Control de Versión de Keys

## 📱 ¿Cómo Funciona?

Este sistema permite que cuando lances una **nueva versión del IPA** (por ejemplo, versión 2.0), las keys de la **versión anterior** (versión 1.0) dejen de funcionar automáticamente y se le muestre al usuario una alerta para que actualice.

## 🔧 Implementación

### 1. En el Código (Ya implementado ✅)

El código ahora verifica automáticamente si la key del usuario requiere una versión más nueva de la app:

- **Al activar una key**: Verifica si la key requiere una versión mínima
- **Al sincronizar con el servidor**: Verifica periódicamente si hay actualizaciones requeridas
- **Cierra la sesión automáticamente**: Si la key requiere actualización, cierra la sesión y muestra una alerta

### 2. En el API (Servidor)

Cuando crees una nueva key para la versión 2.0, el API debe devolver estos campos adicionales:

```json
{
  "valid": true,
  "key": {
    "keyString": "JUSTINRAGEX-123-456",
    "duration": "30D",
    ...
  },
  "minAppVersion": "2.0.0",
  "updateRequired": true
}
```

### 3. Ejemplo de Uso

#### Versión Actual de la App: 2.0.0-Beta
(Definida en `Info.plist` → `CFBundleShortVersionString`)

#### Cuando lances Versión 3.0:

1. **En el servidor/API**, configura las keys nuevas con:
   - `minAppVersion: "3.0.0"`
   - `updateRequired: true`

2. **Los usuarios con versión 2.0** verán:
   ```
   ⚠️ ACTUALIZACIÓN REQUERIDA
   
   Esta Key requiere la versión 3.0.0 o superior de la app.
   
   Tu sesión ha sido cerrada.
   
   Descarga la última versión para continuar usando esta Key.
   ```

3. **La sesión se cerrará automáticamente**

## 📋 Flujo de Usuario

### Usuario con Versión 1.0 intenta usar Key de Versión 2.0:

1. Usuario abre la app (versión 1.0)
2. Intenta activar una key nueva
3. La app verifica con el servidor
4. El servidor responde: `"minAppVersion": "2.0.0", "updateRequired": true`
5. La app muestra alerta de actualización
6. La sesión se cierra automáticamente
7. El usuario debe descargar la versión 2.0

### Usuario con Versión 1.0 tiene key activa de Versión 1.0:

Cuando lances la versión 2.0 y actualices las keys en el servidor:

1. Usuario abre la app (versión 1.0)
2. La app sincroniza con el servidor automáticamente
3. El servidor detecta que la key requiere versión 2.0
4. La app recibe: `"minAppVersion": "2.0.0", "updateRequired": true`
5. La app muestra la alerta
6. **La sesión se cierra inmediatamente**
7. El usuario debe actualizar

## 🔑 API Endpoints

### Para el Admin Panel (Crear Keys con versión mínima)

Endpoint: `POST /api/keys/create`

```json
{
  "keyString": "JUSTINRAGEX-123-456",
  "duration": "30D",
  "userName": "Usuario",
  "minAppVersion": "2.0.0"  // ← Campo nuevo
}
```

### Validar Key (Ya implementado)

Endpoint: `POST /api/keys/{keyString}/validate`

Respuesta incluye:
```json
{
  "valid": true,
  "minAppVersion": "2.0.0",
  "updateRequired": true
}
```

## 📝 Configuración del Servidor

En tu API (`XkeyAPI-main`), necesitas agregar el campo `minAppVersion` a la base de datos de keys:

### Base de datos (agregar columna):
```python
# En database.py o models
minAppVersion = Column(String, default="1.0.0")
```

### Al crear keys (agregar lógica):
```python
# En app.py - endpoint /keys/create
def create_key():
    min_version = request.json.get('minAppVersion', '2.0.0')  # Versión actual por defecto
    # ... crear key con min_version
```

### Al validar keys (agregar lógica):
```python
# En app.py - endpoint /keys/{keyString}/validate
def validate_key(keyString):
    # ... validación existente
    
    # Agregar verificación de versión
    app_version = "2.0.0"  # Versión actual de la app
    key_min_version = key.minAppVersion
    
    if compare_versions(app_version, key_min_version) < 0:
        return {
            "valid": False,
            "updateRequired": True,
            "minAppVersion": key_min_version,
            "reason": "App update required"
        }
```

## 🚀 Flujo Completo de Lanzamiento

### Cuando lances una Nueva Versión:

1. **Actualiza `Info.plist`**:
   ```xml
   <key>CFBundleShortVersionString</key>
   <string>3.0.0</string>
   ```

2. **Actualiza el servidor** para que las nuevas keys tengan:
   - `minAppVersion: "3.0.0"`

3. **(Opcional) Actualiza keys antiguas** para forzar actualización:
   - Edita keys existentes en el servidor
   - Establece `minAppVersion: "3.0.0"` en todas las keys activas

4. **Usuarios con versión antigua**:
   - No podrán usar sus keys
   - Verán la alerta de actualización
   - Deberán descargar la nueva versión

## ⚙️ Archivos Modificados

- ✅ `KeyAPIService.swift` - Agregado campos `minAppVersion` y `updateRequired`
- ✅ `KeyStore.swift` - Agregada verificación de versión y cierre de sesión
- ✅ `KeyModels.swift` - Agregado error `updateRequired`

## 📱 Versión Actual

**Versión de la App**: `2.0.0-Beta` (en `Info.plist`)

Cuando quieras forzar actualización, cambia esta versión a `3.0.0` y actualiza las keys en el servidor con `minAppVersion: "3.0.0"`.
