#Requires -Version 5.1
# aplicar_horarios.ps1 — v1.0.0
# Reaplica los horarios guardados en config.json a las tareas programadas.
# Llamado por instalar.bat cuando detecta una configuracion previa.

$scriptDir = $PSScriptRoot
$configFile = Join-Path $scriptDir "config.json"

if (-not (Test-Path $configFile)) { exit }

$config = Get-Content $configFile -Encoding UTF8 -Raw | ConvertFrom-Json

$tareas = [ordered]@{
    Lunes     = "HITO_Lun"
    Martes    = "HITO_Mar"
    Miercoles = "HITO_Mie"
    Jueves    = "HITO_Jue"
    Viernes   = "HITO_Vie"
}
$diasSemana = [ordered]@{
    Lunes     = "Monday"
    Martes    = "Tuesday"
    Miercoles = "Wednesday"
    Jueves    = "Thursday"
    Viernes   = "Friday"
}

foreach ($dia in @($tareas.Keys)) {
    $hora = $config.horarios.$dia
    if ($hora) {
        $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $diasSemana[$dia] -At $hora
        Set-ScheduledTask -TaskName $tareas[$dia] -Trigger $trigger | Out-Null
    }
}
