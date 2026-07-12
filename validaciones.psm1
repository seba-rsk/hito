#Requires -Version 5.1
# validaciones.psm1
# Lógica de validación y normalización de horarios. Sin ninguna referencia
# a WinForms: se puede testear sin cargar una GUI.
# Lo usan configurar.ps1 y hito.ps1 vía Import-Module.

function ConvertTo-HoraNormalizada {
    <#
    .SYNOPSIS
    Normaliza un texto de hora: recorta espacios y acepta punto o coma como
    separador, convirtiéndolos a dos puntos ("17.30" y "17,30" -> "17:30").

    .PARAMETER Hora
    Texto ingresado por el usuario o leído de config.json.

    .OUTPUTS
    [string] El texto normalizado. No valida: un texto que no es una hora
    sale igual de inválido que entró (validar después con Test-HoraValida).
    #>
    param([string]$Hora)

    return $Hora.Trim() -replace '[.,]', ':'
}

function Test-HoraValida {
    <#
    .SYNOPSIS
    Valida que un texto de hora tenga formato HH:MM en rango 24 horas.

    .PARAMETER Hora
    Texto a validar, por ejemplo "17:30".

    .OUTPUTS
    Hashtable con:
      Valida [bool]  - true si el formato y el rango son correctos.
      Motivo [string] - "formato" o "rango" cuando Valida es false, $null si es true.
    #>
    param([string]$Hora)

    if ($Hora -notmatch "^\d{1,2}:\d{2}$") {
        return @{ Valida = $false; Motivo = "formato" }
    }
    $partes = $Hora -split ":"
    if ([int]$partes[0] -gt 23 -or [int]$partes[1] -gt 59) {
        return @{ Valida = $false; Motivo = "rango" }
    }
    return @{ Valida = $true; Motivo = $null }
}

function Test-Inputs {
    <#
    .SYNOPSIS
    Valida la ruta de la planilla y el horario configurado para cada día.
    Cada hora se normaliza primero con ConvertTo-HoraNormalizada, así que
    se acepta punto o coma como separador además de dos puntos.

    .PARAMETER RutaPlanilla
    Ruta de archivo elegida por el usuario en el formulario.

    .PARAMETER Horas
    Hashtable ordenado: día interno (ej. "Lunes") -> texto de hora ingresado.

    .OUTPUTS
    Hashtable con:
      Ok [bool]
      HorasNormalizadas [ordered hashtable] - solo si Ok es true, horas en formato HH:MM.
      MotivoTipo [string] - "planilla", "sin_dias" o "hora", solo si Ok es false.
      Dia [string] - día interno con el horario inválido, solo si MotivoTipo es "hora".
      Motivo [string] - "formato" o "rango", solo si MotivoTipo es "hora".
    #>
    param(
        [string]$RutaPlanilla,
        [System.Collections.Specialized.OrderedDictionary]$Horas
    )

    if ($RutaPlanilla -eq "") {
        return @{ Ok = $false; MotivoTipo = "planilla" }
    }

    if ($Horas.Count -eq 0) {
        return @{ Ok = $false; MotivoTipo = "sin_dias" }
    }

    $horasNorm = [ordered]@{}
    foreach ($dia in $Horas.Keys) {
        $hora      = ConvertTo-HoraNormalizada $Horas[$dia]
        $resultado = Test-HoraValida $hora
        if (-not $resultado.Valida) {
            return @{ Ok = $false; MotivoTipo = "hora"; Dia = $dia; Motivo = $resultado.Motivo }
        }
        $partes = $hora -split ":"
        $horasNorm[$dia] = "{0:D2}:{1:D2}" -f [int]$partes[0], [int]$partes[1]
    }
    return @{ Ok = $true; HorasNormalizadas = $horasNorm }
}

Export-ModuleMember -Function ConvertTo-HoraNormalizada, Test-HoraValida, Test-Inputs
