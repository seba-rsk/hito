#Requires -Version 5.1
# SincronizarHorarios.Tests.ps1
# Tests Pester para Sync-TareasHorario (sincronizar_horarios.ps1): la
# decisión de crear, actualizar o eliminar cada tarea programada según
# los días activos. Mockea los cmdlets de Task Scheduler — no crea ni
# toca ninguna tarea real de Windows.

BeforeAll {
    . (Join-Path $PSScriptRoot "..\constantes.ps1")
    . (Join-Path $PSScriptRoot "..\sincronizar_horarios.ps1")
}

Describe "Sync-TareasHorario" {

    BeforeEach {
        # New-ScheduledTaskTrigger/Action/SettingsSet solo arman objetos en
        # memoria (CimInstance), sin tocar el sistema — se dejan correr de
        # verdad. Mockear su resultado con un objeto genérico rompe la
        # validación de tipo real de Register-ScheduledTask, que exige
        # CimInstance. Los que sí tocan el Programador de tareas real van
        # mockeados: Get-ScheduledTask, Register/Set/Unregister-ScheduledTask.
        Mock Get-ScheduledTask { @() }
        Mock Register-ScheduledTask { }
        Mock Set-ScheduledTask { }
        Mock Unregister-ScheduledTask { }
    }

    It "crea (Register) la tarea de un día activo que todavía no tiene tarea" {
        $horarios = [ordered]@{ Lunes = "17:30" }
        $errores  = Sync-TareasHorario -HorariosActivos $horarios -ScriptDir "C:\HITO"

        $errores.Count | Should -Be 0
        Should -Invoke Register-ScheduledTask -Times 1 -ParameterFilter { $TaskName -eq "HITO_Lun" }
        Should -Invoke Set-ScheduledTask -Times 0
        Should -Invoke Unregister-ScheduledTask -Times 0
    }

    It "actualiza (Set) la tarea de un día activo que ya existe, sin volver a crearla" {
        Mock Get-ScheduledTask { @([pscustomobject]@{ TaskName = "HITO_Lun" }) }
        $horarios = [ordered]@{ Lunes = "18:00" }

        Sync-TareasHorario -HorariosActivos $horarios -ScriptDir "C:\HITO" | Out-Null

        Should -Invoke Set-ScheduledTask -Times 1 -ParameterFilter { $TaskName -eq "HITO_Lun" }
        Should -Invoke Register-ScheduledTask -Times 0
    }

    It "elimina (Unregister) la tarea de un día que dejó de estar activo" {
        Mock Get-ScheduledTask { @([pscustomobject]@{ TaskName = "HITO_Sab" }) }
        $horarios = [ordered]@{ Lunes = "17:30" }   # Sabado no incluido = inactivo

        Sync-TareasHorario -HorariosActivos $horarios -ScriptDir "C:\HITO" | Out-Null

        Should -Invoke Unregister-ScheduledTask -Times 1 -ParameterFilter { $TaskName -eq "HITO_Sab" }
    }

    It "no toca nada para un día inactivo que tampoco tiene tarea" {
        $horarios = [ordered]@{ Lunes = "17:30" }

        Sync-TareasHorario -HorariosActivos $horarios -ScriptDir "C:\HITO" | Out-Null

        # Un solo Register (Lunes) y ningún Set/Unregister para el resto
        # de los 6 días restantes, todos inactivos y sin tarea previa.
        Should -Invoke Register-ScheduledTask -Times 1
        Should -Invoke Set-ScheduledTask -Times 0
        Should -Invoke Unregister-ScheduledTask -Times 0
    }

    It "sincroniza los 7 días de forma independiente en una sola pasada" {
        Mock Get-ScheduledTask { @(
            [pscustomobject]@{ TaskName = "HITO_Mar" }
            [pscustomobject]@{ TaskName = "HITO_Dom" }
        ) }
        # Lunes: activo, sin tarea -> Register. Martes: activo, con tarea -> Set.
        # Domingo: inactivo, con tarea -> Unregister. Resto: inactivo, sin tarea -> nada.
        $horarios = [ordered]@{ Lunes = "17:30"; Martes = "17:30" }

        Sync-TareasHorario -HorariosActivos $horarios -ScriptDir "C:\HITO" | Out-Null

        Should -Invoke Register-ScheduledTask -Times 1 -ParameterFilter { $TaskName -eq "HITO_Lun" }
        Should -Invoke Set-ScheduledTask -Times 1 -ParameterFilter { $TaskName -eq "HITO_Mar" }
        Should -Invoke Unregister-ScheduledTask -Times 1 -ParameterFilter { $TaskName -eq "HITO_Dom" }
    }

    It "acumula el nombre del día cuando falla la creación de su tarea, y sigue con el resto" {
        Mock Register-ScheduledTask { throw "Acceso denegado" }
        $horarios = [ordered]@{ Lunes = "17:30"; Martes = "17:30" }

        $errores = Sync-TareasHorario -HorariosActivos $horarios -ScriptDir "C:\HITO"

        $errores | Should -Contain "Lunes"
        $errores | Should -Contain "Martes"
        $errores.Count | Should -Be 2
    }

    It "acumula el nombre del día cuando falla la eliminación de su tarea" {
        Mock Get-ScheduledTask { @([pscustomobject]@{ TaskName = "HITO_Sab" }) }
        Mock Unregister-ScheduledTask { throw "Tarea en uso" }
        $horarios = [ordered]@{ Lunes = "17:30" }

        $errores = Sync-TareasHorario -HorariosActivos $horarios -ScriptDir "C:\HITO"

        $errores | Should -Contain "Sabado"
    }
}
