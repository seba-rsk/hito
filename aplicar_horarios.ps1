#Requires -Version 5.1
# aplicar_horarios.ps1
# Reaplica los horarios guardados en config.json a las tareas programadas.
# Llamado por crear_tareas.ps1 cuando detecta una configuración previa.

$scriptDir  = $PSScriptRoot
$configFile = Join-Path $scriptDir "config.json"

. (Join-Path $scriptDir "constantes.ps1")
. (Join-Path $scriptDir "sincronizar_horarios.ps1")
Import-Module (Join-Path $scriptDir "configuracion.psm1") -Force

$cfg = Get-HitoConfig -RutaConfig $configFile
if (-not $cfg.Existe) { exit }
if (-not $cfg.Ok) {
    Write-Host "[AVISO] No se pudo leer config.json, se omite la reaplicación de horarios." -ForegroundColor Yellow
    exit
}

Sync-TareasHorario -HorariosActivos $cfg.Horarios -ScriptDir $scriptDir | Out-Null
