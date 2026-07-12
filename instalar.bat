@echo off
:: instalar.bat
:: Instala HITO: copia los archivos y delega la creacion de tareas
:: programadas y accesos directos a crear_tareas.ps1.
:: No requiere permisos de administrador.
:: La version del software vive en constantes.ps1 (variable HitoVersion).

echo =====================================================
echo   HITO - Instalador
echo =====================================================
echo.

set "DESTINO=%USERPROFILE%\HITO"

:: Crear carpeta de instalacion
if not exist "%DESTINO%" (
    mkdir "%DESTINO%"
    echo [OK] Carpeta creada: %DESTINO%
) else (
    echo [OK] Carpeta ya existe: %DESTINO%
)

:: Copiar archivos
copy /Y "%~dp0hito.ps1"             "%DESTINO%\hito.ps1"             >nul && echo [OK] hito.ps1 copiado
copy /Y "%~dp0configurar.ps1"       "%DESTINO%\configurar.ps1"       >nul && echo [OK] configurar.ps1 copiado
copy /Y "%~dp0desinstalar.ps1"      "%DESTINO%\desinstalar.ps1"      >nul && echo [OK] desinstalar.ps1 copiado
copy /Y "%~dp0aplicar_horarios.ps1" "%DESTINO%\aplicar_horarios.ps1" >nul && echo [OK] aplicar_horarios.ps1 copiado
copy /Y "%~dp0crear_tareas.ps1"        "%DESTINO%\crear_tareas.ps1"        >nul && echo [OK] crear_tareas.ps1 copiado
copy /Y "%~dp0sincronizar_horarios.ps1" "%DESTINO%\sincronizar_horarios.ps1" >nul && echo [OK] sincronizar_horarios.ps1 copiado
copy /Y "%~dp0acerca_de.ps1"           "%DESTINO%\acerca_de.ps1"           >nul && echo [OK] acerca_de.ps1 copiado
copy /Y "%~dp0constantes.ps1"          "%DESTINO%\constantes.ps1"          >nul && echo [OK] constantes.ps1 copiado
copy /Y "%~dp0estilos.ps1"             "%DESTINO%\estilos.ps1"             >nul && echo [OK] estilos.ps1 copiado
copy /Y "%~dp0validaciones.psm1"       "%DESTINO%\validaciones.psm1"       >nul && echo [OK] validaciones.psm1 copiado
copy /Y "%~dp0configuracion.psm1"      "%DESTINO%\configuracion.psm1"      >nul && echo [OK] configuracion.psm1 copiado
copy /Y "%~dp0lanzar.vbs"              "%DESTINO%\lanzar.vbs"              >nul && echo [OK] lanzar.vbs copiado
if exist "%~dp0hito.ico" (
    copy /Y "%~dp0hito.ico" "%DESTINO%\hito.ico" >nul && echo [OK] hito.ico copiado
) else (
    echo [AVISO] hito.ico no encontrado - las ventanas usaran el icono por defecto
)
echo.

:: -- Tareas programadas, accesos directos y reaplicacion de horarios previos --
:: Ruta completa al ejecutable: invocarlo solo por nombre ("powershell")
:: hace que cmd.exe lo busque primero en la carpeta actual antes que en
:: el PATH del sistema, y podria ejecutar un archivo con ese nombre
:: plantado en la carpeta del instalador en vez del PowerShell real.
echo Configurando tareas programadas y accesos directos...
echo.
"%WINDIR%\System32\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -File "%DESTINO%\crear_tareas.ps1"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [AVISO] Hubo problemas creando alguna tarea programada. Revisa los mensajes de arriba.
)

echo.
echo =====================================================
echo   LISTO. Proximos pasos:
echo.
echo   1. Abri el Menu Inicio
echo   2. Busca la carpeta "HITO"
echo   3. Abri "HITO"
echo   4. Selecciona tu planilla y ajusta los dias/horarios
echo      (por defecto: Lunes a Viernes, 17:30)
echo =====================================================
echo.
pause
