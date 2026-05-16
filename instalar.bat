@echo off
:: instalar.bat - v1.0.0
:: Instala HITO: crea las tareas programadas y los accesos directos.
:: No requiere permisos de administrador.

echo =====================================================
echo   HITO - Instalador v1.0.0
echo =====================================================
echo.

set "DESTINO=%USERPROFILE%\HITO"
set "SCRIPT=%DESTINO%\hito.ps1"
set "CONFIGURADOR=%DESTINO%\configurar.ps1"
set "DESINSTALADOR=%DESTINO%\desinstalar.ps1"
set "LANZADOR=%DESTINO%\lanzar.vbs"
set "HORA_DEFAULT=17:30"

:: Crear carpeta de instalacion
if not exist "%DESTINO%" (
    mkdir "%DESTINO%"
    echo [OK] Carpeta creada: %DESTINO%
) else (
    echo [OK] Carpeta ya existe: %DESTINO%
)

:: Copiar archivos
copy /Y "%~dp0hito.ps1"             "%SCRIPT%"                          >nul && echo [OK] hito.ps1 copiado
copy /Y "%~dp0configurar.ps1"       "%CONFIGURADOR%"                    >nul && echo [OK] configurar.ps1 copiado
copy /Y "%~dp0desinstalar.ps1"      "%DESINSTALADOR%"                   >nul && echo [OK] desinstalar.ps1 copiado
copy /Y "%~dp0aplicar_horarios.ps1" "%DESTINO%\aplicar_horarios.ps1"    >nul && echo [OK] aplicar_horarios.ps1 copiado
copy /Y "%~dp0lanzar.vbs"           "%LANZADOR%"                        >nul && echo [OK] lanzar.vbs copiado
if exist "%~dp0hito.ico" (
    copy /Y "%~dp0hito.ico" "%DESTINO%\hito.ico" >nul && echo [OK] hito.ico copiado
) else (
    echo [AVISO] hito.ico no encontrado - las ventanas usaran el icono por defecto
)
echo.

:: -- Crear tareas programadas (lunes a viernes) --------------------------------

set "TR=wscript.exe \"%LANZADOR%\" \"%SCRIPT%\""

schtasks /Delete /TN "HITO_Lun" /F >nul 2>&1
schtasks /Create /TN "HITO_Lun" /TR "%TR%" /SC WEEKLY /D MON /ST %HORA_DEFAULT% /F >nul
if %ERRORLEVEL% EQU 0 (echo [OK] Tarea Lunes     - %HORA_DEFAULT%) else (echo [ERROR] Tarea Lunes)

schtasks /Delete /TN "HITO_Mar" /F >nul 2>&1
schtasks /Create /TN "HITO_Mar" /TR "%TR%" /SC WEEKLY /D TUE /ST %HORA_DEFAULT% /F >nul
if %ERRORLEVEL% EQU 0 (echo [OK] Tarea Martes    - %HORA_DEFAULT%) else (echo [ERROR] Tarea Martes)

schtasks /Delete /TN "HITO_Mie" /F >nul 2>&1
schtasks /Create /TN "HITO_Mie" /TR "%TR%" /SC WEEKLY /D WED /ST %HORA_DEFAULT% /F >nul
if %ERRORLEVEL% EQU 0 (echo [OK] Tarea Miercoles - %HORA_DEFAULT%) else (echo [ERROR] Tarea Miercoles)

schtasks /Delete /TN "HITO_Jue" /F >nul 2>&1
schtasks /Create /TN "HITO_Jue" /TR "%TR%" /SC WEEKLY /D THU /ST %HORA_DEFAULT% /F >nul
if %ERRORLEVEL% EQU 0 (echo [OK] Tarea Jueves    - %HORA_DEFAULT%) else (echo [ERROR] Tarea Jueves)

schtasks /Delete /TN "HITO_Vie" /F >nul 2>&1
schtasks /Create /TN "HITO_Vie" /TR "%TR%" /SC WEEKLY /D FRI /ST %HORA_DEFAULT% /F >nul
if %ERRORLEVEL% EQU 0 (echo [OK] Tarea Viernes   - %HORA_DEFAULT%) else (echo [ERROR] Tarea Viernes)

echo.

:: Ejecucion retroactiva (si la PC estaba apagada a la hora configurada)
for %%T in (HITO_Lun HITO_Mar HITO_Mie HITO_Jue HITO_Vie) do (
    powershell -Command "Set-ScheduledTask -TaskName '%%T' -Settings (New-ScheduledTaskSettingsSet -StartWhenAvailable)" >nul 2>&1
)
echo [OK] Ejecucion retroactiva activada

:: -- Reaplicar horarios si habia config previa ---------------------------------
if exist "%DESTINO%\config.json" (
    echo.
    echo [INFO] Configuracion previa detectada. Aplicando horarios...
    powershell -ExecutionPolicy Bypass -File "%DESTINO%\aplicar_horarios.ps1" >nul 2>&1
    if %ERRORLEVEL% EQU 0 (
        echo [OK] Horarios personalizados aplicados
    ) else (
        echo [AVISO] No se pudieron aplicar los horarios. Abrir Configuracion y hacer clic en Guardar.
    )
)

:: -- Carpeta HITO en el Menu Inicio -------------------------------------------
set "MENU=%APPDATA%\Microsoft\Windows\Start Menu\Programs\HITO"
if not exist "%MENU%" mkdir "%MENU%"

:: Acceso directo: Configuracion
powershell -Command "$s=New-Object -ComObject WScript.Shell; $n='Configuraci'+[char]243+'n'; $l=$s.CreateShortcut('%MENU%\'+$n+'.lnk'); $l.TargetPath='wscript.exe'; $l.Arguments='\"%LANZADOR%\" \"%CONFIGURADOR%\"'; $l.WorkingDirectory='%USERPROFILE%'; $l.IconLocation='C:\Windows\System32\imageres.dll,109'; $l.Save()" >nul
if %ERRORLEVEL% EQU 0 (echo [OK] Acceso directo: Configuracion) else (echo [ERROR] Acceso directo: Configuracion)

:: Acceso directo: Desinstalar
powershell -Command "$s=New-Object -ComObject WScript.Shell; $l=$s.CreateShortcut('%MENU%\Desinstalar.lnk'); $l.TargetPath='powershell.exe'; $l.Arguments='-ExecutionPolicy Bypass -NonInteractive -WindowStyle Hidden -File \"%DESINSTALADOR%\"'; $l.WorkingDirectory='%USERPROFILE%'; $l.IconLocation='C:\Windows\System32\shell32.dll,32'; $l.Save()" >nul
if %ERRORLEVEL% EQU 0 (echo [OK] Acceso directo: Desinstalar) else (echo [ERROR] Acceso directo: Desinstalar)

echo.
echo =====================================================
echo   LISTO. Proximos pasos:
echo.
echo   1. Abri el Menu Inicio
echo   2. Busca la carpeta "HITO"
echo   3. Abri "Configuracion"
echo   4. Selecciona tu planilla y ajusta los horarios
echo      (por defecto: 17:30 todos los dias)
echo =====================================================
echo.
pause
