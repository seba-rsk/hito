#Requires -Version 5.1
# desinstalar.ps1
# Elimina las tareas programadas, los archivos y los accesos directos de HITO.

$scriptDir = $PSScriptRoot

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Antes de borrar nada, confirmar que esta carpeta es realmente una
# instalación de HITO (evita borrar una carpeta equivocada si el script
# se ejecutó copiado a otro lugar en vez de desde el acceso directo).
$archivosEsperados = @("hito.ps1", "lanzar.vbs")
$faltantes = $archivosEsperados | Where-Object { -not (Test-Path -LiteralPath (Join-Path $scriptDir $_)) }

if ($faltantes.Count -gt 0) {
    # MessageBox nativo a propósito: si la carpeta no es una instalación
    # de HITO, no se puede asumir que estilos.ps1 exista para los
    # diálogos propios.
    [System.Windows.Forms.MessageBox]::Show(
        "Esta carpeta no parece una instalación de HITO:`n$scriptDir`n`nNo se borró nada. Usá el acceso directo Desinstalar del Menú Inicio.",
        "HITO",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    exit
}

. (Join-Path $scriptDir "constantes.ps1")
. (Join-Path $scriptDir "estilos.ps1")

$continuar = Show-DialogoHito -Titulo "Desinstalar HITO" -Tipo "Pregunta" -SiNo `
    -Mensaje "Esto va a eliminar HITO de tu computadora.`n`nSe borrará la carpeta:`n$scriptDir`n`nSe borrarán las tareas programadas, los archivos de instalación y los accesos directos del Menú Inicio.`n`n¿Querés continuar?"

if (-not $continuar) { exit }

$errores = @()

# Eliminar las tareas diarias. HITO_Reintento ya no la crea hito.ps1 (el
# segundo aviso es un timer interno del proceso), pero se sigue limpiando
# por si quedó huérfana de una instalación de una versión anterior.
$tareas = @($HitoDias.Values | ForEach-Object { $_.Tarea }) + $HitoTareaReintento

# Una sola consulta con wildcard en vez de una por tarea: Get-ScheduledTask
# es cara (varios segundos por invocación en algunos equipos); llamarla una
# vez por tarea hacía que desinstalar pareciera colgado varios segundos.
$tareasExistentes = @(
    Get-ScheduledTask -TaskName "HITO_*" -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty TaskName
)

foreach ($t in $tareas) {
    if ($tareasExistentes -contains $t) {
        try {
            Unregister-ScheduledTask -TaskName $t -Confirm:$false -ErrorAction Stop
        } catch {
            $errores += "No se pudo eliminar la tarea $t."
        }
    }
}

# Eliminar accesos directos del Menú Inicio
if (Test-Path -LiteralPath $HitoCarpetaMenuInicio) {
    try {
        Remove-Item $HitoCarpetaMenuInicio -Recurse -Force -ErrorAction Stop
    } catch {
        $errores += "No se pudo eliminar la carpeta del Menú Inicio."
    }
}

# Borrar la carpeta de instalación (PowerShell ya cargó el script en memoria,
# por eso puede seguir corriendo mientras borra sus propios archivos).
# Ya se validó arriba que $scriptDir contiene los archivos esperados de HITO.
Remove-Item -LiteralPath $scriptDir -Recurse -Force -ErrorAction SilentlyContinue
if (Test-Path -LiteralPath $scriptDir) {
    $errores += "No se pudo borrar por completo la carpeta:`n$scriptDir`nCerrá los programas que la estén usando y borrala manualmente."
}

# El mensaje final se muestra recién acá, con el resultado real del borrado
# (estilos.ps1 ya está cargado en memoria aunque la carpeta se haya borrado).
if ($errores.Count -gt 0) {
    [void](Show-DialogoHito -Titulo "Desinstalado con avisos" -Tipo "Advertencia" `
        -Mensaje ("HITO fue desinstalado con algunos avisos:`n`n" + ($errores -join "`n`n")))
} else {
    [void](Show-DialogoHito -Titulo "Listo" -Tipo "Info" `
        -Mensaje "HITO fue desinstalado correctamente.")
}
