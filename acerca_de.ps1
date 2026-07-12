#Requires -Version 5.1
# acerca_de.ps1
# Ventana modal "Acerca de HITO": versión, autor, rutas de datos/log y
# accesos rápidos a la carpeta de logs y al repositorio.
# La usa configurar.ps1 vía dot-source.

function Show-VentanaAcercaDe {
    <#
    .SYNOPSIS
    Muestra la ventana modal "Acerca de HITO": versión, autor, ruta de
    datos de usuario y de log (copiables y completas), y accesos a la
    carpeta de logs y al repositorio.

    .PARAMETER ScriptDir
    Carpeta de instalación de HITO.

    .PARAMETER Owner
    Ventana principal desde la que se abre. Sin esto, "Acerca de" se
    centra en la pantalla en vez de sobre la ventana principal — si el
    usuario arrastró la ventana principal antes de abrir "Acerca de",
    aparecería lejos de donde la movió.
    #>
    param([string]$ScriptDir, [System.Windows.Forms.Form]$Owner)

    . (Join-Path $ScriptDir "constantes.ps1")

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    . (Join-Path $ScriptDir "estilos.ps1")

    $logsDir = Join-Path $ScriptDir $HitoNombreCarpetaLogs

    # Mismo ancho que la ventana principal ($HitoAnchoVentanaPrincipal en
    # constantes.ps1, no un 460 propio): el cálculo de posición de más
    # abajo asume ese ancho compartido.
    $anchoVentana   = $HitoAnchoVentanaPrincipal
    $anchoContenido = $anchoVentana - (2 * $HitoMargen)

    $form = New-VentanaHito -Titulo "Acerca de HITO" -Ancho $anchoVentana -Alto 466 -ScriptDir $ScriptDir
    if ($Owner) {
        # Centrada en altura pero corrida a la derecha, no exactamente
        # encima de la principal: con el mismo ancho y sin borde de
        # sistema en ninguna de las dos, "CenterParent" las deja pixel a
        # pixel alineadas — indistinguible a simple vista aunque tengan
        # sombra propia.
        $form.StartPosition = "Manual"
        $desfaseX = $HitoMargen * 2
        $x = $Owner.Left + [int](($Owner.Width  - $form.Width)  / 2) + $desfaseX
        $y = $Owner.Top  + [int](($Owner.Height - $form.Height) / 2)

        # La principal es arrastrable: si queda cerca de un borde de
        # pantalla, el desfase a la derecha puede sacar a "Acerca de"
        # (con su banda y el botón ✕) fuera del área visible. Recortar
        # contra el área de trabajo del monitor donde está la principal.
        $areaTrabajo = [System.Windows.Forms.Screen]::FromControl($Owner).WorkingArea
        $x = [Math]::Max($areaTrabajo.Left, [Math]::Min($x, $areaTrabajo.Right  - $form.Width))
        $y = [Math]::Max($areaTrabajo.Top,  [Math]::Min($y, $areaTrabajo.Bottom - $form.Height))

        $form.Location = New-Object System.Drawing.Point($x, $y)
    }

    $form.Controls.Add((New-LabelHito -Texto "HITO" -X $HitoMargen -Y 54 -Ancho $anchoContenido -Alto 30 -Tamano 15 -Negrita -Centrado))
    $form.Controls.Add((New-LabelHito -Texto "Versión $HitoVersion" -X $HitoMargen -Y 86 -Ancho $anchoContenido -Alto 20 -Tamano 10 -Centrado))
    $form.Controls.Add((New-LabelHito `
        -Texto "Recordatorio diario para completar la planilla de horas, con segundo aviso automático si no se responde." `
        -X $HitoMargen -Y 108 -Ancho $anchoContenido -Alto 40 -Tamano 10 -Color $HitoColorTextoSuave -Centrado))
    $form.Controls.Add((New-SeparadorHito -X $HitoMargen -Y 160 -Ancho $anchoContenido))

    function New-TextBoxRuta($valor, $y) {
        <#
        .SYNOPSIS
        Campo de solo lectura para mostrar una ruta completa: se ve como
        texto informativo (sin borde, mismo fondo que la ventana), ajusta
        la ruta en dos líneas para que nunca quede recortada, y sigue
        siendo seleccionable y copiable con el mouse.
        #>
        $t             = New-Object System.Windows.Forms.TextBox
        $t.Font        = New-Object System.Drawing.Font("Consolas", 9)
        $t.Location    = New-Object System.Drawing.Point($HitoMargen, $y)
        $t.Size        = New-Object System.Drawing.Size($anchoContenido, 36)
        $t.Text        = $valor
        $t.ReadOnly    = $true
        $t.Multiline   = $true
        $t.WordWrap    = $true
        $t.BorderStyle = [System.Windows.Forms.BorderStyle]::None
        $t.BackColor   = $HitoColorFondo
        $t.ForeColor   = $HitoColorTexto
        $t.TabStop     = $false
        return $t
    }

    $form.Controls.Add((New-LabelHito -Texto "AUTOR" -X $HitoMargen -Y 176 -Ancho $anchoContenido -Alto 14 -Negrita -Color $HitoColorTextoSuave))
    $form.Controls.Add((New-LabelHito -Texto $HitoAutor -X $HitoMargen -Y 192 -Ancho $anchoContenido -Alto 20 -Tamano 10))

    $form.Controls.Add((New-LabelHito -Texto "DATOS DE USUARIO" -X $HitoMargen -Y 222 -Ancho $anchoContenido -Alto 14 -Negrita -Color $HitoColorTextoSuave))
    $form.Controls.Add((New-TextBoxRuta $ScriptDir 240))

    $form.Controls.Add((New-LabelHito -Texto "ARCHIVO DE LOG" -X $HitoMargen -Y 288 -Ancho $anchoContenido -Alto 14 -Negrita -Color $HitoColorTextoSuave))
    $form.Controls.Add((New-TextBoxRuta (Join-Path $logsDir $HitoNombreArchivoLog) 306))

    $anchoMitad = [int](($anchoContenido - 12) / 2)

    $btnLogs = New-BotonHito -Texto "Abrir carpeta de logs" -X $HitoMargen -Y 356 -Ancho $anchoMitad -Alto 38
    $btnLogs.Add_Click({
        try {
            if (-not (Test-Path -LiteralPath $logsDir)) { New-Item -ItemType Directory -Path $logsDir | Out-Null }
            Start-Process $HitoRutaExplorer $logsDir
        } catch {
            [void](Show-DialogoHito -Titulo "No se pudo abrir" -Tipo "Advertencia" `
                -Mensaje "No pudimos abrir la carpeta de logs.")
        }
    })
    $form.Controls.Add($btnLogs)

    $btnRepo = New-BotonHito -Texto "Ir al repositorio" -X ($HitoMargen + $anchoMitad + 12) -Y 356 -Ancho $anchoMitad -Alto 38
    $btnRepo.Add_Click({
        try {
            Start-Process $HitoRepoUrl
        } catch {
            [void](Show-DialogoHito -Titulo "No se pudo abrir" -Tipo "Advertencia" `
                -Mensaje "No pudimos abrir el navegador.")
        }
    })
    $form.Controls.Add($btnRepo)

    $btnCerrar = New-BotonHito -Texto "&Cerrar" -X $HitoMargen -Y 402 -Ancho $anchoContenido -Alto 40 -Primario
    $btnCerrar.Add_Click({ $form.Close() })
    $form.Controls.Add($btnCerrar)
    $form.AcceptButton = $btnCerrar
    $form.CancelButton = $btnCerrar

    if ($Owner) { [void]$form.ShowDialog($Owner) } else { [void]$form.ShowDialog() }
}
