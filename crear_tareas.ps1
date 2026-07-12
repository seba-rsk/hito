#Requires -Version 5.1
# crear_tareas.ps1
# Crea las tareas programadas semanales de HITO (Lunes a Viernes por
# defecto), reaplica horarios previos si existe config.json, y crea los
# accesos directos del Menú Inicio.
# Llamado por instalar.bat después de copiar los archivos a %USERPROFILE%\HITO.
#
# Usa cmdlets nativos (Register-ScheduledTask, WScript.Shell con parámetros
# separados) en vez de armar comandos por concatenación de texto: evita que
# una ruta de perfil de usuario con espacios rompa la instalación.

$scriptDir = $PSScriptRoot
. (Join-Path $scriptDir "constantes.ps1")
. (Join-Path $scriptDir "sincronizar_horarios.ps1")

$lanzador      = Join-Path $scriptDir "lanzar.vbs"
$configurador  = Join-Path $scriptDir "configurar.ps1"
$desinstalador = Join-Path $scriptDir "desinstalar.ps1"

function New-TareasSemanales {
    <#
    .SYNOPSIS
    Crea las tareas programadas de los días activos por defecto (Lunes a
    Viernes), con ejecución retroactiva si la PC estaba apagada a la hora
    configurada. Sábado y Domingo quedan disponibles pero sin tarea hasta
    que el usuario los active desde Configuración.

    .OUTPUTS
    Array con los nombres de los días en los que falló la creación de la tarea.
    #>
    $horariosIniciales = [ordered]@{}
    foreach ($dia in $HitoDiasLaborables) { $horariosIniciales[$dia] = $HitoHoraDefault }

    $errores = Sync-TareasHorario -HorariosActivos $horariosIniciales -ScriptDir $scriptDir
    foreach ($dia in $HitoDias.Keys) {
        $info = $HitoDias[$dia]
        if ($errores -contains $info.Nombre) {
            Write-Host "[ERROR] Tarea $($info.Nombre)" -ForegroundColor Red
        } elseif ($horariosIniciales.Contains($info.Nombre)) {
            Write-Host "[OK] Tarea $($info.Nombre.PadRight(10)) - $HitoHoraDefault" -ForegroundColor Green
        }
    }
    return $errores
}

function Sync-HorariosPrevios {
    <#
    .SYNOPSIS
    Si ya existe una configuración guardada (reinstalación), reaplica esos
    horarios a las tareas recién creadas.
    #>
    $configFile = Join-Path $scriptDir "config.json"
    if (-not (Test-Path -LiteralPath $configFile)) { return }

    Write-Host ""
    Write-Host "[INFO] Configuración previa detectada. Aplicando horarios..." -ForegroundColor Cyan
    try {
        & (Join-Path $scriptDir "aplicar_horarios.ps1")
        Write-Host "[OK] Horarios personalizados aplicados" -ForegroundColor Green
    } catch {
        Write-Host "[AVISO] No se pudieron aplicar los horarios. Abrir HITO y hacer clic en Guardar." -ForegroundColor Yellow
    }
}

function New-AccesosDirectos {
    <#
    .SYNOPSIS
    Crea la carpeta HITO en el Menú Inicio con los accesos directos de
    HITO (ventana principal: configuración + Acerca de) y Desinstalar.
    #>
    $menu = $HitoCarpetaMenuInicio
    if (-not (Test-Path -LiteralPath $menu)) { New-Item -ItemType Directory -Path $menu | Out-Null }

    $shell = New-Object -ComObject WScript.Shell

    # Ícono propio si está disponible; si no, uno genérico de Windows.
    $iconoHito = Join-Path $scriptDir "hito.ico"
    $iconoMenu = if (Test-Path -LiteralPath $iconoHito) { "$iconoHito,0" }
                 else { "$env:WINDIR\System32\imageres.dll,109" }

    try {
        $lnk = $shell.CreateShortcut((Join-Path $menu "HITO.lnk"))
        $lnk.TargetPath       = $HitoRutaWscript
        $lnk.Arguments        = "`"$lanzador`" `"$configurador`""
        $lnk.WorkingDirectory = $env:USERPROFILE
        $lnk.IconLocation     = $iconoMenu
        $lnk.Save()
        Write-Host "[OK] Acceso directo: HITO" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] Acceso directo: HITO" -ForegroundColor Red
    }

    try {
        $lnk = $shell.CreateShortcut((Join-Path $menu "Desinstalar.lnk"))
        $lnk.TargetPath       = $HitoRutaPowershell
        $lnk.Arguments        = "-ExecutionPolicy Bypass -NonInteractive -WindowStyle Hidden -File `"$desinstalador`""
        $lnk.WorkingDirectory = $env:USERPROFILE
        $lnk.IconLocation     = "$env:WINDIR\System32\shell32.dll,32"
        $lnk.Save()
        Write-Host "[OK] Acceso directo: Desinstalar" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] Acceso directo: Desinstalar" -ForegroundColor Red
    }
}

$erroresTareas = New-TareasSemanales
Sync-HorariosPrevios
New-AccesosDirectos

if ($erroresTareas.Count -gt 0) {
    Write-Host ""
    Write-Host "[AVISO] No se pudieron crear las tareas de: $($erroresTareas -join ', ')" -ForegroundColor Yellow
    exit 1
}
exit 0
