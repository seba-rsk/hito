#Requires -Version 5.1
# constantes.ps1
# Fuente única de días, tareas programadas y valores por defecto de HITO.
# La usan hito.ps1, configurar.ps1, aplicar_horarios.ps1, desinstalar.ps1 y
# crear_tareas.ps1 via dot-source: . (Join-Path $scriptDir "constantes.ps1")
#
# El campo "Nombre" es el identificador interno (ASCII, sin tildes): se usa
# como clave de config.json y como texto en log.txt. No cambiarlo rompe la
# compatibilidad con instalaciones existentes.

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', '',
    Justification = 'Variables usadas por los scripts que dot-sourcean este archivo.'
)]
param()

$HitoDias = [ordered]@{
    Monday    = @{ Nombre = "Lunes";     Tarea = "HITO_Lun" }
    Tuesday   = @{ Nombre = "Martes";    Tarea = "HITO_Mar" }
    Wednesday = @{ Nombre = "Miercoles"; Tarea = "HITO_Mie" }
    Thursday  = @{ Nombre = "Jueves";    Tarea = "HITO_Jue" }
    Friday    = @{ Nombre = "Viernes";   Tarea = "HITO_Vie" }
    Saturday  = @{ Nombre = "Sabado";    Tarea = "HITO_Sab" }
    Sunday    = @{ Nombre = "Domingo";   Tarea = "HITO_Dom" }
}

# Días activos por defecto en una instalación nueva (Lunes a Viernes).
# Sábado y Domingo quedan disponibles pero desactivados hasta que el
# usuario los tilde en Configuración.
$HitoDiasLaborables = @("Lunes", "Martes", "Miercoles", "Jueves", "Viernes")

$HitoHoraDefault        = "17:30"
$HitoMinutosReintento   = 15
$HitoSegundosChequeoRed = 10
$HitoVersion            = "1.1.0"

# Ancho compartido por configurar.ps1 y acerca_de.ps1: "Acerca de" se
# posiciona respecto de la principal asumiendo el mismo ancho (ver
# acerca_de.ps1, cálculo de posición). Si dejan de coincidir, ese cálculo
# deja de tener sentido sin que nada avise — de ahí la constante única.
$HitoAnchoVentanaPrincipal = 460
$HitoAutor              = "Sebastián A. Roskopf"
$HitoRepoUrl            = "https://github.com/seba-rsk/hito"
$HitoNombreCarpetaLogs  = "logs"
$HitoNombreArchivoLog   = "log.txt"

# Identidad de aplicación para la barra de tareas de Windows (la usa
# estilos.ps1 antes de crear cualquier ventana).
$HitoAppUserModelId = "SebastianRoskopf.HITO"

# Rutas completas de los ejecutables del sistema: referenciarlos solo por
# nombre los resuelve vía PATH del usuario, que es modificable.
$HitoRutaWscript    = Join-Path $env:WINDIR "System32\wscript.exe"
$HitoRutaPowershell = Join-Path $env:WINDIR "System32\WindowsPowerShell\v1.0\powershell.exe"
$HitoRutaExplorer   = Join-Path $env:WINDIR "explorer.exe"

# Extensiones que HITO reconoce como planilla de Excel. Otro archivo se
# puede configurar y abrir igual, pero con un aviso.
$HitoExtensionesPlanilla = @(".xls", ".xlsx", ".xlsm")

# Carpeta de los accesos directos que crea el instalador (y borra el
# desinstalador) en el Menú Inicio del usuario.
$HitoCarpetaMenuInicio = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\HITO"

# HITO_Reintento ya no la crea hito.ps1 (el segundo aviso ahora es un timer
# interno del mismo proceso). Se mantiene solo para que desinstalar.ps1
# pueda limpiarla si quedó huérfana de una instalación de una versión previa.
$HitoTareaReintento = "HITO_Reintento"
