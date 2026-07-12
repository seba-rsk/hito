#Requires -Version 5.1
# sincronizar_horarios.ps1
# Reconcilia las tareas programadas de HITO contra un conjunto de días
# activos: crea las que faltan, actualiza las que ya existen y elimina las
# de días que se desactivaron. La usan configurar.ps1 (al guardar) y
# aplicar_horarios.ps1 (al reinstalar), para no duplicar esta lógica.
# Requiere que constantes.ps1 ya haya sido dot-sourceado antes (usa $HitoDias).

function Sync-TareasHorario {
    <#
    .SYNOPSIS
    Crea, actualiza o elimina las tareas programadas de HITO para que
    coincidan exactamente con los días activos y sus horarios.

    .PARAMETER HorariosActivos
    Hashtable día interno (ej. "Lunes") -> hora "HH:MM". Los días de
    $HitoDias que no aparecen acá se consideran desactivados: su tarea
    programada se elimina si existe.

    .PARAMETER ScriptDir
    Carpeta de instalación de HITO (para armar la acción de la tarea).

    .OUTPUTS
    Array con los nombres (Nombre interno) de los días cuya tarea no se
    pudo sincronizar.
    #>
    param(
        [hashtable]$HorariosActivos,
        [string]$ScriptDir
    )

    $lanzador = Join-Path $ScriptDir "lanzar.vbs"
    $script   = Join-Path $ScriptDir "hito.ps1"
    $errores  = @()

    # Una sola consulta con wildcard en vez de una por día: Get-ScheduledTask
    # es una llamada cara (varios segundos por invocación en algunos equipos);
    # llamarla 7 veces hacía que Guardar tardara más de 20 segundos.
    $tareasExistentes = @(
        Get-ScheduledTask -TaskName "HITO_*" -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty TaskName
    )

    foreach ($diaSemana in $HitoDias.Keys) {
        $info   = $HitoDias[$diaSemana]
        $activo = $HorariosActivos.Contains($info.Nombre)
        $existe = $tareasExistentes -contains $info.Tarea

        try {
            if ($activo) {
                $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $diaSemana -At $HorariosActivos[$info.Nombre]
                if ($existe) {
                    Set-ScheduledTask -TaskName $info.Tarea -Trigger $trigger -ErrorAction Stop | Out-Null
                } else {
                    $accion   = New-ScheduledTaskAction -Execute $HitoRutaWscript `
                                -Argument "`"$lanzador`" `"$script`""
                    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable
                    Register-ScheduledTask -TaskName $info.Tarea -Action $accion `
                        -Trigger $trigger -Settings $settings -Force -ErrorAction Stop | Out-Null
                }
            } elseif ($existe) {
                Unregister-ScheduledTask -TaskName $info.Tarea -Confirm:$false -ErrorAction Stop
            }
        } catch {
            $errores += $info.Nombre
        }
    }
    return $errores
}
