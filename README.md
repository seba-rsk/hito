# HITO

**Recordatorio diario para completar la planilla de horas**
Windows 10 / 11 · No requiere permisos de administrador · v1.1.0

![Versión](https://img.shields.io/badge/versión-1.1.0-blue)
![Licencia](https://img.shields.io/badge/licencia-MIT-green)
![Powershell](https://img.shields.io/badge/PowerShell-5.1+-yellow)
![Plataforma](https://img.shields.io/badge/plataforma-Windows-lightgrey)
![CI](https://github.com/seba-rsk/hito/actions/workflows/ci.yml/badge.svg)

---

## Capturas de pantalla

**Ventana de recordatorio**

![Ventana de recordatorio](https://raw.githubusercontent.com/seba-rsk/hito/refs/heads/main/docs/ventana_recordatorio.png)

**Ventana de recordatorio - Segundo aviso**

![Ventana de recordatorio - Segundo aviso](https://raw.githubusercontent.com/seba-rsk/hito/refs/heads/main/docs/ventana_segundo_aviso.png)

**Ventana principal**

![Ventana principal de HITO](https://raw.githubusercontent.com/seba-rsk/hito/refs/heads/main/docs/configurador.png)

**Red no disponible**

![Aviso de red no disponible](https://raw.githubusercontent.com/seba-rsk/hito/refs/heads/main/docs/ventana_sin_red.png)

---

## Qué hace

Los días que elijas (por defecto Lunes a Viernes, pero cualquier combinación de los 7 días es configurable), a la hora configurada, aparece una ventana que recuerda completar la planilla de horas antes de terminar el día.
Dos opciones:

- **Abrir planilla** — abre el archivo Excel directamente.
- **Ya las completé** — cierra el aviso y registra el día como listo.

Si no se responde en 15 minutos, aparece un segundo aviso. Cada interacción queda registrada en `logs\log.txt` (fecha, día, estado y hora). Desde **HITO → ⓘ Acerca de** se puede ver la versión instalada y abrir esa carpeta directamente.

---

## Estructura del proyecto

```
HITO/
├── hito.ps1                  # Script principal. Muestra la ventana de recordatorio.
├── configurar.ps1            # Ventana principal (configuración + Acerca de). Accesible desde el Menú Inicio.
├── acerca_de.ps1             # Ventana modal "Acerca de HITO".
├── desinstalar.ps1           # Desinstalador. Accesible desde el Menú Inicio.
├── aplicar_horarios.ps1      # Script auxiliar. Reaplica horarios guardados a las tareas.
├── crear_tareas.ps1          # Script auxiliar. Crea tareas programadas y accesos directos.
├── sincronizar_horarios.ps1  # Reconcilia tareas programadas contra los días activos.
├── constantes.ps1            # Fuente única de días, tareas programadas y valores por defecto.
├── estilos.ps1               # Paleta de colores y controles compartidos por las tres ventanas.
├── validaciones.psm1         # Lógica de validación de horarios, testeada con Pester.
├── configuracion.psm1        # Lectura de config.json, testeada con Pester.
├── lanzar.vbs                # Lanzador silencioso. Ejecuta los scripts sin ventana de consola.
├── instalar.bat              # Instalador. Ejecutar una vez por PC.
│
├── tests/
│   ├── Validaciones.Tests.ps1        # Tests Pester del módulo de validaciones.
│   ├── Configuracion.Tests.ps1       # Tests Pester de la lectura de config.json.
│   └── SincronizarHorarios.Tests.ps1 # Tests Pester de la reconciliación de tareas (mockea el Programador de tareas).
│
├── .github/
│   └── workflows/
│       └── ci.yml        # Pipeline de CI (sintaxis, encoding, lint y tests Pester).
│
├── docs/                 # Capturas de pantalla
│
├── hito.ico
├── README.md
├── CHANGELOG.md
├── KNOWN_ISSUES.md
├── LICENSE
└── .gitignore
```

Los siguientes archivos **no están en el repositorio** y se generan localmente:

| Archivo         | Cuándo se crea |
|-----------------|----------------|
| `config.json`   | Al guardar por primera vez desde la ventana principal de HITO. Contiene la ruta de la planilla y los días/horarios activos. |
| `logs\log.txt`  | Al primer uso del recordatorio. Una línea por interacción con fecha, día, estado y hora. |
| `hito.ico`      | No se genera automáticamente — colocarlo en la misma carpeta que `instalar.bat` para activar el ícono personalizado en las ventanas y accesos directos. |

---

## Instalación

Repetir estos pasos en cada equipo.

**Paso 1 — Ejecutar el instalador**

- Colocar todos los archivos del repositorio (`instalar.bat`, `hito.ps1`, `configurar.ps1`, `acerca_de.ps1`, `desinstalar.ps1`, `aplicar_horarios.ps1`, `crear_tareas.ps1`, `sincronizar_horarios.ps1`, `constantes.ps1`, `estilos.ps1`, `validaciones.psm1`, `configuracion.psm1`, `lanzar.vbs` y `hito.ico`) en la misma carpeta.
- Hacer doble clic en `instalar.bat`. La consola debe mostrar todos los mensajes `[OK]`.

**Paso 2 — Configurar la planilla personal**

- Abrir el Menú Inicio → carpeta **HITO** → **HITO**.
- Hacer clic en **Examinar** y seleccionar la planilla Excel personal (`.xlsm`, `.xlsx` o `.xls`).
- Activar los días que necesites (cada día es un botón; por defecto Lunes a Viernes) y ajustar la hora de cada uno (por defecto 17:30). Se acepta punto, coma o dos puntos como separador (`17.30`, `17,30` o `17:30`).
- Hacer clic en **Guardar**. Las tareas programadas se actualizan en el momento.

---

## Actualizar HITO

Para pasar de una versión anterior a una nueva **no hace falta desinstalar**:
ejecutar una sola vez el `instalar.bat` de la versión nueva, sobre la
instalación existente.

- Los archivos se reemplazan por los de la versión nueva.
- La configuración (`config.json`) y el historial (`logs\log.txt`) se
  conservan; los horarios guardados se reaplican automáticamente a las
  tareas programadas.
- Los accesos directos del Menú Inicio se regeneran.

> **Para empezar el historial de cero** (por ejemplo, si se viene de una
> versión con otro formato de log): desinstalar primero (Menú Inicio →
> HITO → **Desinstalar**) y recién después ejecutar el instalador nuevo.
> Atención: desinstalar borra también la configuración, así que habrá que
> volver a elegir la planilla y los días/horarios la primera vez.

---

## Archivos instalados

El instalador copia los archivos a `%USERPROFILE%\HITO` (por ejemplo `C:\Users\Juan\HITO`).
Esta es la única carpeta que usa el sistema. No se modifica el registro de Windows ni se instala ningún programa adicional.

### Archivos copiados por el instalador

| Archivo                     | Descripción |
|-----------------------------|-------------|
| `hito.ps1`                  | Script principal. Muestra la ventana de recordatorio. |
| `configurar.ps1`            | Ventana principal: configuración + acceso a Acerca de. |
| `acerca_de.ps1`             | Ventana modal "Acerca de HITO". |
| `desinstalar.ps1`           | Desinstalador. |
| `aplicar_horarios.ps1`      | Script auxiliar. Reaplica horarios guardados a las tareas programadas. |
| `crear_tareas.ps1`          | Script auxiliar. Crea las tareas programadas y los accesos directos del Menú Inicio. |
| `sincronizar_horarios.ps1`  | Crea, actualiza o elimina tareas programadas según los días activos. |
| `constantes.ps1`            | Fuente única de días, tareas programadas y valores por defecto. |
| `estilos.ps1`               | Paleta de colores y controles compartidos por las tres ventanas. |
| `validaciones.psm1`         | Lógica de validación de horarios usada por la ventana principal y el recordatorio. |
| `configuracion.psm1`        | Lectura de `config.json`, usada por el recordatorio, la ventana principal y la reaplicación de horarios. |
| `lanzar.vbs`                | Lanzador silencioso. Evita el parpadeo de consola al ejecutar los scripts. |
| `hito.ico`                  | Ícono de las ventanas. Solo se copia si estaba presente en la carpeta del instalador. |

### Archivos generados automáticamente

| Archivo | Cuándo se crea |
|---|---|
| `config.json` | Al guardar por primera vez desde la ventana principal de HITO. Contiene la ruta de la planilla y los días/horarios activos. |
| `logs\log.txt` | Al primer uso del recordatorio. Una línea por interacción con fecha, día, estado y hora. |

### ¿Se puede eliminar la carpeta original del instalador?

Sí. Una vez que `instalar.bat` terminó con todos los mensajes `[OK]`, los archivos ya están copiados en `%USERPROFILE%\HITO` y la carpeta original no es necesaria. Puede descartarse o guardarse como respaldo para reinstalar en otro equipo.

La excepción es `hito.ico`: si no estaba presente al instalar, se puede agregar luego re-ejecutando el instalador desde la carpeta original con el ícono incluido.

---

## Desinstalación

Abrir el Menú Inicio → carpeta **HITO** → **Desinstalar**.

Confirmar en la ventana de advertencia. El desinstalador elimina las tareas programadas, los accesos directos y la carpeta de instalación completa. No quedan rastros en el sistema.

> El sistema no modifica el registro de Windows ni instala ningún programa adicional.

---

## Cambiar la planilla, los días o el horario

Abrir el Menú Inicio → carpeta **HITO** → **HITO**.

El formulario muestra la configuración actual. Modificar lo necesario (planilla, qué días tienen recordatorio, hora de cada uno) y hacer clic en **Guardar**.
El cambio tiene efecto inmediato: las tareas programadas se crean, actualizan o eliminan solas según los días que queden activados, sin necesidad de tocar el Programador de tareas.

Hacer esto si se renombra la planilla, se empieza a usar un archivo nuevo (por ejemplo al inicio de cada año), si cambia el horario, o si cambian los días que necesitás recordatorio (por ejemplo, un cambio de turno).

---

## Probar sin esperar la hora configurada

Abrir PowerShell (sin necesidad de ejecutar como administrador) y usar los siguientes comandos.

**Ver la ventana de recordatorio**
```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\HITO\hito.ps1" -Test
```

**Simular el segundo aviso**
```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\HITO\hito.ps1" -Test -Segundo
```

**Abrir el configurador**
```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\HITO\configurar.ps1"
```

**Abrir el desinstalador**
```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\HITO\desinstalar.ps1"
```

**Simular red no disponible**
```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\HITO\hito.ps1" -Test -SinRed
```

---

## Comportamiento del sistema día a día

**Situación normal**
A la hora configurada aparece la ventana. Se hace clic en un botón y listo hasta el día siguiente.

**Si la PC estaba apagada o suspendida a la hora configurada**
El recordatorio se ejecuta automáticamente al volver a encender o desbloquear, siempre que sea el mismo día calendario. Si se retoma al día siguiente, no aparece ningún aviso.

**Si la red no está disponible**
La ventana aparece igual pero con un aviso en naranja indicando que la red no está disponible. El botón Abrir planilla muestra una advertencia adicional. El recordatorio nunca se cancela silenciosamente.

**Qué pasa con cada acción sobre el primer aviso**

| Acción                  | Cancela el segundo aviso | Registra en el log           |
|-------------------------|--------------------------|------------------------------|
| Abrir planilla          | Sí                       | Sí → "Abrió planilla"        |
| Ya las completé         | Sí                       | Sí → "Completado"            |
| Cerrar con la X         | **No**                   | Sí → "Cerrado sin respuesta" |
| Ignorar (dejar abierta) | **No**                   | No (hasta que se interactúe) |

Si no se hace nada en 15 minutos, la misma ventana se transforma en el segundo aviso (no se abre una ventana nueva) y queda registrado "Mostrado" en el log. El comportamiento de los botones es idéntico al del primero. Si tampoco se responde el segundo aviso, queda registrado "Cerrado sin respuesta" al cerrarlo, o nada si se deja abierto indefinidamente.

**Formato del log**

Cada interacción queda en una línea del archivo `logs\log.txt`. El log es acumulativo, todas las acciones del día quedan registradas, no solo la última.

```
2026-05-12 | Martes | 1er aviso | Cerrado sin respuesta | 17:33
2026-05-12 | Martes | 2do aviso | Mostrado              | 17:48
2026-05-12 | Martes | 2do aviso | Abrió planilla        | 17:51
```

---

## Requisitos

- Windows 10 u 11.
- Acceso a la unidad o carpeta de red donde está guardada la planilla personal (unidad mapeada, ruta UNC `\\servidor\carpeta`, o archivo local).
- PowerShell (incluido en todas las versiones de Windows 10 y 11).

---

## Resolución de problemas

| Problema | Solución |
|----------|----------|
| No aparece el recordatorio a la hora configurada | Verificar que la tarea del día en cuestión (`HITO_Lun` / `_Mar` / `_Mie` / `_Jue` / `_Vie` / `_Sab` / `_Dom`) exista y esté habilitada en el Programador de tareas, y que ese día esté activado en la ventana principal de HITO (Menú Inicio → HITO). |
| Aparece "Planilla no encontrada" | Verificar que la unidad de red esté conectada y que la ruta sea exacta. Abrir HITO desde el Menú Inicio y seleccionar el archivo nuevamente con Examinar. |
| No aparece la carpeta HITO en el Menú Inicio | Re-ejecutar `instalar.bat`. |
| Error al ejecutar el script manualmente | Usar siempre el archivo `.ps1` descargado. No copiar y pegar el contenido en un archivo nuevo, ya que puede alterar el encoding y romper el script. |
| El horario no se aplica correctamente | Abrir HITO desde el Menú Inicio y verificar la hora del día en cuestión (formato `HH:MM`, `HH.MM` o `HH,MM`, 24 horas). Confirmar que ese día esté activado. |
| El segundo aviso no aparece | Es la misma ventana del primer aviso, que se transforma sola a los 15 minutos si nadie respondió — no hace falta que aparezca una ventana nueva. Si se hizo clic en cualquier botón del primer aviso, se cancela automáticamente. Si el popup fue cerrado con la X o ignorado, el segundo aviso sí debería aparecer en la misma ventana. |
| No se puede seleccionar la planilla con Examinar | Verificar que la unidad de red esté montada antes de abrir HITO. |
| La ventana aparece aunque ya se completó la planilla | Suele pasar si el popup fue cerrado con la X en lugar de usar el botón. Siempre hacer clic en **Ya las completé** para cerrar correctamente. |
| Las ventanas no muestran el ícono de HITO | El archivo `hito.ico` no estaba presente al instalar. Colocarlo en la misma carpeta que `instalar.bat` y re-ejecutar el instalador. |
| No encuentro el log de actividad | Ahora vive en `%USERPROFILE%\HITO\logs\log.txt`, no suelto en la carpeta de instalación. Se puede abrir directo desde HITO → ⓘ Acerca de → "Abrir carpeta de logs". |

---

## Limitaciones conocidas

Ver [KNOWN_ISSUES.md](KNOWN_ISSUES.md).

---

## Changelog

Ver [CHANGELOG.md](CHANGELOG.md).

---

## Licencia

MIT — ver [LICENSE](LICENSE).

---

## Autor

Desarrollado por **Sebastián A. Roskopf** — [GitHub](https://github.com/seba-rsk)