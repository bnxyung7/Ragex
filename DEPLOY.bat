@echo off
chcp 65001 >nul
echo ============================================================
echo 🚀 RAGEX v2.1.1 - DEPLOYMENT SCRIPT
echo ============================================================
echo.

:MENU
echo Selecciona una opción:
echo.
echo 1. Ver status de Git
echo 2. Build SIN encriptación (rápido)
echo 3. Build CON encriptación (seguro)
echo 4. Crear etiquetas en admin (abre navegador)
echo 5. Ver últimos commits
echo 6. Salir
echo.
set /p choice="Opción (1-6): "

if "%choice%"=="1" goto STATUS
if "%choice%"=="2" goto BUILD_NORMAL
if "%choice%"=="3" goto BUILD_ENCRYPTED
if "%choice%"=="4" goto ADMIN_PANEL
if "%choice%"=="5" goto COMMITS
if "%choice%"=="6" goto END
goto MENU

:STATUS
echo.
echo ============================================================
echo 📊 GIT STATUS
echo ============================================================
git status
echo.
pause
goto MENU

:BUILD_NORMAL
echo.
echo ============================================================
echo 🏗️  BUILD SIN ENCRIPTACIÓN
echo ============================================================
echo.
echo ✅ Código ya está pusheado
echo ✅ Build se puede hacer directamente en CodeMagic
echo.
echo 📋 Instrucciones:
echo 1. Ir a CodeMagic dashboard
echo 2. Seleccionar proyecto Ragex
echo 3. Branch: main (commit: c086720)
echo 4. Click "Start new build"
echo 5. Esperar ~15-20 minutos
echo.
echo ⚠️  NOTA: Los patches NO estarán encriptados
echo          Cualquiera puede extraer el IPA y copiar los .3105
echo.
pause
goto MENU

:BUILD_ENCRYPTED
echo.
echo ============================================================
echo 🔐 BUILD CON ENCRIPTACIÓN
echo ============================================================
echo.
echo Paso 1: Instalar dependencias Python...
pip install -r requirements.txt
echo.
echo Paso 2: Encriptar patches...
python encrypt_patches.py
echo.
echo Paso 3: Verificar archivos encriptados...
dir ThreeOneOSFive\PreinstalledPatches\FREE_FIRE\AIMBOT\*.3105e
echo.
set /p confirm="¿Hacer commit y push de archivos encriptados? (s/n): "
if /i "%confirm%"=="s" (
    echo.
    echo Agregando archivos .3105e...
    git add ThreeOneOSFive/PreinstalledPatches/**/*.3105e
    git commit -m "feat: patches encriptados para v2.1.1 production"
    git push origin main
    echo.
    echo ✅ Archivos encriptados pusheados
    echo.
    echo 📋 Ahora ve a CodeMagic y:
    echo 1. Trigger build del último commit
    echo 2. Esperar IPA
    echo 3. ¡Listo!
) else (
    echo.
    echo ⚠️  Cancelado. Archivos NO pusheados.
)
echo.
pause
goto MENU

:ADMIN_PANEL
echo.
echo ============================================================
echo 🎛️  ABRIR PANEL ADMIN
echo ============================================================
echo.
echo Abriendo https://ragex.deno.dev/admin en navegador...
start https://ragex.deno.dev/admin
echo.
echo 📋 Para crear etiquetas:
echo 1. Login: ADMIN / Cleon0208@
echo 2. Click "Etiquetas de Productos"
echo 3. Crear tags para los 4 AIMBOT:
echo    - FREE_FIRE_AIMBOT_Aim_Neck → Test
echo    - FREE_FIRE_AIMBOT_Aim_Head → Test
echo    - FREE_FIRE_AIMBOT_Aim_Budy_70_PERCENT → Test
echo    - FREE_FIRE_AIMBOT_Aim_Budy_90_PERCENT → Test
echo.
pause
goto MENU

:COMMITS
echo.
echo ============================================================
echo 📝 ÚLTIMOS COMMITS
echo ============================================================
git log --oneline -10
echo.
pause
goto MENU

:END
echo.
echo ============================================================
echo 👋 ¡Hasta luego!
echo ============================================================
echo.
exit
