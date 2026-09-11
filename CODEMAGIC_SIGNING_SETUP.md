# 📱 Configurar IPA Firmada en Codemagic

## ✅ Lo que acabamos de hacer:

Agregamos un nuevo workflow: **`x-release-signed`**
- ✅ Firma la IPA automáticamente
- ✅ Lista para instalar directamente (sin ESign)
- ✅ Se puede compartir por link

---

## 🔧 Qué necesitas hacer TÚ en Codemagic:

### 1️⃣ Subir Certificado P12

1. Ve a: **Codemagic Dashboard** → Tu proyecto **X**
2. Click en **⚙️ Settings** (arriba derecha)
3. En el menú izquierdo: **Code signing identities**
4. Sección: **iOS certificates**
5. Click **Upload certificate**

**Sube:**
- 📄 Tu archivo `.p12`
- 🔑 La contraseña del P12

---

### 2️⃣ Subir Provisioning Profile

1. Misma pantalla (Code signing identities)
2. Sección: **iOS provisioning profiles**
3. Click **Upload profile**

**Sube:**
- 📄 Tu archivo `.mobileprovision`

**IMPORTANTE:** Asegúrate que el **Bundle ID** del provisioning profile coincida:
```
com.apple.mobile.MobileHouseArrest
```

---

### 3️⃣ Configurar Variables de Entorno (opcional)

Si necesitas configurar el Team ID:

1. Ve a: **Environment variables**
2. Agrega:
   - Variable: `TEAM_ID`
   - Valor: Tu Team ID de Apple (10 caracteres, ej: `A1B2C3D4E5`)

---

### 4️⃣ Ejecutar el Build

1. Ve a: **Builds** (menú izquierdo)
2. Click **Start new build**
3. Selecciona workflow: **`x-release-signed`**
4. Branch: `main`
5. Click **Start build**

---

## 📦 Resultado:

Cuando el build termine (~10-15 min):

1. **Download IPA:**
   - Ve a la página del build
   - Artifacts → Download `X-signed.ipa`

2. **Compartir por link:**
   - Codemagic genera un link automático
   - Copia el link del artifact
   - Compártelo con quien quieras

3. **Instalar:**
   - Abre el link en Safari (iPhone)
   - Click para instalar
   - ¡Listo! ✅

---

## 🔄 Workflows disponibles:

| Workflow | Descripción | Output |
|----------|-------------|--------|
| `x-dev` | Compilación rápida (sin IPA) | Ninguno |
| `x-simulator` | Para Xcode Simulator | X-Simulator.app.zip |
| `x-release` | IPA sin firmar (ESign) | X-unsigned.ipa |
| `x-release-signed` | 🆕 IPA firmada (lista) | X-signed.ipa ✅ |

---

## ⚠️ Troubleshooting:

### Error: "No matching provisioning profiles found"

**Solución:**
1. Verifica que el Bundle ID en `.mobileprovision` sea: `com.apple.mobile.MobileHouseArrest`
2. Verifica que el certificado P12 coincida con el provisioning profile
3. Si es **Development profile** → cambia en `codemagic.yaml`:
   ```yaml
   distribution_type: development  # en vez de adhoc
   ```

### Error: "Certificate not found"

**Solución:**
1. Asegúrate de subir el P12 en **Code signing identities**
2. Verifica que la contraseña del P12 sea correcta
3. El P12 debe contener **certificado + private key**

### Error: "Signing identity not found"

**Solución:**
1. Abre Keychain Access en tu Mac
2. Exporta de nuevo el certificado como P12
3. Al exportar: ✅ Incluir private key
4. Sube el nuevo P12 a Codemagic

### Build success pero IPA no instala

**Posibles causas:**
1. **UDID no registrado**: Si es Ad-Hoc profile, el UDID del iPhone debe estar en el provisioning profile
2. **Profile expirado**: Verifica fecha de expiración del `.mobileprovision`
3. **Bundle ID diferente**: Debe ser exactamente `com.apple.mobile.MobileHouseArrest`

---

## 📊 Verificar antes de compilar:

### ✅ Checklist:

- [ ] P12 subido a Codemagic
- [ ] Contraseña de P12 correcta
- [ ] `.mobileprovision` subido
- [ ] Bundle ID coincide: `com.apple.mobile.MobileHouseArrest`
- [ ] Si es Ad-Hoc → UDIDs registrados en provisioning profile
- [ ] Workflow `x-release-signed` agregado en `codemagic.yaml`
- [ ] Código pusheado a GitHub/repo conectado

---

## 🚀 Automatización:

Para que compile automáticamente en cada push a `main`:

El workflow ya está configurado con:
```yaml
triggering:
  events:
    - push
  branch_patterns:
    - pattern: "main"
      include: true
```

Cada vez que hagas `git push origin main` → Build automático ✅

---

## 📧 Notificaciones por Email:

Cambia en `codemagic.yaml`:
```yaml
publishing:
  email:
    recipients:
      - tu_email@gmail.com  # 👈 Cambia esto
```

Recibirás email cuando:
- ✅ Build exitoso (con link de descarga)
- ❌ Build falló (con logs)

---

## 🎯 Próximos pasos:

1. **Ahora mismo:**
   - Sube P12 y mobileprovision a Codemagic
   - Ejecuta build de `x-release-signed`
   - Descarga y prueba la IPA

2. **Después:**
   - Si funciona → Commit este `codemagic.yaml` a GitHub
   - Builds automáticos en cada push

3. **Compartir:**
   - Link de Codemagic artifacts → Funciona 30 días
   - O sube la IPA a: Dropbox, Google Drive, WeTransfer, etc.

---

## 📞 ¿Dudas?

Si algo falla:
1. Revisa los **logs del build** en Codemagic
2. Busca errores de signing: `No matching provisioning`, `Code signing failed`
3. Verifica Bundle ID en ambos lados

**Archivos necesarios:**
- ✅ `.p12` (certificado + private key)
- ✅ `.mobileprovision` (con Bundle ID correcto)
- ✅ Contraseña del P12

---

## 🎉 ¡Listo!

Ahora puedes:
- ✅ Generar IPAs firmadas automáticamente
- ✅ Compartir por link de Codemagic
- ✅ Instalar directamente (sin ESign)

**Build command:**
```bash
# Si estás en local y quieres probar primero
git add codemagic.yaml CODEMAGIC_SIGNING_SETUP.md
git commit -m "feat: add signed IPA workflow for Codemagic"
git push origin main
```

Codemagic detectará el cambio y compilará automáticamente. 🚀
