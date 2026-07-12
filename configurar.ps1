#Requires -Version 5.1
# configurar.ps1
# Ventana principal de HITO: selecciona la planilla, configura qué días
# tienen recordatorio y a qué hora, y da acceso a "Acerca de".
# Accesible desde: Menú Inicio -> HITO

$scriptDir  = $PSScriptRoot
$configFile = Join-Path $scriptDir "config.json"

. (Join-Path $scriptDir "constantes.ps1")
. (Join-Path $scriptDir "sincronizar_horarios.ps1")
. (Join-Path $scriptDir "acerca_de.ps1")
Import-Module (Join-Path $scriptDir "validaciones.psm1") -Force
Import-Module (Join-Path $scriptDir "configuracion.psm1") -Force

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

. (Join-Path $scriptDir "estilos.ps1")

$displayDia = @{
    Lunes = "Lunes"; Martes = "Martes"; Miercoles = "Miércoles"; Jueves = "Jueves"
    Viernes = "Viernes"; Sabado = "Sábado"; Domingo = "Domingo"
}

# Leer valores actuales: por defecto, Lunes a Viernes activos a la hora
# por defecto; si hay config.json previo, se reemplaza por lo guardado.
$valorPlanilla = ""
$horasPorDia   = [ordered]@{}
$diasActivos   = [ordered]@{}
foreach ($dia in $HitoDias.Keys) {
    $nombre = $HitoDias[$dia].Nombre
    $horasPorDia[$nombre] = $HitoHoraDefault
    $diasActivos[$nombre] = $HitoDiasLaborables -contains $nombre
}

$cfg = Get-HitoConfig -RutaConfig $configFile
if ($cfg.Existe -and -not $cfg.Ok) {
    [void](Show-DialogoHito -Titulo "Configuración dañada" -Tipo "Advertencia" `
        -Mensaje "No pudimos leer la configuración guardada, así que se muestran los valores por defecto.`nAl guardar, se reemplaza por una configuración nueva.")
} elseif ($cfg.Existe) {
    $valorPlanilla = $cfg.Planilla
    if ($cfg.Horarios.Count -gt 0) {
        foreach ($nombre in @($diasActivos.Keys)) { $diasActivos[$nombre] = $false }
        foreach ($nombre in $cfg.Horarios.Keys) {
            if ($horasPorDia.Contains($nombre)) {
                $horasPorDia[$nombre] = ConvertTo-HoraNormalizada $cfg.Horarios[$nombre]
                $diasActivos[$nombre] = $true
            }
        }
    }
}

# --- Formulario ---
# Todas las posiciones se calculan contra ClientSize (área útil real) con
# margen uniforme, para que el margen derecho sea igual al izquierdo.
$anchoVentana   = $HitoAnchoVentanaPrincipal
$anchoContenido = $anchoVentana - (2 * $HitoMargen)

# Conserva el botón en la barra de tareas: es la ventana principal del
# software, no un aviso transitorio.
$form = New-VentanaHito -Titulo "HITO" -Ancho $anchoVentana -Alto 554 -ScriptDir $scriptDir -EnBarraTareas

$form.Controls.Add((New-LabelHito -Texto "Tus recordatorios" -X $HitoMargen -Y 52 -Ancho 250 -Alto 30 -Tamano 14 -Negrita))

$btnAcercaDe = New-BotonHito -Texto "ⓘ &Acerca de" -X ($anchoVentana - $HitoMargen - 112) -Y 52 -Ancho 112 -Alto 30
$btnAcercaDe.Add_Click({ Show-VentanaAcercaDe -ScriptDir $scriptDir -Owner $form })
$form.Controls.Add($btnAcercaDe)

# -- Sección Planilla --
$form.Controls.Add((New-LabelHito -Texto "PLANILLA DE HORAS" -X $HitoMargen -Y 98 -Ancho $anchoContenido -Alto 16 -Negrita -Color $HitoColorTextoSuave))

$textBoxPlanilla           = New-Object System.Windows.Forms.TextBox
$textBoxPlanilla.Font      = New-FuenteHito
$textBoxPlanilla.Location  = New-Object System.Drawing.Point($HitoMargen, 121)
$textBoxPlanilla.Size      = New-Object System.Drawing.Size(312, 24)
$textBoxPlanilla.Text      = $valorPlanilla
$textBoxPlanilla.BackColor = [System.Drawing.Color]::White
$textBoxPlanilla.ForeColor = $HitoColorTexto
$form.Controls.Add($textBoxPlanilla)

$btnExaminar = New-BotonHito -Texto "&Examinar..." -X ($anchoVentana - $HitoMargen - 90) -Y 118 -Ancho 90 -Alto 30
$btnExaminar.Add_Click({
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title  = "Seleccionar planilla de horas"
    $dialog.Filter = "Planillas Excel (*.xlsm;*.xlsx;*.xls)|*.xlsm;*.xlsx;*.xls|Todos los archivos (*.*)|*.*"
    $rutaActual = $textBoxPlanilla.Text.Trim()
    if ($rutaActual) {
        $dirActual = Split-Path $rutaActual
        if (Test-Path -LiteralPath $dirActual) { $dialog.InitialDirectory = $dirActual }
    }
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $textBoxPlanilla.Text           = $dialog.FileName
        $textBoxPlanilla.SelectionStart = $textBoxPlanilla.Text.Length
    }
})
$form.Controls.Add($btnExaminar)

# -- Sección Días y horarios --
$form.Controls.Add((New-LabelHito -Texto "DÍAS Y HORARIOS" -X $HitoMargen -Y 160 -Ancho $anchoContenido -Alto 16 -Negrita -Color $HitoColorTextoSuave))

function Save-Config {
    <#
    .SYNOPSIS
    Guarda la ruta de la planilla y los horarios normalizados en
    config.json. Escribe a un archivo temporal y recién después lo
    renombra, para que un corte a mitad de escritura no deje la
    configuración truncada.
    #>
    param([string]$RutaPlanilla, $HorasNorm)
    $temporal = "$configFile.tmp"
    [ordered]@{ planilla = $RutaPlanilla; horarios = $HorasNorm } |
        ConvertTo-Json -Depth 3 | Set-Content -Path $temporal -Encoding UTF8
    Move-Item -Path $temporal -Destination $configFile -Force
}

function New-ToggleDia($texto, $checked, $x, $y) {
    <#
    .SYNOPSIS
    Crea el botón de día (checkbox con apariencia de botón): al activarlo
    se desbloquea el campo de hora de su fila.
    #>
    $c            = New-Object System.Windows.Forms.CheckBox
    $c.Appearance = [System.Windows.Forms.Appearance]::Button
    $c.FlatStyle  = "Flat"
    $c.FlatAppearance.BorderSize = 0
    $c.Text       = $texto
    $c.Font       = New-FuenteHito -Tamano 10
    $c.TextAlign  = [System.Drawing.ContentAlignment]::MiddleLeft
    $c.Padding    = New-Object System.Windows.Forms.Padding(12, 0, 0, 0)
    $c.Location   = New-Object System.Drawing.Point($x, $y)
    $c.Size       = New-Object System.Drawing.Size(170, 32)
    $c.Cursor     = "Hand"
    $c.Checked    = $checked
    return $c
}

function New-TextBoxHora($valor, $x, $y) {
    <#
    .SYNOPSIS
    Crea el campo de hora de una fila de días.
    #>
    $t           = New-Object System.Windows.Forms.TextBox
    $t.Font      = New-FuenteHito -Tamano 10
    $t.Location  = New-Object System.Drawing.Point($x, $y)
    $t.Size      = New-Object System.Drawing.Size(70, 26)
    $t.MaxLength = 5
    $t.Text      = $valor
    $t.TextAlign = [System.Windows.Forms.HorizontalAlignment]::Center
    $t.ForeColor = $HitoColorTexto
    return $t
}

# Nombre interno -> controles de su fila (Check, Hora)
$controlsFila = [ordered]@{}

function Update-EstadoFilaDia([string]$Nombre) {
    <#
    .SYNOPSIS
    Refleja el estado de una fila: día activo = botón lleno con el color
    primario y campo de hora habilitado; inactivo = botón gris y campo
    bloqueado.
    #>
    $fila   = $controlsFila[$Nombre]
    $activo = $fila.Check.Checked

    $fila.Hora.Enabled   = $activo
    $fila.Hora.BackColor = if ($activo) { [System.Drawing.Color]::White }
                           else         { $HitoColorCampoInactivo }

    # CheckedBackColor debe acompañar a BackColor: en el estado tildado,
    # WinForms pinta con CheckedBackColor y dejaría un celeste lavado.
    if ($activo) {
        $fila.Check.BackColor = $HitoColorPrimario
        $fila.Check.ForeColor = [System.Drawing.Color]::White
        $fila.Check.FlatAppearance.CheckedBackColor   = $HitoColorPrimario
        $fila.Check.FlatAppearance.MouseOverBackColor = $HitoColorPrimarioHover
        $fila.Check.FlatAppearance.MouseDownBackColor = $HitoColorPrimarioDown
    } else {
        $fila.Check.BackColor = $HitoColorSecundario
        $fila.Check.ForeColor = $HitoColorTexto
        $fila.Check.FlatAppearance.CheckedBackColor   = $HitoColorSecundario
        $fila.Check.FlatAppearance.MouseOverBackColor = $HitoColorSecundarioHover
        $fila.Check.FlatAppearance.MouseDownBackColor = $HitoColorSecundarioDown
    }
}

# Una fila por día: botón de día + campo de hora al lado.
$filaBaseY = 182
$filaPaso  = 38
$xHora     = $HitoMargen + 170 + 12
$i = 0
foreach ($dia in $HitoDias.Keys) {
    $nombre = $HitoDias[$dia].Nombre
    $y      = $filaBaseY + ($i * $filaPaso)

    $check = New-ToggleDia $displayDia[$nombre] $diasActivos[$nombre] $HitoMargen $y
    $hora  = New-TextBoxHora $horasPorDia[$nombre] $xHora ($y + 3)
    $form.Controls.Add($check)
    $form.Controls.Add($hora)
    $controlsFila[$nombre] = @{ Check = $check; Hora = $hora }
    $check.Tag = $nombre
    $check.Add_CheckedChanged({ Update-EstadoFilaDia $this.Tag })
    $i++
}
foreach ($nombre in $controlsFila.Keys) { Update-EstadoFilaDia $nombre }

$form.Controls.Add((New-LabelHito -Texto "Formato 24 hs. Se acepta : . o , como separador (ej: 17:30)." `
    -X $HitoMargen -Y 450 -Ancho $anchoContenido -Alto 16 -Color $HitoColorTextoHint))

# -- Separador y botones (confirmar abajo a la derecha) --
$form.Controls.Add((New-SeparadorHito -X $HitoMargen -Y 476 -Ancho $anchoContenido))

function Get-HorasActivas {
    <#
    .SYNOPSIS
    Normaliza el texto de hora de todas las filas (punto o coma pasan a
    dos puntos, se recortan espacios) y devuelve el hashtable ordenado
    día interno -> hora de los días que están activos.
    #>
    foreach ($nombre in $controlsFila.Keys) {
        $fila = $controlsFila[$nombre]
        $fila.Hora.Text = ConvertTo-HoraNormalizada $fila.Hora.Text
    }
    $horas = [ordered]@{}
    foreach ($nombre in $controlsFila.Keys) {
        if ($controlsFila[$nombre].Check.Checked) {
            $horas[$nombre] = $controlsFila[$nombre].Hora.Text
        }
    }
    return $horas
}

function Show-AvisoValidacion {
    <#
    .SYNOPSIS
    Muestra el mensaje correspondiente a una validación fallida de
    Test-Inputs y, si el problema es una hora, restaura los campos
    inválidos al último valor guardado válido.
    #>
    param($Resultado)
    switch ($Resultado.MotivoTipo) {
        "planilla" {
            [void](Show-DialogoHito -Titulo "Falta la planilla" -Tipo "Advertencia" `
                -Mensaje "Seleccioná tu planilla con el botón Examinar.")
        }
        "sin_dias" {
            [void](Show-DialogoHito -Titulo "Sin días activos" -Tipo "Advertencia" `
                -Mensaje "Activá al menos un día para el recordatorio.")
        }
        "hora" {
            if ($Resultado.Motivo -eq "formato") {
                [void](Show-DialogoHito -Titulo "Hora incorrecta" -Tipo "Advertencia" `
                    -Mensaje "El horario del $($displayDia[$Resultado.Dia]) no es válido.`nUsá el formato HH:MM (ej: 17:30).")
            } else {
                [void](Show-DialogoHito -Titulo "Hora incorrecta" -Tipo "Advertencia" `
                    -Mensaje "El horario del $($displayDia[$Resultado.Dia]) está fuera de rango.`nHoras: 0-23, Minutos: 0-59.")
            }
            # Restaurar celdas inválidas al último valor guardado válido
            foreach ($nombre in $controlsFila.Keys) {
                if (-not (Test-HoraValida $controlsFila[$nombre].Hora.Text).Valida) {
                    $controlsFila[$nombre].Hora.Text = $horasPorDia[$nombre]
                }
            }
        }
    }
}

function Set-FormularioOcupado {
    <#
    .SYNOPSIS
    Muestra u oculta el estado "Guardando..." (botones deshabilitados y
    cursor de espera) mientras se sincronizan las tareas programadas,
    que puede tardar varios segundos en algunos equipos.
    #>
    param([bool]$Ocupado)
    $btnGuardar.Enabled  = -not $Ocupado
    $btnCancelar.Enabled = -not $Ocupado
    $btnGuardar.Text     = if ($Ocupado) { "Guardando..." } else { $script:textoBotonGuardar }
    $form.Cursor         = if ($Ocupado) { [System.Windows.Forms.Cursors]::WaitCursor }
                           else          { [System.Windows.Forms.Cursors]::Default }
    if ($Ocupado) {
        $form.Refresh()
        [System.Windows.Forms.Application]::DoEvents()
    }
}

$btnGuardar = New-BotonHito -Texto "&Guardar" -X ($anchoVentana - $HitoMargen - 150) -Y 490 -Ancho 150 -Alto 40 -Primario
$script:textoBotonGuardar = $btnGuardar.Text
$btnGuardar.Add_Click({
    $rutaPlanilla = $textBoxPlanilla.Text.Trim()
    $horas        = Get-HorasActivas
    $resultado    = Test-Inputs -RutaPlanilla $rutaPlanilla -Horas $horas

    if (-not $resultado.Ok) {
        Show-AvisoValidacion $resultado
        return
    }

    Set-FormularioOcupado $true
    Save-Config -RutaPlanilla $rutaPlanilla -HorasNorm $resultado.HorasNormalizadas
    $planillaOk    = Test-Path -LiteralPath $rutaPlanilla
    $erroresTareas = Sync-TareasHorario -HorariosActivos $resultado.HorasNormalizadas -ScriptDir $scriptDir
    Set-FormularioOcupado $false

    $avisos = @()
    if (-not $planillaOk) {
        $avisos += "No encontramos la planilla en:`n$rutaPlanilla`n`nVerificá que la red esté disponible."
    } elseif ($HitoExtensionesPlanilla -notcontains [System.IO.Path]::GetExtension($rutaPlanilla).ToLowerInvariant()) {
        $avisos += "El archivo elegido no tiene extensión de planilla de Excel (.xls, .xlsx, .xlsm).`nSe guardó igual, pero verificá que sea el archivo correcto."
    }
    if ($erroresTareas.Count -gt 0) {
        $avisos += "No se pudieron actualizar las tareas de: $(($erroresTareas | ForEach-Object { $displayDia[$_] }) -join ', ').`n`nVolviendo a ejecutar el instalador se soluciona."
    }

    if ($avisos.Count -gt 0) {
        [void](Show-DialogoHito -Titulo "Guardado con avisos" -Tipo "Advertencia" `
            -Mensaje ($avisos -join "`n`n"))
    } else {
        [void](Show-DialogoHito -Titulo "Todo listo" -Tipo "Info" `
            -Mensaje "Los recordatorios están configurados.")
    }
    $form.Close()
})
$form.Controls.Add($btnGuardar)

$btnCancelar = New-BotonHito -Texto "&Cancelar" -X ($anchoVentana - $HitoMargen - 150 - 10 - 110) -Y 490 -Ancho 110 -Alto 40
$btnCancelar.Add_Click({ $form.Close() })
$form.Controls.Add($btnCancelar)

$form.Add_Shown({ $textBoxPlanilla.SelectionStart = $textBoxPlanilla.Text.Length })
[void]$form.ShowDialog()
