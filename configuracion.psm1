#Requires -Version 5.1
# configuracion.psm1
# Lectura y parseo de config.json. Sin ninguna referencia a WinForms: se
# puede testear sin cargar una GUI.
# Lo usan hito.ps1, configurar.ps1 y aplicar_horarios.ps1 vía Import-Module,
# en vez de cada uno leer y parsear el archivo por su cuenta.

function Get-HitoConfig {
    <#
    .SYNOPSIS
    Lee y parsea config.json.

    .PARAMETER RutaConfig
    Ruta completa al archivo config.json.

    .OUTPUTS
    Hashtable con:
      Existe [bool]   - false si el archivo no existe. No es un error: es
                        el estado normal antes del primer guardado.
      Ok [bool]       - false si el archivo existe pero no se pudo leer o
                        parsear (JSON dañado, editado a mano de forma
                        inválida). Cuando es false, Planilla y Horarios
                        vienen vacíos.
      Planilla [string] - ruta de la planilla, recortada de espacios.
                          "" si no existe la clave, si el archivo no existe
                          o si Ok es false.
      Horarios [hashtable] - día interno (ej. "Lunes") -> texto de hora tal
                             como está en el archivo, sin normalizar. Vacío
                             si no existe la clave, si el archivo no existe
                             o si Ok es false.
    #>
    param([string]$RutaConfig)

    if (-not (Test-Path -LiteralPath $RutaConfig)) {
        return @{ Existe = $false; Ok = $false; Planilla = ""; Horarios = @{} }
    }

    try {
        $config = Get-Content $RutaConfig -Encoding UTF8 -Raw | ConvertFrom-Json
    } catch {
        return @{ Existe = $true; Ok = $false; Planilla = ""; Horarios = @{} }
    }

    $planilla = if ($config.planilla) { $config.planilla.Trim() } else { "" }

    $horarios = @{}
    if ($config.PSObject.Properties['horarios']) {
        $config.horarios.PSObject.Properties | ForEach-Object { $horarios[$_.Name] = $_.Value }
    }

    return @{ Existe = $true; Ok = $true; Planilla = $planilla; Horarios = $horarios }
}

Export-ModuleMember -Function Get-HitoConfig
