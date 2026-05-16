#Requires -Version 5.1
# configurar.ps1 — v1.0.0
# Permite seleccionar la planilla y configurar el horario del recordatorio.
# Accesible desde: Menu Inicio -> HITO -> Configuracion

$scriptDir = $PSScriptRoot
$configFile = Join-Path $scriptDir "config.json"

$tareasScheduled = [ordered]@{
    Lunes     = "HITO_Lun"
    Martes    = "HITO_Mar"
    Miercoles = "HITO_Mie"
    Jueves    = "HITO_Jue"
    Viernes   = "HITO_Vie"
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Leer valores actuales
$valorPlanilla = ""
$horasPorDia   = [ordered]@{ Lunes="17:30"; Martes="17:30"; Miercoles="17:30"; Jueves="17:30"; Viernes="17:30" }
$displayDia    = @{ Lunes="Lunes"; Martes="Martes"; Miercoles="Miércoles"; Jueves="Jueves"; Viernes="Viernes" }

if (Test-Path $configFile) {
    $config = Get-Content $configFile -Encoding UTF8 -Raw | ConvertFrom-Json
    $valorPlanilla = if ($config.planilla) { $config.planilla.Trim() } else { "" }
    if ($config.PSObject.Properties['horarios']) {
        foreach ($dia in @($horasPorDia.Keys)) {
            $val = $config.horarios.$dia
            if ($val) { $horasPorDia[$dia] = $val.Trim() }
        }
    }
}

# --- Formulario ---
$form                 = New-Object System.Windows.Forms.Form
$form.Text            = "HITO – Configuración"
$form.Size            = New-Object System.Drawing.Size(460, 375)
$form.StartPosition   = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox     = $false
$form.MinimizeBox     = $false
$form.TopMost         = $true
$form.BackColor       = [System.Drawing.Color]::FromArgb(245, 245, 245)
$iconPath = Join-Path $scriptDir "hito.ico"
if (Test-Path $iconPath) { $form.Icon = New-Object System.Drawing.Icon($iconPath) }

$labelTitulo           = New-Object System.Windows.Forms.Label
$labelTitulo.Text      = "Configuración"
$labelTitulo.Font      = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$labelTitulo.Location  = New-Object System.Drawing.Point(20, 20)
$labelTitulo.Size      = New-Object System.Drawing.Size(410, 28)
$labelTitulo.ForeColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$form.Controls.Add($labelTitulo)

# -- Seccion Planilla --
$labelNombre           = New-Object System.Windows.Forms.Label
$labelNombre.Text      = "Planilla de horas"
$labelNombre.Font      = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$labelNombre.Location  = New-Object System.Drawing.Point(20, 60)
$labelNombre.Size      = New-Object System.Drawing.Size(410, 18)
$labelNombre.ForeColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$form.Controls.Add($labelNombre)

$textBoxPlanilla           = New-Object System.Windows.Forms.TextBox
$textBoxPlanilla.Font      = New-Object System.Drawing.Font("Segoe UI", 9)
$textBoxPlanilla.Location  = New-Object System.Drawing.Point(20, 82)
$textBoxPlanilla.Size      = New-Object System.Drawing.Size(318, 24)
$textBoxPlanilla.Text      = $valorPlanilla
$textBoxPlanilla.ReadOnly  = $true
$textBoxPlanilla.BackColor = [System.Drawing.Color]::White
$textBoxPlanilla.ForeColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$form.Controls.Add($textBoxPlanilla)

$btnExaminar                          = New-Object System.Windows.Forms.Button
$btnExaminar.Text                     = "Examinar..."
$btnExaminar.Font                     = New-Object System.Drawing.Font("Segoe UI", 9)
$btnExaminar.Location                 = New-Object System.Drawing.Point(346, 80)
$btnExaminar.Size                     = New-Object System.Drawing.Size(84, 26)
$btnExaminar.BackColor                = [System.Drawing.Color]::FromArgb(225, 225, 225)
$btnExaminar.ForeColor                = [System.Drawing.Color]::FromArgb(30, 30, 30)
$btnExaminar.FlatStyle                = "Flat"
$btnExaminar.FlatAppearance.BorderSize = 0
$btnExaminar.Cursor                   = "Hand"
$btnExaminar.Add_Click({
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title  = "Seleccionar planilla de horas"
    $dialog.Filter = "Planillas Excel (*.xlsm;*.xlsx;*.xls)|*.xlsm;*.xlsx;*.xls|Todos los archivos (*.*)|*.*"
    $rutaActual = $textBoxPlanilla.Text.Trim()
    if ($rutaActual) {
        $dirActual = Split-Path $rutaActual
        if (Test-Path $dirActual) { $dialog.InitialDirectory = $dirActual }
    }
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $textBoxPlanilla.Text           = $dialog.FileName
        $textBoxPlanilla.SelectionStart = $textBoxPlanilla.Text.Length
    }
})
$form.Controls.Add($btnExaminar)

# -- Seccion Horarios --
$labelHorarios           = New-Object System.Windows.Forms.Label
$labelHorarios.Text      = "Hora del recordatorio"
$labelHorarios.Font      = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$labelHorarios.Location  = New-Object System.Drawing.Point(20, 120)
$labelHorarios.Size      = New-Object System.Drawing.Size(410, 18)
$labelHorarios.ForeColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$form.Controls.Add($labelHorarios)

$checkMismo          = New-Object System.Windows.Forms.CheckBox
$checkMismo.Text     = "Mismo horario todos los días"
$checkMismo.Font     = New-Object System.Drawing.Font("Segoe UI", 9)
$checkMismo.Location = New-Object System.Drawing.Point(20, 143)
$checkMismo.Size     = New-Object System.Drawing.Size(250, 20)
$checkMismo.ForeColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$form.Controls.Add($checkMismo)

$colorDeshabilitado = [System.Drawing.Color]::FromArgb(220, 220, 220)
$colorHabilitado    = [System.Drawing.Color]::White

function Test-HoraValida {
    param($hora, $nombreDia)
    if ($hora -notmatch "^\d{1,2}:\d{2}$") {
        [void][System.Windows.Forms.MessageBox]::Show(
            "El horario del $nombreDia no es válido.`nUsa el formato HH:MM (ej: 17:30).",
            "Hora incorrecta",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning)
        return $false
    }
    $p = $hora -split ":"
    if ([int]$p[0] -gt 23 -or [int]$p[1] -gt 59) {
        [void][System.Windows.Forms.MessageBox]::Show(
            "El horario del $nombreDia está fuera de rango.`nHoras: 0-23, Minutos: 0-59.",
            "Hora incorrecta",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning)
        return $false
    }
    return $true
}

function Test-Inputs {
    param($rutaPlanilla, $horas)
    if ($rutaPlanilla -eq "") {
        [void][System.Windows.Forms.MessageBox]::Show(
            "Selecciona tu planilla con el botón Examinar.",
            "Falta la planilla",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning)
        return $null
    }
    $horasNorm = [ordered]@{}
    foreach ($dia in $horas.Keys) {
        $hora = $horas[$dia]
        if (-not (Test-HoraValida $hora $displayDia[$dia])) { return $null }
        $p = $hora -split ":"
        $horasNorm[$dia] = "{0:D2}:{1:D2}" -f [int]$p[0], [int]$p[1]
    }
    return $horasNorm
}

function Save-Config {
    param($rutaPlanilla, $horasNorm)
    [ordered]@{ planilla = $rutaPlanilla; horarios = $horasNorm } |
        ConvertTo-Json -Depth 3 | Set-Content -Path $configFile -Encoding UTF8
    return (Test-Path $rutaPlanilla)
}

function Update-ScheduledTasks {
    param($horasNorm)
    $diasSemana    = [ordered]@{ Lunes='Monday'; Martes='Tuesday'; Miercoles='Wednesday'; Jueves='Thursday'; Viernes='Friday' }
    $erroresTareas = @()
    foreach ($dia in @($tareasScheduled.Keys)) {
        try {
            $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $diasSemana[$dia] -At $horasNorm[$dia]
            Set-ScheduledTask -TaskName $tareasScheduled[$dia] -Trigger $trigger | Out-Null
        } catch {
            $erroresTareas += $dia
        }
    }
    return $erroresTareas
}

function New-LabelDia($texto, $x, $y) {
    $l            = New-Object System.Windows.Forms.Label
    $l.Text       = $texto
    $l.Font       = New-Object System.Drawing.Font("Segoe UI", 9)
    $l.Location   = New-Object System.Drawing.Point($x, ($y + 4))
    $l.Size       = New-Object System.Drawing.Size(85, 18)
    $l.ForeColor  = [System.Drawing.Color]::FromArgb(30, 30, 30)
    return $l
}

function New-TextBoxHora($valor, $x, $y) {
    $t            = New-Object System.Windows.Forms.TextBox
    $t.Font       = New-Object System.Drawing.Font("Segoe UI", 10)
    $t.Location   = New-Object System.Drawing.Point($x, $y)
    $t.Size       = New-Object System.Drawing.Size(65, 26)
    $t.MaxLength  = 5
    $t.Text       = $valor
    $t.ForeColor  = [System.Drawing.Color]::FromArgb(30, 30, 30)
    return $t
}

$form.Controls.Add((New-LabelDia "Lunes:"      20  172))
$form.Controls.Add((New-LabelDia "Martes:"    220  172))
$form.Controls.Add((New-LabelDia "Miércoles:"  20  204))
$form.Controls.Add((New-LabelDia "Jueves:"    220  204))
$form.Controls.Add((New-LabelDia "Viernes:"    20  236))

$tbLun = New-TextBoxHora $horasPorDia["Lunes"]     110 172
$tbMar = New-TextBoxHora $horasPorDia["Martes"]    310 172
$tbMie = New-TextBoxHora $horasPorDia["Miercoles"] 110 204
$tbJue = New-TextBoxHora $horasPorDia["Jueves"]    310 204
$tbVie = New-TextBoxHora $horasPorDia["Viernes"]   110 236

$form.Controls.Add($tbLun)
$form.Controls.Add($tbMar)
$form.Controls.Add($tbMie)
$form.Controls.Add($tbJue)
$form.Controls.Add($tbVie)

$labelFormatHora           = New-Object System.Windows.Forms.Label
$labelFormatHora.Text      = "Formato 24 hs. Ej: 17:30"
$labelFormatHora.Font      = New-Object System.Drawing.Font("Segoe UI", 8)
$labelFormatHora.Location  = New-Object System.Drawing.Point(220, 241)
$labelFormatHora.Size      = New-Object System.Drawing.Size(200, 16)
$labelFormatHora.ForeColor = [System.Drawing.Color]::FromArgb(150, 150, 150)
$form.Controls.Add($labelFormatHora)

$tbDependientes = @($tbMar, $tbMie, $tbJue, $tbVie)

$checkMismo.Add_CheckedChanged({
    if ($checkMismo.Checked) {
        foreach ($tb in $tbDependientes) {
            $tb.Text      = $tbLun.Text
            $tb.Enabled   = $false
            $tb.BackColor = $colorDeshabilitado
        }
    } else {
        foreach ($tb in $tbDependientes) {
            $tb.Enabled   = $true
            $tb.BackColor = $colorHabilitado
        }
    }
})

$tbLun.Add_TextChanged({
    if ($checkMismo.Checked) {
        foreach ($tb in $tbDependientes) { $tb.Text = $tbLun.Text }
    }
})

$todosIguales = ($horasPorDia["Lunes"] -eq $horasPorDia["Martes"]) -and
                ($horasPorDia["Lunes"] -eq $horasPorDia["Miercoles"]) -and
                ($horasPorDia["Lunes"] -eq $horasPorDia["Jueves"]) -and
                ($horasPorDia["Lunes"] -eq $horasPorDia["Viernes"])
$checkMismo.Checked = $todosIguales
if ($todosIguales) {
    foreach ($tb in $tbDependientes) {
        $tb.Enabled   = $false
        $tb.BackColor = $colorDeshabilitado
    }
}

# -- Separador y botones --
$sep             = New-Object System.Windows.Forms.Panel
$sep.BackColor   = [System.Drawing.Color]::FromArgb(210, 210, 210)
$sep.Location    = New-Object System.Drawing.Point(20, 270)
$sep.Size        = New-Object System.Drawing.Size(410, 1)
$form.Controls.Add($sep)

$btnGuardar                          = New-Object System.Windows.Forms.Button
$btnGuardar.Text                     = "Guardar"
$btnGuardar.Font                     = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$btnGuardar.Location                 = New-Object System.Drawing.Point(20, 284)
$btnGuardar.Size                     = New-Object System.Drawing.Size(195, 40)
$btnGuardar.BackColor                = [System.Drawing.Color]::FromArgb(0, 120, 212)
$btnGuardar.ForeColor                = [System.Drawing.Color]::White
$btnGuardar.FlatStyle                = "Flat"
$btnGuardar.FlatAppearance.BorderSize = 0
$btnGuardar.Cursor                   = "Hand"
$btnGuardar.Add_Click({
    $rutaPlanilla = $textBoxPlanilla.Text.Trim()

    # Normalizar punto o coma como separador (10.30 → 10:30)
    $tbLun.Text = $tbLun.Text.Trim() -replace '[.,]', ':'
    if (-not $checkMismo.Checked) {
        foreach ($tb in $tbDependientes) {
            $tb.Text = $tb.Text.Trim() -replace '[.,]', ':'
        }
    }
    if ($checkMismo.Checked) {
        foreach ($tb in $tbDependientes) { $tb.Text = $tbLun.Text }
    }

    $horas = [ordered]@{
        Lunes     = $tbLun.Text
        Martes    = $tbMar.Text
        Miercoles = $tbMie.Text
        Jueves    = $tbJue.Text
        Viernes   = $tbVie.Text
    }
    $horasNorm = Test-Inputs $rutaPlanilla $horas
    if ($null -eq $horasNorm) {
        # Restaurar celdas inválidas al último valor guardado válido
        $tbRef = [ordered]@{ Lunes=$tbLun; Martes=$tbMar; Miercoles=$tbMie; Jueves=$tbJue; Viernes=$tbVie }
        foreach ($dia in $tbRef.Keys) {
            $h = $tbRef[$dia].Text
            $inv = $h -notmatch "^\d{1,2}:\d{2}$"
            if (-not $inv) {
                $p = $h -split ':'
                $inv = [int]$p[0] -gt 23 -or [int]$p[1] -gt 59
            }
            if ($inv) { $tbRef[$dia].Text = $horasPorDia[$dia] }
        }
        if ($checkMismo.Checked) {
            foreach ($tb in $tbDependientes) { $tb.Text = $tbLun.Text }
        }
        return
    }
    $planillaOk    = Save-Config $rutaPlanilla $horasNorm
    $erroresTareas = Update-ScheduledTasks $horasNorm

    $avisos = @()
    if (-not $planillaOk) {
        $avisos += "No encontramos la planilla en:`n$rutaPlanilla`n`nVerifica que la red esté disponible."
    }
    if ($erroresTareas.Count -gt 0) {
        $avisos += "No se pudieron actualizar las tareas de: $(($erroresTareas | ForEach-Object { $displayDia[$_] }) -join ', ').`n`nVolviendo a ejecutar el instalador se soluciona."
    }

    if ($avisos.Count -gt 0) {
        [System.Windows.Forms.MessageBox]::Show(
            ($avisos -join "`n`n"),
            "Guardado con avisos",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning)
    } else {
        [System.Windows.Forms.MessageBox]::Show(
            "Todo listo. Los recordatorios están configurados.",
            "Guardado",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information)
    }
    $form.Close()
})
$form.Controls.Add($btnGuardar)

$btnCancelar                          = New-Object System.Windows.Forms.Button
$btnCancelar.Text                     = "Cancelar"
$btnCancelar.Font                     = New-Object System.Drawing.Font("Segoe UI", 9)
$btnCancelar.Location                 = New-Object System.Drawing.Point(225, 284)
$btnCancelar.Size                     = New-Object System.Drawing.Size(205, 40)
$btnCancelar.BackColor                = [System.Drawing.Color]::FromArgb(225, 225, 225)
$btnCancelar.ForeColor                = [System.Drawing.Color]::FromArgb(30, 30, 30)
$btnCancelar.FlatStyle                = "Flat"
$btnCancelar.FlatAppearance.BorderSize = 0
$btnCancelar.Cursor                   = "Hand"
$btnCancelar.Add_Click({ $form.Close() })
$form.Controls.Add($btnCancelar)

$form.Add_Shown({ $textBoxPlanilla.SelectionStart = $textBoxPlanilla.Text.Length })
[void]$form.ShowDialog()
