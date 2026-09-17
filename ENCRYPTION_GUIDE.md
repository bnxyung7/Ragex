# 🔐 Guía de Encriptación de Patches

Este sistema protege tus archivos `.3105` para que no puedan ser robados si alguien extrae el IPA.

## 🎯 ¿Cómo funciona?

1. **Archivos encriptados en IPA**: Los `.3105` se convierten a `.3105e` (encriptados con AES-256-GCM)
2. **Key derivada de usuario**: Cada usuario desencripta con su API key única
3. **Desencriptación en memoria**: Los archivos NUNCA se guardan desencriptados en el dispositivo
4. **Sin key = Sin acceso**: Extraer el IPA solo da archivos encriptados inútiles

---

## 📋 Requisitos

- Python 3.7 o superior
- pip (gestor de paquetes Python)

---

## 🚀 Instalación

### 1. Instalar dependencias Python:

```bash
cd C:\Users\J\Desktop\PROYECTO\Ragex-main
pip install -r requirements.txt
```

---

## 🔒 Uso del Script de Encriptación

### Opción 1: Encriptar SIN eliminar originales (recomendado para pruebas)

```bash
python encrypt_patches.py
```

Esto creará archivos `.3105e` al lado de los `.3105` originales.

### Opción 2: Encriptar Y eliminar originales (para producción)

```bash
python encrypt_patches.py --delete
```

Esto creará `.3105e` y **ELIMINARÁ** los `.3105` originales.

⚠️ **ADVERTENCIA**: Haz backup antes de usar `--delete`

---

## 📁 Estructura después de encriptar:

```
PreinstalledPatches/
├── FREE_FIRE/
│   ├── AIMBOT/
│   │   ├── Aim Neck.3105e          ✅ Encriptado
│   │   ├── Aim Head.3105e          ✅ Encriptado
│   │   └── ...
│   ├── HOLOGRAMA/
│   │   └── ...
│   ├── MOD_SKIN/
│   │   └── ...
│   └── COMBO/
│       └── ...
└── FREE_FIRE_MAX/
    └── ... (igual que FREE_FIRE)
```

---

## 🔑 ¿Cómo funciona la Key?

### En el script Python (build time):
```python
MASTER_KEY = "RagexMasterEncryption2024"
SALT = "RagexV2Secure2024"
```

### En el IPA (runtime):
```swift
// Key derivada del API key del usuario
let userKey = KeyStore.shared.activeSession?.key.licenseKey
let derivedKey = deriveKey(from: userKey + salt)
```

**Resultado**: Cada usuario solo puede desencriptar si tiene key válida.

---

## ✅ Verificar que funciona:

### 1. Encriptar archivos:
```bash
python encrypt_patches.py
```

### 2. Compilar IPA con archivos `.3105e`

### 3. Probar en dispositivo:
- Usuario con key válida → Patches funcionan ✅
- Usuario sin key → No puede desencriptar ❌

---

## 🛡️ Seguridad

### ✅ Protecciones implementadas:
- **AES-256-GCM**: Encriptación militar grade
- **Nonce único**: Cada archivo tiene nonce aleatorio
- **Key derivation**: SHA256(userKey + salt)
- **No extracción**: Archivos inútiles sin la app

### ❌ NO protege contra:
- Usuario con key válida que guarda los patches después de desencriptar
- Reverse engineering extremo del IPA (aunque dificulta mucho)

---

## 🔧 Troubleshooting

### Error: "ModuleNotFoundError: No module named 'cryptography'"
```bash
pip install cryptography
```

### Error: "No se encuentra la carpeta PreinstalledPatches"
Asegúrate de ejecutar el script desde la raíz del proyecto:
```bash
cd C:\Users\J\Desktop\PROYECTO\Ragex-main
python encrypt_patches.py
```

### Los patches no se desencriptan en el IPA
1. Verifica que `FileEncryptionService.swift` está compilado
2. Verifica que el salt es idéntico en Python y Swift
3. Revisa los logs de Xcode para errores de desencriptación

---

## 📝 Notas importantes

1. **Backup obligatorio**: Haz backup de los `.3105` originales antes de usar `--delete`
2. **Git ignore**: Los `.3105e` se deben incluir en el repo, los `.3105` NO
3. **Build time**: Encripta ANTES de compilar el IPA
4. **Testing**: Prueba con un archivo primero antes de encriptar todo

---

## 🎯 Workflow recomendado:

```bash
# 1. Agregar nuevos patches
cp "nuevo_patch.3105" ThreeOneOSFive/PreinstalledPatches/FREE_FIRE/AIMBOT/

# 2. Encriptar
python encrypt_patches.py

# 3. Eliminar originales (opcional)
rm ThreeOneOSFive/PreinstalledPatches/**/*.3105

# 4. Commit
git add ThreeOneOSFive/PreinstalledPatches/**/*.3105e
git commit -m "feat: agregar nuevo patch encriptado"

# 5. Build IPA
# (CodeMagic o Xcode)
```

---

## 📞 Soporte

Si tienes problemas con la encriptación, revisa:
1. Logs de Python al ejecutar el script
2. Logs de Xcode al compilar
3. Logs de console en el dispositivo

---

**¡Tus patches ahora están protegidos! 🔒**
