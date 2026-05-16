#Requires -Version 5.1
# hito.ps1 — v1.0.0
# Muestra una ventana para recordar completar la planilla de horas.
# La configuracion se lee desde config.json (misma carpeta que este script).
# Para cambiar la planilla u hora: Menu Inicio -> HITO -> Configuracion
# Usar -Test para mostrar la ventana sin importar la hora (solo para pruebas).

param([switch]$Test, [switch]$Segundo, [switch]$SinRed)

$scriptDir = $PSScriptRoot
$scriptPath = $MyInvocation.MyCommand.Path
$configFile = Join-Path $scriptDir "config.json"

# --- Leer configuracion ---
if (Test-Path $configFile) {
    $config       = Get-Content $configFile -Encoding UTF8 -Raw | ConvertFrom-Json
    $planillaPath = $config.planilla.Trim()

    $mapDias    = @{ Monday="Lunes"; Tuesday="Martes"; Wednesday="Miercoles"; Thursday="Jueves"; Friday="Viernes" }
    $diaHoy     = $mapDias[(Get-Date).DayOfWeek.ToString()]
    if (-not $diaHoy -and -not $Test) { exit }
    if (-not $diaHoy) { $diaHoy = "Lunes" }   # valor de prueba para -Test en fin de semana
    $horaConfig = $config.horarios.$diaHoy
    if (-not $horaConfig -and -not $Test) { exit }
    if (-not $horaConfig) { $horaConfig = "09:00" }
    $horaConfig = $horaConfig.Trim()
} else {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show(
        "No encontramos una planilla configurada.`nSe va a abrir el configurador ahora.",
        "HITO",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
    $lanzador     = Join-Path $scriptDir "lanzar.vbs"
    $configurador = Join-Path $scriptDir "configurar.ps1"
    if (Test-Path $configurador) {
        Start-Process "wscript.exe" "`"$lanzador`" `"$configurador`""
    }
    exit
}

# Si la PC estaba apagada a la hora configurada, mostrar solo si seguimos en el mismo dia.
if (-not $Test) {
    $partes       = $horaConfig -split ":"
    $ahora        = Get-Date
    $horaEsperada = $ahora.Date.AddHours([int]$partes[0]).AddMinutes([int]$partes[1])
    if ($ahora -lt $horaEsperada) { exit }
}

# --- Programar segundo recordatorio si el usuario no responde en 15 minutos ---
if (-not $Test -and -not $Segundo) {
    $lanzadorPath = Join-Path $scriptDir "lanzar.vbs"
    $accion  = New-ScheduledTaskAction -Execute "wscript.exe" `
               -Argument "`"$lanzadorPath`" `"$scriptPath`" -Segundo"
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(15)
    Register-ScheduledTask -TaskName "HITO_Reintento" `
        -Action $accion -Trigger $trigger -Force -ErrorAction SilentlyContinue | Out-Null
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Verificar disponibilidad de la carpeta de red ---
$redDisponible = if ($SinRed) { $false } else { Test-Path (Split-Path $planillaPath) }

# --- Log de actividad ---
$logFile  = Join-Path $scriptDir "log.txt"
$avisoNum = if ($Segundo) { "2do aviso" } else { "1er aviso" }

function Write-Log {
    param($estado)
    $fecha = Get-Date -Format "yyyy-MM-dd"
    $hora  = Get-Date -Format "HH:mm"
    $linea = "$fecha | $diaHoy | $avisoNum | $estado | $hora"
    if (Test-Path $logFile) {
        $contenido = @(Get-Content $logFile -Encoding UTF8)
        ($contenido + $linea) | Set-Content $logFile -Encoding UTF8
    } else {
        $linea | Set-Content $logFile -Encoding UTF8
    }
}

# --- Ventana principal ---
$form                 = New-Object System.Windows.Forms.Form
$form.Text            = "HITO – Recordatorio"
$form.Size            = New-Object System.Drawing.Size(420, 220)
$form.StartPosition   = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox     = $false
$form.MinimizeBox     = $false
$form.TopMost         = $true
$form.BackColor       = [System.Drawing.Color]::FromArgb(245, 245, 245)
$iconPath = Join-Path $scriptDir "hito.ico"
if (Test-Path $iconPath) { $form.Icon = New-Object System.Drawing.Icon($iconPath) }

$labelTitulo          = New-Object System.Windows.Forms.Label
$labelTitulo.Font     = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$labelTitulo.Location = New-Object System.Drawing.Point(20, 22)
$labelTitulo.Size     = New-Object System.Drawing.Size(370, 28)
if (-not $redDisponible) {
    $labelTitulo.Text      = "Sin acceso a la planilla"
    $labelTitulo.ForeColor = [System.Drawing.Color]::FromArgb(180, 80, 0)
} elseif ($Segundo) {
    $labelTitulo.Text      = "Segundo aviso"
    $labelTitulo.ForeColor = [System.Drawing.Color]::FromArgb(190, 30, 30)
} else {
    $labelTitulo.Text      = "Completa las horas antes de irte"
    $labelTitulo.ForeColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
}
$form.Controls.Add($labelTitulo)

$labelSub           = New-Object System.Windows.Forms.Label
$labelSub.Font      = New-Object System.Drawing.Font("Segoe UI", 9)
$labelSub.Location  = New-Object System.Drawing.Point(20, 58)
$labelSub.Size      = New-Object System.Drawing.Size(370, 35)
$labelSub.ForeColor = [System.Drawing.Color]::FromArgb(90, 90, 90)
if (-not $redDisponible) {
    $labelSub.Text = "Son las $horaConfig. La red no está disponible — verificá la conexión."
} elseif ($Segundo) {
    $labelSub.Text = "Son las $horaConfig. Las horas del día siguen pendientes."
} else {
    $labelSub.Text = "Son las $horaConfig. Antes de cerrar, registra las tareas y horas del día."
}
$form.Controls.Add($labelSub)

$sep             = New-Object System.Windows.Forms.Panel
$sep.BackColor   = [System.Drawing.Color]::FromArgb(210, 210, 210)
$sep.Location    = New-Object System.Drawing.Point(20, 105)
$sep.Size        = New-Object System.Drawing.Size(370, 1)
$form.Controls.Add($sep)

$btnAbrir                          = New-Object System.Windows.Forms.Button
$btnAbrir.Text                     = "Abrir planilla"
$btnAbrir.Font                     = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$btnAbrir.Location                 = New-Object System.Drawing.Point(20, 120)
$btnAbrir.Size                     = New-Object System.Drawing.Size(180, 40)
$btnAbrir.BackColor                = [System.Drawing.Color]::FromArgb(0, 120, 212)
$btnAbrir.ForeColor                = [System.Drawing.Color]::White
$btnAbrir.FlatStyle                = "Flat"
$btnAbrir.FlatAppearance.BorderSize = 0
$btnAbrir.Cursor                   = "Hand"
$btnAbrir.Add_Click({
    if (-not (Test-Path (Split-Path $planillaPath))) {
        [System.Windows.Forms.MessageBox]::Show(
            "La red no está disponible.`n`nVerifica la VPN o la conexión antes de abrir la planilla.",
            "HITO",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
    } elseif (Test-Path $planillaPath) {
        Unregister-ScheduledTask -TaskName "HITO_Reintento" -Confirm:$false -ErrorAction SilentlyContinue
        Write-Log "Abrio planilla"
        $form.remove_FormClosing($handlerCierre)
        Start-Process $planillaPath
        $form.Close()
    } else {
        [System.Windows.Forms.MessageBox]::Show(
            "No encontramos la planilla en:`n$planillaPath`n`nVerifica la ruta en el configurador.",
            "HITO",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
    }
})
$form.Controls.Add($btnAbrir)

$btnListo                          = New-Object System.Windows.Forms.Button
$btnListo.Text                     = "Ya las completé"
$btnListo.Font                     = New-Object System.Drawing.Font("Segoe UI", 9)
$btnListo.Location                 = New-Object System.Drawing.Point(210, 120)
$btnListo.Size                     = New-Object System.Drawing.Size(180, 40)
$btnListo.BackColor                = [System.Drawing.Color]::FromArgb(225, 225, 225)
$btnListo.ForeColor                = [System.Drawing.Color]::FromArgb(30, 30, 30)
$btnListo.FlatStyle                = "Flat"
$btnListo.FlatAppearance.BorderSize = 0
$btnListo.Cursor                   = "Hand"
$btnListo.Add_Click({
    Unregister-ScheduledTask -TaskName "HITO_Reintento" -Confirm:$false -ErrorAction SilentlyContinue
    Write-Log "Completado"
    $form.remove_FormClosing($handlerCierre)
    $form.Close()
})
$form.Controls.Add($btnListo)

$handlerCierre = {
    Write-Log "Cerrado sin respuesta"
    # HITO_Reintento NO se cancela: el segundo aviso debe aparecer igual
}
$form.Add_FormClosing($handlerCierre)

$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()
