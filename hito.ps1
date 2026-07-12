#Requires -Version 5.1
# hito.ps1
# Muestra una ventana para recordar completar la planilla de horas.
# La configuración se lee desde config.json (misma carpeta que este script).
# Para cambiar la planilla, los días o la hora: Menú Inicio -> HITO
# Usar -Test para mostrar la ventana sin importar la hora (solo para pruebas).

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter', 'SinRed',
    Justification = 'Usado por los handlers de la ventana vía closure de scope.'
)]
param([switch]$Test, [switch]$Segundo, [switch]$SinRed)

$scriptDir  = $PSScriptRoot
$configFile = Join-Path $scriptDir "config.json"

. (Join-Path $scriptDir "constantes.ps1")
Import-Module (Join-Path $scriptDir "validaciones.psm1") -Force
Import-Module (Join-Path $scriptDir "configuracion.psm1") -Force

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

. (Join-Path $scriptDir "estilos.ps1")

function Show-AvisoConfiguracion {
    <#
    .SYNOPSIS
    Avisa que la configuración falta o no sirve, y abre el configurador
    para que el usuario la complete o corrija.
    #>
    param([string]$Mensaje, [string]$Titulo, [string]$Tipo = "Advertencia")
    [void](Show-DialogoHito -Mensaje $Mensaje -Titulo $Titulo -Tipo $Tipo)
    $lanzador     = Join-Path $scriptDir "lanzar.vbs"
    $configurador = Join-Path $scriptDir "configurar.ps1"
    if (Test-Path -LiteralPath $configurador) {
        Start-Process $HitoRutaWscript "`"$lanzador`" `"$configurador`""
    }
}

# --- Leer configuración ---
$cfg = Get-HitoConfig -RutaConfig $configFile
if (-not $cfg.Existe) {
    Show-AvisoConfiguracion -Titulo "Configuración pendiente" -Tipo "Info" `
        -Mensaje "No encontramos una planilla configurada.`nSe va a abrir el configurador ahora."
    exit
}
if (-not $cfg.Ok) {
    Show-AvisoConfiguracion -Titulo "Configuración dañada" `
        -Mensaje "No pudimos leer la configuración de HITO.`nSe va a abrir el configurador para volver a guardarla."
    exit
}
$planillaPath = $cfg.Planilla

$diaHoy = $HitoDias[(Get-Date).DayOfWeek.ToString()].Nombre
if (-not $diaHoy -and -not $Test) { exit }
if (-not $diaHoy) { $diaHoy = "Lunes" }   # valor de prueba para -Test en fin de semana
$horaConfig = $cfg.Horarios[$diaHoy]
if (-not $horaConfig -and -not $Test) { exit }
if (-not $horaConfig) { $horaConfig = $HitoHoraDefault }   # valor de prueba para -Test sin horario guardado
$horaConfig = ConvertTo-HoraNormalizada $horaConfig

# config.json se puede editar a mano: si el horario guardado no es una hora
# real, avisar y abrir el configurador en vez de morir en silencio (este
# proceso corre oculto, sin consola donde ver el error).
if (-not (Test-HoraValida $horaConfig).Valida) {
    Show-AvisoConfiguracion -Titulo "Horario inválido" `
        -Mensaje "El horario guardado para hoy no es válido.`nSe va a abrir el configurador para corregirlo."
    exit
}

# Si la PC estaba apagada a la hora configurada, mostrar solo si seguimos en el mismo día.
if (-not $Test) {
    $partes       = $horaConfig -split ":"
    $ahora        = Get-Date
    $horaEsperada = $ahora.Date.AddHours([int]$partes[0]).AddMinutes([int]$partes[1])
    if ($ahora -lt $horaEsperada) { exit }
}

function Test-RedDisponible {
    <#
    .SYNOPSIS
    Indica si la carpeta donde vive la planilla está accesible ahora
    (unidad de red conectada, VPN activa, archivo local, etc).
    #>
    param([string]$RutaPlanilla)
    $carpeta = Split-Path $RutaPlanilla
    if (-not $carpeta) { return $false }
    return Test-Path -LiteralPath $carpeta
}

# --- Log de actividad ---
$logDir       = Join-Path $scriptDir $HitoNombreCarpetaLogs
$logFile      = Join-Path $logDir $HitoNombreArchivoLog
$logFileViejo = Join-Path $scriptDir $HitoNombreArchivoLog
if (-not (Test-Path -LiteralPath $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
if ((Test-Path -LiteralPath $logFileViejo) -and -not (Test-Path -LiteralPath $logFile)) {
    # Migración única: instalaciones de versiones anteriores tenían el log
    # suelto junto a los scripts, no en su propia carpeta.
    Move-Item -Path $logFileViejo -Destination $logFile
}

$script:avisoActual = if ($Segundo) { 2 } else { 1 }   # 1 = primer aviso, 2 = segundo aviso

function Write-HitoLog {
    <#
    .SYNOPSIS
    Agrega una línea al log de actividad: fecha, día, número de aviso
    vigente ($avisoActual), estado y hora.
    #>
    param($estado)
    $avisoNum = if ($avisoActual -eq 2) { "2do aviso" } else { "1er aviso" }
    $fecha = Get-Date -Format "yyyy-MM-dd"
    $hora  = Get-Date -Format "HH:mm"
    $linea = "$fecha | $diaHoy | $avisoNum | $estado | $hora"
    if (Test-Path -LiteralPath $logFile) {
        # Append directo: reescribir el archivo completo arriesgaba perder
        # todo el historial ante un corte a mitad de escritura.
        Add-Content -Path $logFile -Value $linea -Encoding UTF8
    } else {
        $linea | Set-Content -Path $logFile -Encoding UTF8
    }
}

function Complete-Aviso {
    <#
    .SYNOPSIS
    Detiene la escalada a segundo aviso y registra el estado en el log.
    Lógica compartida por los dos botones de la ventana.
    #>
    param([string]$Estado)
    $timerSegundoAviso.Stop()
    Write-HitoLog $Estado
}

# --- Estado de red ---
# El primer chequeo es sincrónico (la ventana todavía no se mostró); los
# siguientes corren en un runspace aparte, porque Test-Path sobre una
# carpeta de red caída puede bloquear varios segundos y congelaría la
# ventana en cada chequeo periódico.
$script:redDisponible = if ($SinRed) { $false } else { Test-RedDisponible $planillaPath }
$script:chequeoRed    = $null

function Start-ChequeoRed {
    <#
    .SYNOPSIS
    Lanza en segundo plano el chequeo de acceso a la carpeta de la
    planilla. El timer de red recoge el resultado cuando termina.
    #>
    $instancia = [powershell]::Create()
    [void]$instancia.AddScript({
        param($Ruta)
        $carpeta = Split-Path $Ruta
        if (-not $carpeta) { return $false }
        Test-Path -LiteralPath $carpeta
    }).AddArgument($planillaPath)
    $script:chequeoRed = @{ Instancia = $instancia; Resultado = $instancia.BeginInvoke() }
}

# --- Ventana principal (popup: banda propia, centrado real, sin taskbar) ---
$anchoVentana = 420
$anchoTexto   = $anchoVentana - (2 * $HitoMargen)

$form = New-VentanaHito -Titulo "HITO" -Ancho $anchoVentana -Alto 266 -ScriptDir $scriptDir

$labelTitulo = New-LabelHito -Texto "" -X $HitoMargen -Y 58 -Ancho $anchoTexto -Alto 30 -Tamano 15 -Negrita -Centrado
$form.Controls.Add($labelTitulo)

$labelSub = New-LabelHito -Texto "" -X $HitoMargen -Y 92 -Ancho $anchoTexto -Alto 42 -Tamano 10 -Color $HitoColorTextoSuave -Centrado
$form.Controls.Add($labelSub)

$btnAbrir = New-BotonHito -Texto "&Abrir planilla" -X $HitoMargen -Y 150 -Ancho $anchoTexto -Alto 42 -Primario
$btnAbrir.Add_Click({
    if (-not (Test-RedDisponible $planillaPath)) {
        [void](Show-DialogoHito -Titulo "Red no disponible" -Tipo "Advertencia" `
            -Mensaje "La red no está disponible.`n`nVerificá la VPN o la conexión antes de abrir la planilla.")
    } elseif (Test-Path -LiteralPath $planillaPath) {
        # Si la ruta configurada no es una planilla de Excel, confirmar
        # antes de ejecutarla: evita abrir cualquier otra cosa con un clic.
        $extension = [System.IO.Path]::GetExtension($planillaPath).ToLowerInvariant()
        if ($HitoExtensionesPlanilla -notcontains $extension) {
            $abrirIgual = Show-DialogoHito -Titulo "Archivo no reconocido" -Tipo "Pregunta" -SiNo `
                -Mensaje "El archivo configurado no es una planilla de Excel:`n$planillaPath`n`n¿Abrirlo de todos modos?"
            if (-not $abrirIgual) { return }
        }
        Complete-Aviso "Abrió planilla"
        $form.remove_FormClosing($handlerCierre)
        Start-Process $planillaPath
        $form.Close()
    } else {
        [void](Show-DialogoHito -Titulo "Planilla no encontrada" -Tipo "Advertencia" `
            -Mensaje "No encontramos la planilla en:`n$planillaPath`n`nVerificá la ruta en el configurador.")
    }
})
$form.Controls.Add($btnAbrir)

$btnListo = New-BotonHito -Texto "&Ya las completé" -X $HitoMargen -Y 200 -Ancho $anchoTexto -Alto 42
$btnListo.Add_Click({
    Complete-Aviso "Completado"
    $form.remove_FormClosing($handlerCierre)
    $form.Close()
})
$form.Controls.Add($btnListo)

function Update-EstadoAviso {
    <#
    .SYNOPSIS
    Refleja en la ventana el último estado de red conocido: título,
    subtítulo y si el botón "Abrir planilla" puede usarse. Se llama al
    construir la ventana y cada vez que el chequeo periódico de red
    termina, para que una reconexión (VPN) la reactive sin cerrar el aviso.
    #>
    if (-not $script:redDisponible) {
        $labelTitulo.Text      = "Sin acceso a la planilla"
        $labelTitulo.ForeColor = $HitoColorAlerta
        $labelSub.Text         = "La red no está disponible — verificá la conexión antes de abrir la planilla."
    } elseif ($avisoActual -eq 2) {
        $labelTitulo.Text      = "Segundo aviso"
        $labelTitulo.ForeColor = $HitoColorUrgente
        $labelSub.Text         = "Las horas del día siguen pendientes."
    } else {
        $labelTitulo.Text      = "Completá las horas de hoy"
        $labelTitulo.ForeColor = $HitoColorTexto
        $labelSub.Text         = "Antes de cerrar, registrá las tareas y horas del día."
    }
    $btnAbrir.Enabled = $script:redDisponible
    if ($script:redDisponible) {
        $btnAbrir.BackColor = $HitoColorPrimario
        $btnAbrir.ForeColor = [System.Drawing.Color]::White
        $btnAbrir.Font                      = New-FuenteHito -Tamano 10 -Negrita
        $btnAbrir.FlatAppearance.BorderSize = 0
    } else {
        # Deshabilitado: apagado de verdad, no el color primario pleno
        # con el texto gris que deja WinForms por defecto. Sin caja
        # propia (fondo = el de la ventana) en vez de un gris sólido, con
        # un contorno del mismo tono que el secundario "Ya las completé"
        # — insinúa el botón sin llenarlo, y como el color del borde es
        # el mismo gris recesivo del secundario (no uno más oscuro ni de
        # acento) no compite en atención con ningún botón habilitado.
        $btnAbrir.BackColor = $HitoColorFondo
        $btnAbrir.ForeColor = $HitoColorTextoHint
        $btnAbrir.Font                       = New-FuenteHito -Tamano 10
        $btnAbrir.FlatAppearance.BorderSize  = 2
        $btnAbrir.FlatAppearance.BorderColor = $HitoColorSecundario
    }
}
Update-EstadoAviso

$timerRed = New-Object System.Windows.Forms.Timer
$timerRed.Interval = $HitoSegundosChequeoRed * 1000
$timerRed.Add_Tick({
    if ($SinRed) { return }
    if (-not $chequeoRed) { Start-ChequeoRed; return }
    if (-not $chequeoRed.Resultado.IsCompleted) { return }
    try {
        $valor = $chequeoRed.Instancia.EndInvoke($chequeoRed.Resultado) | Select-Object -First 1
        $script:redDisponible = [bool]$valor
    } catch {
        # Chequeo fallido: conservar el último estado de red conocido.
        Write-Verbose "Chequeo de red fallido: $_"
    }
    $chequeoRed.Instancia.Dispose()
    $script:chequeoRed = $null
    Update-EstadoAviso
    Start-ChequeoRed   # dejar el próximo chequeo ya en marcha
})
if (-not $SinRed) { Start-ChequeoRed }
$timerRed.Start()

$timerSegundoAviso = New-Object System.Windows.Forms.Timer
$timerSegundoAviso.Interval = $HitoMinutosReintento * 60 * 1000
$timerSegundoAviso.Add_Tick({
    $timerSegundoAviso.Stop()
    $script:avisoActual = 2
    Write-HitoLog "Mostrado"
    Update-EstadoAviso
    if (-not $form.Visible) {
        # SW_SHOWNOACTIVATE (4): reaparece adelante (es TopMost) pero sin
        # robar el foco — un Enter que el usuario estaba tecleando en otra
        # aplicación no debe caer sobre los botones del aviso.
        if ([HitoNativo].GetMethod("ShowWindow")) {
            [void][HitoNativo]::ShowWindow($form.Handle, 4)
        } else {
            $form.Show()
        }
    }
})
if (-not $Test) { $timerSegundoAviso.Start() }

$form.Add_FormClosed({
    $timerRed.Stop(); $timerRed.Dispose()
    $timerSegundoAviso.Stop(); $timerSegundoAviso.Dispose()
    if ($chequeoRed) {
        $chequeoRed.Instancia.Dispose()
        $script:chequeoRed = $null
    }
})

$handlerCierre = {
    param($ventana, $evento)
    Write-HitoLog "Cerrado sin respuesta"
    if ($avisoActual -eq 1) {
        # Ocultar en vez de cerrar: el timer de segundo aviso sigue
        # corriendo y va a reactivar esta misma ventana más tarde.
        $evento.Cancel = $true
        $ventana.Hide()
    }
}
$form.Add_FormClosing($handlerCierre)

$form.Add_Shown({ $form.Activate() })
# Application.Run (no ShowDialog): con ShowDialog, ocultar la ventana desde
# FormClosing con $e.Cancel = $true igual termina el modal loop. Con
# Application.Run, Hide() de verdad la oculta y el proceso sigue vivo hasta
# que la ventana se cierra en serio (ver Timer de segundo aviso, más arriba).
[System.Windows.Forms.Application]::Run($form)
