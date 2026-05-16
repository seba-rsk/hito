#Requires -Version 5.1
# desinstalar.ps1 — v1.0.0
# Elimina las tareas programadas, los archivos y los accesos directos de HITO.

Add-Type -AssemblyName System.Windows.Forms

$respuesta = [System.Windows.Forms.MessageBox]::Show(
    "Esto va a eliminar HITO de tu computadora.`n`nSe borrarán las tareas programadas, los archivos de instalación y los accesos directos del Menú Inicio.`n`n¿Querés continuar?",
    "Desinstalar HITO",
    [System.Windows.Forms.MessageBoxButtons]::YesNo,
    [System.Windows.Forms.MessageBoxIcon]::Warning
)

if ($respuesta -ne [System.Windows.Forms.DialogResult]::Yes) { exit }

$errores = @()

# Eliminar las 5 tareas diarias y el reintento
$tareas = @("HITO_Lun","HITO_Mar","HITO_Mie","HITO_Jue","HITO_Vie","HITO_Reintento")
foreach ($t in $tareas) {
    if (Get-ScheduledTask -TaskName $t -ErrorAction SilentlyContinue) {
        try {
            Unregister-ScheduledTask -TaskName $t -Confirm:$false -ErrorAction Stop
        } catch {
            $errores += "No se pudo eliminar la tarea $t."
        }
    }
}

# Eliminar accesos directos del Menu Inicio
$carpetaMenu = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\HITO"
if (Test-Path $carpetaMenu) {
    try {
        Remove-Item $carpetaMenu -Recurse -Force -ErrorAction Stop
    } catch {
        $errores += "No se pudo eliminar la carpeta del Menú Inicio."
    }
}

# Eliminar carpeta de instalacion (donde vive este script)
$scriptDir = $PSScriptRoot

if ($errores.Count -gt 0) {
    [System.Windows.Forms.MessageBox]::Show(
        "HITO fue desinstalado con algunos avisos:`n`n" + ($errores -join "`n"),
        "Desinstalación completada",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
} else {
    [System.Windows.Forms.MessageBox]::Show(
        "HITO fue desinstalado correctamente.",
        "Listo",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
}

# Borrar la carpeta de instalacion (PowerShell ya cargo el script en memoria)
Remove-Item -LiteralPath $scriptDir -Recurse -Force -ErrorAction SilentlyContinue