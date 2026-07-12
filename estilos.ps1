#Requires -Version 5.1
# estilos.ps1
# Paleta de colores, tipografía y fábricas de controles compartidas por las
# ventanas de HITO (hito.ps1, configurar.ps1, acerca_de.ps1, desinstalar.ps1),
# para que un ajuste de diseño se haga en un solo lugar.
# Requiere que System.Windows.Forms y System.Drawing ya estén cargados
# (Add-Type del script llamador) y constantes.ps1 ya dot-sourceado antes
# del dot-source de este archivo.

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', '',
    Justification = 'Variables usadas por los scripts que dot-sourcean este archivo.'
)]
param()

# Funciones nativas de Windows usadas por las ventanas sin barra de título:
# - DwmSetWindowAttribute: pedirle a Windows 11 que no redondee las esquinas.
# - ReleaseCapture + SendMessage: arrastrar la ventana desde la banda propia.
if (-not ([System.Management.Automation.PSTypeName]'HitoNativo').Type) {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public static class HitoNativo
{
    [DllImport("dwmapi.dll", PreserveSig = true)]
    public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);

    [DllImport("user32.dll")]
    public static extern bool ReleaseCapture();

    [DllImport("user32.dll")]
    public static extern IntPtr SendMessage(IntPtr hWnd, int msg, int wParam, int lParam);

    [DllImport("shell32.dll", CharSet = CharSet.Unicode, PreserveSig = true)]
    public static extern int SetCurrentProcessExplicitAppUserModelID(string appId);

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll", EntryPoint = "GetClassLongA")]
    public static extern int GetClassLong(IntPtr hWnd, int nIndex);

    [DllImport("user32.dll", EntryPoint = "SetClassLongA")]
    public static extern int SetClassLong(IntPtr hWnd, int nIndex, int dwNewLong);
}
"@
}

# Constantes de user32.dll para Set-SombraVentana (no vienen expuestas por
# .NET): GCL_STYLE identifica el campo de estilo de la clase de ventana,
# CS_DROPSHADOW pide a Windows la sombra nativa de las ventanas flotantes.
$HitoGclStyle     = -26
$HitoCsDropshadow = 0x00020000

function Set-SombraVentana {
    <#
    .SYNOPSIS
    Agrega la sombra nativa de Windows a una ventana sin borde de sistema.

    .DESCRIPTION
    Sin barra de título ni borde del sistema, dos ventanas de HITO
    superpuestas (ej. "Acerca de" sobre la principal) no tienen ninguna
    señal visual de que son ventanas distintas. La sombra nativa (el mismo
    efecto que usa cualquier flyout de Windows) resuelve eso sin agregar
    un borde de color que compita con el resto del diseño.

    .PARAMETER Form
    Ventana ya creada (necesita el handle nativo, por eso se llama
    después de que la ventana existe, no durante su construcción).
    #>
    param([System.Windows.Forms.Form]$Form)
    $estiloActual = [HitoNativo]::GetClassLong($Form.Handle, $HitoGclStyle)
    [void][HitoNativo]::SetClassLong($Form.Handle, $HitoGclStyle, ($estiloActual -bor $HitoCsDropshadow))
}

# Identidad de aplicación propia: sin esto, la barra de tareas agrupa las
# ventanas bajo powershell.exe y muestra su ícono en vez de hito.ico.
if ($HitoAppUserModelId -and [HitoNativo].GetMethod("SetCurrentProcessExplicitAppUserModelID")) {
    [void][HitoNativo]::SetCurrentProcessExplicitAppUserModelID($HitoAppUserModelId)
}

$HitoFuenteNombre = "Segoe UI"

# Métrica de layout: todo se posiciona contra ClientSize (el área útil real
# de la ventana), con este margen uniforme en los cuatro lados.
$HitoMargen    = 24
$HitoAltoBanda = 36

# --- Paleta activa: Opción A "Petróleo y ámbar" ---
$HitoColorFondo         = [System.Drawing.Color]::FromArgb(247, 248, 250)  # #F7F8FA
$HitoColorTexto         = [System.Drawing.Color]::FromArgb(26, 29, 33)     # #1A1D21
$HitoColorTextoSuave    = [System.Drawing.Color]::FromArgb(85, 96, 110)    # #55606E
$HitoColorTextoHint     = [System.Drawing.Color]::FromArgb(138, 148, 160)  # #8A94A0
$HitoColorSeparador     = [System.Drawing.Color]::FromArgb(226, 230, 235)  # #E2E6EB
$HitoColorAlerta        = [System.Drawing.Color]::FromArgb(180, 83, 9)     # #B45309 (ámbar: sin red)
$HitoColorUrgente       = [System.Drawing.Color]::FromArgb(185, 28, 28)    # #B91C1C (rojo: segundo aviso)
$HitoColorCampoInactivo = [System.Drawing.Color]::FromArgb(232, 235, 239)  # #E8EBEF

$HitoColorPrimario        = [System.Drawing.Color]::FromArgb(14, 116, 144) # #0E7490
$HitoColorPrimarioHover   = [System.Drawing.Color]::FromArgb(12, 100, 125) # #0C647D
$HitoColorPrimarioDown    = [System.Drawing.Color]::FromArgb(10, 85, 104)  # #0A5568
$HitoColorSecundario      = [System.Drawing.Color]::FromArgb(228, 233, 238) # #E4E9EE
$HitoColorSecundarioHover = [System.Drawing.Color]::FromArgb(216, 222, 229) # #D8DEE5
$HitoColorSecundarioDown  = [System.Drawing.Color]::FromArgb(201, 209, 218) # #C9D1DA

$HitoColorBanda      = [System.Drawing.Color]::FromArgb(22, 78, 99)   # #164E63
$HitoColorBandaHover = [System.Drawing.Color]::FromArgb(29, 95, 119)  # #1D5F77

# Carpeta donde vive este archivo (= carpeta de instalación de HITO).
# La usan las ventanas para encontrar hito.ico sin que cada llamador
# tenga que pasarla.
$HitoCarpetaEstilos = $PSScriptRoot

function New-FuenteHito {
    <#
    .SYNOPSIS
    Crea una fuente con la tipografía estándar de HITO.

    .PARAMETER Tamano
    Tamaño en puntos (9 por defecto).

    .PARAMETER Negrita
    Usar la variante en negrita.
    #>
    param([single]$Tamano = 9, [switch]$Negrita)

    $estilo = if ($Negrita) { [System.Drawing.FontStyle]::Bold }
              else          { [System.Drawing.FontStyle]::Regular }
    return New-Object System.Drawing.Font($HitoFuenteNombre, $Tamano, $estilo)
}

function Set-EsquinasRectas {
    <#
    .SYNOPSIS
    Pide a Windows 11 que no redondee las esquinas de la ventana
    (DWMWA_WINDOW_CORNER_PREFERENCE = DONOTROUND). En Windows 10 la
    llamada devuelve un código de error que se ignora: ahí las esquinas
    de una ventana sin borde ya son rectas.
    #>
    param($Form)
    $Form.Add_HandleCreated({
        $preferencia = 1   # DWMWCP_DONOTROUND
        [void][HitoNativo]::DwmSetWindowAttribute($this.Handle, 33, [ref]$preferencia, 4)
    })
}

function Enable-ArrastreVentana {
    <#
    .SYNOPSIS
    Permite arrastrar una ventana sin barra de título del sistema
    tomándola con el mouse desde el control indicado (la banda propia).
    #>
    param($Control)
    $Control.Add_MouseDown({
        param($origen, $evento)
        if ($evento.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            # WM_NCLBUTTONDOWN (0xA1) con HTCAPTION (0x2): Windows mueve
            # la ventana como si se arrastrara una barra de título real.
            [void][HitoNativo]::ReleaseCapture()
            [void][HitoNativo]::SendMessage($origen.FindForm().Handle, 0xA1, 0x2, 0)
        }
    })
}

function New-VentanaHito {
    <#
    .SYNOPSIS
    Crea una ventana con la identidad de HITO: sin barra de título del
    sistema, con banda propia (logo, título y una ✕ que dispara el mismo
    FormClosing que la X del sistema), esquinas rectas, borde de 1 px y
    arrastrable desde la banda. Ancho y Alto definen el área útil real
    (ClientSize), no el tamaño exterior — así los márgenes izquierdo y
    derecho quedan realmente iguales.

    .PARAMETER Titulo
    Título integrado a la banda propia.

    .PARAMETER Ancho
    Ancho del área útil en píxeles.

    .PARAMETER Alto
    Alto del área útil en píxeles.

    .PARAMETER ScriptDir
    Carpeta donde buscar hito.ico. Si se omite, se usa la carpeta de
    instalación (donde vive estilos.ps1).

    .PARAMETER EnBarraTareas
    Mantener el botón en la barra de tareas (ventana principal). Los
    avisos transitorios no lo llevan.
    #>
    param([string]$Titulo, [int]$Ancho, [int]$Alto, [string]$ScriptDir, [switch]$EnBarraTareas)

    if (-not $ScriptDir) { $ScriptDir = $HitoCarpetaEstilos }
    $iconPath = Join-Path $ScriptDir "hito.ico"

    $form = New-Object System.Windows.Forms.Form
    $form.Text            = $Titulo
    $form.StartPosition   = "CenterScreen"
    $form.MaximizeBox     = $false
    $form.MinimizeBox     = $false
    $form.TopMost         = $true
    $form.BackColor       = $HitoColorFondo
    $form.FormBorderStyle = "None"
    $form.ShowInTaskbar   = [bool]$EnBarraTareas
    $form.ClientSize      = New-Object System.Drawing.Size($Ancho, $Alto)
    Set-EsquinasRectas -Form $form

    # Sin barra del sistema, la ventana necesita un límite visual
    # propio contra el fondo del escritorio.
    $form.Add_Paint({
        param($ventana, $evento)
        $lapiz = New-Object System.Drawing.Pen($HitoColorSeparador)
        $evento.Graphics.DrawRectangle($lapiz, 0, 0, $ventana.ClientSize.Width - 1, $ventana.ClientSize.Height - 1)
        $lapiz.Dispose()
    })

    $banda           = New-Object System.Windows.Forms.Panel
    $banda.BackColor = $HitoColorBanda
    $banda.Location  = New-Object System.Drawing.Point(0, 0)
    $banda.Size      = New-Object System.Drawing.Size($Ancho, $HitoAltoBanda)

    # Logo de la app integrado a la banda, a la izquierda del título.
    # ExtractAssociatedIcon y no Icon.ToBitmap directo: hito.ico solo trae
    # un frame de 256 px comprimido como PNG, y ToBitmap falla con esos
    # frames en .NET Framework.
    $xTitulo = 14
    if (Test-Path -LiteralPath $iconPath) {
        $logoBanda           = New-Object System.Windows.Forms.PictureBox
        $logoBanda.Image     = [System.Drawing.Icon]::ExtractAssociatedIcon($iconPath).ToBitmap()
        $logoBanda.SizeMode  = [System.Windows.Forms.PictureBoxSizeMode]::StretchImage
        $logoBanda.Location  = New-Object System.Drawing.Point(12, (($HitoAltoBanda - 20) / 2))
        $logoBanda.Size      = New-Object System.Drawing.Size(20, 20)
        $logoBanda.BackColor = $HitoColorBanda
        $banda.Controls.Add($logoBanda)
        Enable-ArrastreVentana -Control $logoBanda
        $xTitulo = 40
    }

    $tituloBanda           = New-Object System.Windows.Forms.Label
    $tituloBanda.Text      = $Titulo
    $tituloBanda.Font      = New-FuenteHito -Tamano 10.5 -Negrita
    $tituloBanda.ForeColor = [System.Drawing.Color]::White
    $tituloBanda.BackColor = $HitoColorBanda
    $tituloBanda.Location  = New-Object System.Drawing.Point($xTitulo, 0)
    $tituloBanda.Size      = New-Object System.Drawing.Size(($Ancho - $xTitulo - 46), $HitoAltoBanda)
    $tituloBanda.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $banda.Controls.Add($tituloBanda)

    $btnCerrarBanda           = New-Object System.Windows.Forms.Button
    $btnCerrarBanda.Text      = "✕"
    $btnCerrarBanda.Font      = New-FuenteHito -Tamano 10
    $btnCerrarBanda.ForeColor = [System.Drawing.Color]::White
    $btnCerrarBanda.BackColor = $HitoColorBanda
    $btnCerrarBanda.FlatStyle = "Flat"
    $btnCerrarBanda.FlatAppearance.BorderSize = 0
    $btnCerrarBanda.FlatAppearance.MouseOverBackColor = $HitoColorBandaHover
    $btnCerrarBanda.FlatAppearance.MouseDownBackColor = $HitoColorBandaHover
    $btnCerrarBanda.Location  = New-Object System.Drawing.Point(($Ancho - 44), 0)
    $btnCerrarBanda.Size      = New-Object System.Drawing.Size(44, $HitoAltoBanda)
    $btnCerrarBanda.Cursor    = "Hand"
    $btnCerrarBanda.TabStop   = $false
    $btnCerrarBanda.Add_Click({ $this.FindForm().Close() })
    $banda.Controls.Add($btnCerrarBanda)

    Enable-ArrastreVentana -Control $banda
    Enable-ArrastreVentana -Control $tituloBanda

    $form.Controls.Add($banda)

    if (Test-Path -LiteralPath $iconPath) { $form.Icon = New-Object System.Drawing.Icon($iconPath) }
    Set-SombraVentana -Form $form
    return $form
}

function New-LabelHito {
    <#
    .SYNOPSIS
    Crea una etiqueta con la tipografía y los colores estándar de HITO.

    .PARAMETER Texto
    Texto a mostrar.

    .PARAMETER X
    Posición horizontal en píxeles.

    .PARAMETER Y
    Posición vertical en píxeles.

    .PARAMETER Ancho
    Ancho en píxeles.

    .PARAMETER Alto
    Alto en píxeles (18 por defecto, una línea de texto de 9 pt).

    .PARAMETER Tamano
    Tamaño de fuente en puntos (9 por defecto).

    .PARAMETER Negrita
    Usar negrita.

    .PARAMETER Centrado
    Centrar el texto (para las ventanas tipo popup).

    .PARAMETER Color
    Color del texto (color de texto principal por defecto).
    #>
    param(
        [string]$Texto,
        [int]$X,
        [int]$Y,
        [int]$Ancho,
        [int]$Alto = 18,
        [single]$Tamano = 9,
        [switch]$Negrita,
        [switch]$Centrado,
        [System.Drawing.Color]$Color = $HitoColorTexto
    )

    $label           = New-Object System.Windows.Forms.Label
    $label.Text      = $Texto
    $label.Font      = New-FuenteHito -Tamano $Tamano -Negrita:$Negrita
    $label.Location  = New-Object System.Drawing.Point($X, $Y)
    $label.Size      = New-Object System.Drawing.Size($Ancho, $Alto)
    $label.ForeColor = $Color
    $label.BackColor = [System.Drawing.Color]::Transparent
    # Sin mnemónicos: un "&" real en una ruta mostrada debe verse tal cual,
    # no desaparecer subrayando la letra siguiente.
    $label.UseMnemonic = $false
    if ($Centrado) { $label.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter }
    return $label
}

function New-BotonHito {
    <#
    .SYNOPSIS
    Crea un botón con el estilo estándar de HITO: plano, sin borde, con
    estados visuales al pasar el mouse y al hacer clic.

    .PARAMETER Texto
    Texto del botón (admite mnemónicos con "&").

    .PARAMETER X
    Posición horizontal en píxeles.

    .PARAMETER Y
    Posición vertical en píxeles.

    .PARAMETER Ancho
    Ancho en píxeles.

    .PARAMETER Alto
    Alto en píxeles.

    .PARAMETER Primario
    Variante primaria (color de acento, texto blanco en negrita) para la
    acción principal de la ventana. Sin este switch, variante secundaria.
    #>
    param([string]$Texto, [int]$X, [int]$Y, [int]$Ancho, [int]$Alto, [switch]$Primario)

    $boton                           = New-Object System.Windows.Forms.Button
    $boton.Text                      = $Texto
    $boton.Font                      = New-FuenteHito -Tamano 10 -Negrita:$Primario
    $boton.Location                  = New-Object System.Drawing.Point($X, $Y)
    $boton.Size                      = New-Object System.Drawing.Size($Ancho, $Alto)
    $boton.FlatStyle                 = "Flat"
    $boton.FlatAppearance.BorderSize = 0
    $boton.Cursor                    = "Hand"
    if ($Primario) {
        $boton.BackColor = $HitoColorPrimario
        $boton.ForeColor = [System.Drawing.Color]::White
        $boton.FlatAppearance.MouseOverBackColor = $HitoColorPrimarioHover
        $boton.FlatAppearance.MouseDownBackColor = $HitoColorPrimarioDown
    } else {
        $boton.BackColor = $HitoColorSecundario
        $boton.ForeColor = $HitoColorTexto
        $boton.FlatAppearance.MouseOverBackColor = $HitoColorSecundarioHover
        $boton.FlatAppearance.MouseDownBackColor = $HitoColorSecundarioDown
    }
    return $boton
}

function New-SeparadorHito {
    <#
    .SYNOPSIS
    Crea la línea separadora horizontal estándar de HITO.

    .PARAMETER X
    Posición horizontal en píxeles.

    .PARAMETER Y
    Posición vertical en píxeles.

    .PARAMETER Ancho
    Ancho en píxeles.
    #>
    param([int]$X, [int]$Y, [int]$Ancho)

    $sep           = New-Object System.Windows.Forms.Panel
    $sep.BackColor = $HitoColorSeparador
    $sep.Location  = New-Object System.Drawing.Point($X, $Y)
    $sep.Size      = New-Object System.Drawing.Size($Ancho, 1)
    return $sep
}

function Show-DialogoHito {
    <#
    .SYNOPSIS
    Diálogo modal propio de HITO, en reemplazo de MessageBox: mismo
    lenguaje visual que las ventanas popup (banda con ✕, textos
    centrados, botones apilados de ancho completo).

    .PARAMETER Mensaje
    Cuerpo del mensaje. Admite varias líneas.

    .PARAMETER Titulo
    Encabezado del diálogo (se muestra dentro, coloreado según Tipo).

    .PARAMETER Tipo
    "Info" (acento primario), "Advertencia" (ámbar) o "Pregunta" (neutro).

    .PARAMETER SiNo
    Mostrar botones Sí / No en vez de un único Aceptar.

    .OUTPUTS
    [bool] true si el usuario eligió Aceptar o Sí; false si eligió No o
    cerró con la ✕ (o Esc).
    #>
    param(
        [string]$Mensaje,
        [string]$Titulo = "HITO",
        [ValidateSet("Info", "Advertencia", "Pregunta")]
        [string]$Tipo = "Info",
        [switch]$SiNo
    )

    $anchoCliente = 400
    $anchoTexto   = $anchoCliente - (2 * $HitoMargen)

    # Altura del mensaje medida con la fuente real, para que el diálogo
    # crezca según el texto en vez de recortarlo.
    $fuenteMensaje = New-FuenteHito -Tamano 10
    $tamanoMaximo  = New-Object System.Drawing.Size($anchoTexto, 0)
    $altoMensaje   = [System.Windows.Forms.TextRenderer]::MeasureText(
        $Mensaje, $fuenteMensaje, $tamanoMaximo,
        [System.Windows.Forms.TextFormatFlags]::WordBreak).Height + 8

    $yTitulo   = $HitoAltoBanda + 18
    $yMensaje  = $yTitulo + 26 + 10
    $yBotones  = $yMensaje + $altoMensaje + 20
    $altoBoton = 40
    $altoExtra = if ($SiNo) { $altoBoton + 8 } else { 0 }
    $altoCliente = $yBotones + $altoBoton + $altoExtra + $HitoMargen

    $colorTitulo = switch ($Tipo) {
        "Advertencia" { $HitoColorAlerta }
        "Pregunta"    { $HitoColorTexto }
        default       { $HitoColorPrimario }
    }

    $form = New-VentanaHito -Titulo "HITO" -Ancho $anchoCliente -Alto $altoCliente
    $form.Tag = $false

    $form.Controls.Add((New-LabelHito -Texto $Titulo -X $HitoMargen -Y $yTitulo `
        -Ancho $anchoTexto -Alto 26 -Tamano 12 -Negrita -Centrado -Color $colorTitulo))
    $form.Controls.Add((New-LabelHito -Texto $Mensaje -X $HitoMargen -Y $yMensaje `
        -Ancho $anchoTexto -Alto $altoMensaje -Tamano 10 -Centrado -Color $HitoColorTextoSuave))

    if ($SiNo) {
        $btnSi = New-BotonHito -Texto "&Sí" -X $HitoMargen -Y $yBotones -Ancho $anchoTexto -Alto $altoBoton -Primario
        $btnSi.Add_Click({ $this.FindForm().Tag = $true; $this.FindForm().Close() })
        $form.Controls.Add($btnSi)

        $btnNo = New-BotonHito -Texto "&No" -X $HitoMargen -Y ($yBotones + $altoBoton + 8) -Ancho $anchoTexto -Alto $altoBoton
        $btnNo.Add_Click({ $this.FindForm().Close() })
        $form.Controls.Add($btnNo)

        $form.AcceptButton = $btnSi
        $form.CancelButton = $btnNo
    } else {
        $btnAceptar = New-BotonHito -Texto "&Aceptar" -X $HitoMargen -Y $yBotones -Ancho $anchoTexto -Alto $altoBoton -Primario
        $btnAceptar.Add_Click({ $this.FindForm().Tag = $true; $this.FindForm().Close() })
        $form.Controls.Add($btnAceptar)

        $form.AcceptButton = $btnAceptar
        $form.CancelButton = $btnAceptar
    }

    [void]$form.ShowDialog()
    $resultado = [bool]$form.Tag
    $form.Dispose()
    return $resultado
}
