# Changelog

Todos los cambios notables de HITO se documentan en este archivo.

El formato sigue [Keep a Changelog](https://keepachangelog.com/es/1.0.0/).
El versionado sigue [Semantic Versioning](https://semver.org/lang/es/).

---

## [Unreleased]
(cambios en desarrollo que todavía no tienen versión asignada)

---

## [1.1.0] — 2026-07-12

### Agregado
- `constantes.ps1`: fuente única de días, tareas programadas y hora por
  defecto, compartida por todos los scripts (antes duplicada en 4 archivos).
- `configuracion.psm1` (`Get-HitoConfig`, con tests): lectura y parseo de
  `config.json` en un solo lugar, testeado con Pester. Antes `hito.ps1`,
  `configurar.ps1` y `aplicar_horarios.ps1` leían y parseaban el archivo
  cada uno por su cuenta, con manejo de errores ligeramente distinto en
  cada copia.
- `constantes.ps1`: `$HitoAnchoVentanaPrincipal` (460), compartida por
  `configurar.ps1` y `acerca_de.ps1` en vez de repetir el mismo `460`
  literal en los dos archivos.
- Tests con Pester (`tests/SincronizarHorarios.Tests.ps1`) para
  `Sync-TareasHorario`: la decisión de crear, actualizar o eliminar cada
  tarea programada según los días activos, antes sin ningún test.
  Mockea los cmdlets del Programador de tareas (`Get/Register/Set/
  Unregister-ScheduledTask`) — no crea ni toca ninguna tarea real.
- `validaciones.psm1`: lógica de validación de horarios extraída del
  formulario de configuración, ahora testeable de forma aislada.
- `crear_tareas.ps1`: creación de tareas programadas y accesos directos del
  Menú Inicio con cmdlets nativos de PowerShell (`Register-ScheduledTask`,
  `WScript.Shell`), en reemplazo de comandos armados por concatenación de
  texto en `instalar.bat`.
- Tests con Pester (`tests/Validaciones.Tests.ps1`) para la validación de
  horarios, corridos automáticamente en CI.
- `KNOWN_ISSUES.md` con las limitaciones reales del software.
- Validación en `desinstalar.ps1`: antes de borrar, confirma que la carpeta
  contiene una instalación real de HITO, y muestra la ruta exacta en el
  diálogo de confirmación.
- `hito.ps1`: el botón "Abrir planilla" se deshabilita cuando la red no
  está disponible, y se reactiva solo si la conexión vuelve mientras la
  ventana sigue abierta (chequeo cada 10 segundos).
- Selector de días de la semana: `configurar.ps1` pasa a soportar los 7
  días (antes fijo Lunes-Viernes), cada uno con su propio checkbox
  "Activo". Por defecto siguen activos Lunes a Viernes — cero cambio de
  comportamiento para instalaciones existentes. `sincronizar_horarios.ps1`
  (nuevo) crea, actualiza o elimina la tarea programada de cada día según
  quede activo o no, y lo usan tanto `configurar.ps1` (al guardar) como
  `aplicar_horarios.ps1` (al reinstalar).
- Ventana "Acerca de HITO" (`acerca_de.ps1`, nuevo), accesible con el botón
  "ⓘ Acerca de" de la ventana principal: versión, autor, ruta de datos de
  usuario y de log (copiables), botón para abrir la carpeta de logs y
  botón para ir al repositorio.
- Los logs pasan de `log.txt` suelto a una carpeta exclusiva
  (`logs\log.txt`), con migración automática del archivo viejo la primera
  vez que corre la versión nueva.
- El acceso directo del Menú Inicio antes llamado "Configuración" pasa a
  llamarse "HITO", reflejando que ahora es la ventana principal del
  software (configuración + Acerca de), no solo un formulario de ajustes.
- `estilos.ps1`: paleta de colores, tipografía y fábricas de controles
  (ventana, etiqueta, botón, separador) compartidas por las tres ventanas
  — antes cada una copiaba su propio bloque de estilo, y ya había
  producido inconsistencias reales (texto de 8pt vs 9pt).
- `ConvertTo-HoraNormalizada` en `validaciones.psm1` (con sus tests): la
  aceptación de punto o coma como separador de hora deja de vivir en el
  formulario y pasa al módulo testeado, que ahora normaliza y valida en
  un solo lugar.
- Aviso al guardar la configuración, y confirmación al abrir desde el
  recordatorio, cuando el archivo configurado como planilla no tiene
  extensión de Excel (`.xls`, `.xlsx`, `.xlsm`) — se puede usar igual,
  pero ya no en silencio.

### Corregido
- Lectura de `config.json` protegida con manejo de errores en `hito.ps1`,
  `configurar.ps1` y `aplicar_horarios.ps1`: si el archivo está dañado, se
  avisa al usuario en vez de fallar en silencio.
- `lanzar.vbs` ahora encierra entre comillas los argumentos adicionales al
  primero, evitando que un argumento con espacios rompa el comando.
- `hito.ps1`: los mensajes de la ventana de recordatorio ya no citan la
  hora configurada — evita el mensaje engañoso ("Son las 17:30...") cuando
  la ejecución retroactiva muestra el aviso horas después.
- `hito.ps1`: el segundo aviso ya no abre una ventana nueva mientras la del
  primero sigue abierta. Ahora es la misma ventana la que escala a "segundo
  aviso" (timer interno de `$HitoMinutosReintento` minutos), eliminando la
  tarea programada `HITO_Reintento` y la posibilidad de que dos ventanas
  coexistan y generen logs confusos (confirmado en `log.txt` de producción).
  Se agregó un nuevo estado de log, "Mostrado", que marca el momento exacto
  en que aparece el segundo aviso, independiente de la acción posterior del
  usuario.
- `hito.ps1` valida el horario leído de `config.json` antes de usarlo: un
  valor editado a mano (por ejemplo `"17.xx"`) ya no tumba el recordatorio
  en silencio — se avisa al usuario y se abre el configurador, igual que
  cuando el archivo está dañado.
- El chequeo periódico de red del recordatorio pasa a correr en segundo
  plano: con la unidad de red caída, `Test-Path` podía congelar la ventana
  varios segundos en cada chequeo.
- El desinstalador ahora borra la carpeta de instalación antes de mostrar
  el mensaje final, y avisa si no se pudo borrar por completo (antes decía
  "desinstalado correctamente" sin haber verificado ese último paso).
- `config.json` se escribe de forma atómica (archivo temporal + renombre)
  y el log se agrega línea por línea en vez de reescribirse completo: un
  corte a mitad de escritura ya no puede truncarlos.
- `lanzar.vbs` rechaza argumentos que contengan comillas dobles, que
  romperían el armado del comando (ninguna ruta real las contiene).
- Los cuatro hallazgos bajos de la auditoría del 2026-07-11:
  - Todos los `Test-Path` usan `-LiteralPath`: una carpeta real con
    corchetes en el nombre (ej. `C:\Obras\[2026] Torre\`) ya no hace que
    la planilla figure como "no encontrada" por interpretarse como
    comodín.
  - Los ejecutables del sistema se invocan por ruta completa
    (`System32\wscript.exe`, `System32\...\powershell.exe`) en tareas
    programadas, accesos directos, `Start-Process` y `lanzar.vbs` — ya no
    se resuelven vía PATH del usuario, que es modificable.
  - Los textos de los diálogos muestran los `&` de una ruta tal cual
    (`UseMnemonic = $false`): antes un `&` real desaparecía subrayando la
    letra siguiente, y la ruta confirmada no era idéntica a la mostrada.
  - El segundo aviso reaparece al frente **sin robar el foco**
    (`ShowWindow` con `SW_SHOWNOACTIVATE`): un Enter que el usuario
    estaba tecleando en otra aplicación ya no puede accionar un botón
    del aviso y registrar un falso "Completado".
- `hito.ps1`: el botón "Abrir planilla" deshabilitado (sin red) ahora se
  distingue con claridad del botón secundario "Ya las completé" — antes
  usaban grises casi idénticos y, encima, el deshabilitado conservaba la
  negrita de su variante primaria y llamaba más la atención que el
  habilitado. Corregido en varias iteraciones probadas en la app real
  (`/ui`): un gris intermedio no se distinguía, oscurecer
  `$HitoColorSecundario` perdía la sutileza del gris original en el
  resto de los botones de la app, y un borde de un tono más oscuro que
  el fondo destacaba de más. Diseño final: sin negrita, fondo propio
  (usa el mismo color que la ventana) y un contorno 2px del mismo gris
  recesivo que el secundario — insinúa el botón sin llenarlo ni
  competir en atención con ningún botón habilitado.
- Todas las ventanas de HITO (sin barra de título del sistema) ahora
  tienen sombra nativa de Windows (`Set-SombraVentana`, `estilos.ps1`).
  Sin esto, dos ventanas de HITO superpuestas —por ejemplo "Acerca de"
  sobre la principal— no tenían ninguna señal visual de ser ventanas
  distintas.
- "Acerca de HITO" ahora abre centrada en altura sobre la ventana
  principal pero corrida hacia la derecha, en vez de exactamente encima
  (`Owner` + posicionamiento manual). Con el mismo ancho que la
  principal y ninguna de las dos con borde de sistema, quedar
  perfectamente superpuestas hacía indistinguible cuáles botones eran de
  cada ventana incluso con la sombra nueva.
- Capturas de `docs/` (`configurador.png`, `ventana_recordatorio.png`,
  `ventana_segundo_aviso.png`, `ventana_sin_red.png`) regeneradas desde
  el código final de esta sesión — reflejan la banda con logo, los
  botones de día y el botón deshabilitado con contorno. La sombra nativa
  no aparece en las capturas: se recortan al rectángulo exacto de la
  ventana (`GetWindowRect`), y la sombra de DWM se compone fuera de ese
  rectángulo — solo se ve al usar la app real.
- `instalar.bat` invoca PowerShell por ruta completa en vez de por
  nombre: `cmd.exe` busca primero en la carpeta actual antes que en el
  PATH, así que un archivo llamado `powershell.exe`/`.bat`/`.cmd`
  plantado junto al instalador se habría ejecutado en su lugar. Hallazgo
  de seguridad severidad media de la auditoría del 2026-07-12,
  inconsistente con la misma política ya aplicada al resto de los
  ejecutables del sistema (`constantes.ps1`).
- `acerca_de.ps1` invoca `explorer.exe` por ruta completa (nueva
  constante `$HitoRutaExplorer`), en vez de por nombre — mismo hallazgo
  y misma corrección que `instalar.bat`, severidad baja en este caso.
- `lanzar.vbs` rechaza también argumentos que terminan en backslash: en
  la línea de comandos de Windows, un backslash justo antes de la
  comilla de cierre la "escapa" en vez de cerrarla, fusionando ese
  argumento con el siguiente. Hallazgo de seguridad severidad baja
  (riesgo latente, no explotable con el código actual).

### Cambiado
- `instalar.bat` simplificado: delega la creación de tareas programadas y
  accesos directos a `crear_tareas.ps1` en vez de usar `schtasks /TR` y
  `powershell -Command` con rutas interpoladas manualmente.
- `hito.ps1`: la lógica de verificación de red y de registro en el log se
  extrajo de los manejadores de clic de los botones a funciones propias.
- Auditoría de interfaz (`/ui`): mnemónicos de teclado (`&Guardar`,
  `&Cancelar`, `&Examinar...`, `&Abrir planilla`, `&Ya las completé`) en
  ambos formularios.
- Botones con estado visual al pasar el mouse y al hacer clic
  (`FlatAppearance.MouseOverBackColor`/`MouseDownBackColor`) en todos los
  botones de `hito.ps1` y `configurar.ps1`.
- El campo de la planilla en `configurar.ps1` deja de ser de solo lectura:
  ahora se puede pegar una ruta manualmente además de usar "Examinar".
- Output de `crear_tareas.ps1` y `aplicar_horarios.ps1` coloreado por
  severidad (`[OK]` verde, `[ERROR]` rojo, `[AVISO]` amarillo, `[INFO]` cian).
- El título de la ventana principal pasa de "HITO – Configuración" a
  simplemente "HITO", consistente con el acceso directo del Menú Inicio.
- Se elimina el checkbox "Mismo horario para los días activos" y toda su
  lógica asociada (sincronización en vivo, día de referencia): tras
  revisarlo con `/evaluar`, el ahorro de tipeo no justificaba la
  complejidad ni el bug que había generado. Cada día activo se edita
  siempre de forma independiente.
- La sección de días de `configurar.ps1` pasa de 1 columna × 7 filas a una
  grilla de 2 columnas × 4 filas (Lunes/Martes, Miércoles/Jueves,
  Sábado/Domingo, Domingo solo), eliminando el espacio vacío excesivo de
  la versión anterior. La ventana se achica de 460×560 a 460×435.
- Texto secundario que había quedado más chico que el resto (8pt) sube a
  9pt: labels de campo en "Acerca de", hint de formato de hora, botón
  "Acerca de".
- Título, versión y descripción se centran en las ventanas tipo popup
  (`hito.ps1` y `acerca_de.ps1`); `configurar.ps1` mantiene alineación a
  la izquierda por ser un formulario con secciones, no un popup.
- Los campos de ruta en "Acerca de" (Datos de usuario, Archivo de log)
  pierden el borde y pasan a fondo gris (igual al de la ventana) en vez
  de blanco, para que se vean como texto informativo y no como un campo
  editable — siguen siendo seleccionables y copiables con el mouse.
- El hint "Formato 24 hs. Ej: 17:30" ahora aclara que también se acepta
  punto o coma como separador, ya que antes el texto no lo mencionaba.
- Revisión ortográfica completa del repositorio (comentarios, docstrings,
  textos de interfaz y documentación): tildes, ñ y puntuación correctos en
  español rioplatense. Sin cambios de comportamiento. `instalar.bat` queda
  como excepción deliberada — es ASCII puro sin BOM para evitar que los
  tildes se muestren corruptos en el codepage por defecto de `cmd.exe`.
- La versión del software vive solo en `constantes.ps1` (`$HitoVersion`):
  se eliminó de los headers de los scripts y del banner de `instalar.bat`,
  que ya habían quedado desactualizados entre sí.
- Constantes compartidas nuevas en `constantes.ps1`: autor, URL del
  repositorio, carpeta del Menú Inicio, nombre de la carpeta de logs,
  intervalo del chequeo de red y extensiones de planilla reconocidas
  (antes duplicadas o hardcodeadas en varios scripts).
- Conjugación unificada en voseo en todos los textos de la interfaz
  ("Verificá", "Completá", "Seleccioná", "Usá"), que mezclaban tuteo y
  voseo en una misma ventana.
- El manejador del botón Guardar de `configurar.ps1` se partió en
  funciones con una responsabilidad cada una (`Get-HorasActivas`,
  `Show-AvisoValidacion`, `Set-FormularioOcupado`).
- CI endurecido: el workflow declara `permissions: contents: read`,
  `actions/checkout` queda fijada por SHA en vez de por tag, y
  PSScriptAnalyzer y Pester se instalan con versión exacta.
- **Refactor visual completo** tras auditoría `/ui` aprobada por el usuario:
  - Corregido el bug de layout que hacía que el margen derecho fuera más
    angosto que el izquierdo en todas las ventanas: los controles se
    posicionaban contra `Form.Size` (que incluye bordes del sistema) en
    vez de `ClientSize` (el área útil real). Ahora todo el layout usa
    `ClientSize` con margen uniforme de 24 px.
  - Paleta nueva "Petróleo y ámbar" (primario #0E7490, banda #164E63,
    ámbar #B45309 para "sin red", rojo #B91C1C para segundo aviso), en
    reemplazo del azul genérico de Windows. Confirmada como definitiva
    por el usuario tras comparar capturas reales contra la alternativa
    "Índigo sobrio", que se descartó y eliminó de `estilos.ps1`.
  - Las ventanas de aviso (recordatorio, Acerca de y diálogos) pierden la
    barra de título del sistema: banda propia integrada con el título y
    una ✕ (misma lógica de cierre), esquinas rectas también en Windows 11
    (vía DWM), borde de 1 px, arrastrables desde la banda y sin botón en
    la barra de tareas (no aparece más el ícono de PowerShell).
  - Popups: título 15 pt, texto auxiliar 10 pt, todo centrado de verdad,
    y botones apilados de ancho completo (acción principal arriba).
  - Nuevos diálogos propios (`Show-DialogoHito`) en reemplazo de todos los
    `MessageBox` nativos, con el mismo lenguaje visual (única excepción:
    el aviso "esta carpeta no es una instalación de HITO" del
    desinstalador, que no puede asumir que `estilos.ps1` exista).
  - Ventana principal: márgenes simétricos, encabezados de sección en
    mayúsculas, días rediseñados como botones apilados (uno por fila) que
    al activarse se llenan con el color primario y desbloquean el campo
    de hora al lado; Guardar pasa abajo a la derecha (convención de
    diálogos).
  - "Acerca de": mismo ancho que la ventana principal y rutas en campos
    de dos líneas con ajuste de palabra — ya no se recortan.
  - La ventana principal también pasa al tratamiento popup (banda propia,
    esquinas rectas, botones armonizados), pero conservando su botón en
    la barra de tareas por ser la ventana principal, no un aviso.
  - La barra de tareas de Windows ahora muestra el ícono de HITO en vez
    del de PowerShell: cada proceso declara su propia identidad de
    aplicación (`SetCurrentProcessExplicitAppUserModelID`) antes de crear
    ventanas. El acceso directo del Menú Inicio también pasa a usar
    `hito.ico` (con el ícono genérico anterior como respaldo si falta).
  - El logo de HITO aparece integrado a la banda de título de todas las
    ventanas, a la izquierda del nombre (cargado con
    `ExtractAssociatedIcon` — `Icon.ToBitmap` falla con íconos que solo
    traen un frame de 256 px comprimido como PNG, como `hito.ico`).
    El título de la banda usa 10,5 pt para quedar proporcionado al logo.
  - El encabezado de la ventana principal pasa de "Configuración" a
    "Tus recordatorios": desde que da acceso a "Acerca de" y es la cara
    visible del software, era un nombre que le quedaba chico.
  - `New-VentanaHito` queda con una única variante (banda propia): la
    rama con borde estándar del sistema quedó sin usuarios tras pasar la
    ventana principal al tratamiento nuevo, y se eliminó como código
    muerto junto con el switch `-Popup`.
- Se crea `ROADMAP.md` con la primera mejora diferida: alternar idioma
  español/inglés (se reabre si aparece un usuario real de habla inglesa).
  Segunda entrada (2026-07-11): partir `estilos.ps1` en dos, diferido
  hasta superar ~600 líneas o agregar una cuarta ventana.
- README actualizado a la interfaz nueva: las 4 capturas de `docs/`
  regeneradas con el diseño actual, referencias "HITO → Configuración"
  reemplazadas por los nombres reales de la interfaz, la fila de
  problemas frecuentes pasa a "Planilla no encontrada" (el título real
  del aviso) y "tildar" pasa a "activar" (los días ahora son botones).
- Nueva sección "Actualizar HITO" en el README: actualizar es ejecutar
  una sola vez el instalador de la versión nueva (config e historial se
  conservan), con la variante "desinstalar primero" para quien quiera
  empezar el historial de cero.
- Constantes nuevas en `constantes.ps1`: nombre del archivo de log,
  identidad de aplicación (AppUserModelID) y rutas completas de
  `wscript.exe`/`powershell.exe`, antes repetidas o inline.

---

## [1.0.0] — 2026-05-15

### Agregado
- Ventana de recordatorio diario (lunes a viernes) a hora configurable.
- Segundo aviso automático a los 15 minutos si no hay respuesta.
- Botón "Abrir planilla" que lanza el archivo Excel directamente.
- Botón "Ya las completé" para cerrar el aviso y registrar el día como listo.
- Aviso en naranja cuando la carpeta de red no está disponible.
- Log acumulativo en `log.txt` (fecha, día, número de aviso, acción y hora).
- Formulario de configuración para seleccionar la planilla y ajustar horarios por día.
- Opción "Mismo horario todos los días" en el configurador.
- Validación de horarios en el configurador: un único mensaje de error por campo inválido, con restauración automática al último valor correcto guardado.
- Se acepta punto o coma como separador de hora (`17.30`, `17,30` equivalen a `17:30`).
- Instalador (`instalar.bat`) que crea las tareas programadas y los accesos directos del Menú Inicio.
- Desinstalador (`desinstalar.ps1`) que elimina tareas, accesos directos y carpeta de instalación, incluso cuando se ejecuta desde el acceso directo del Menú Inicio.
- Ejecución retroactiva: si la PC estaba apagada a la hora configurada, el aviso se muestra al volver.
- Ejecución silenciosa sin ventana de consola (vía `lanzar.vbs`).
- Soporte para ícono personalizado (`hito.ico`) con fallback silencioso si no existe.
- Íconos correctos en los accesos directos del Menú Inicio.
- El acceso directo en el Menú Inicio se llama "Configuración" (con tilde).