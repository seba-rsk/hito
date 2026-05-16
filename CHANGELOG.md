# Changelog

Todos los cambios notables de HITO se documentan en este archivo.

El formato sigue [Keep a Changelog](https://keepachangelog.com/es/1.0.0/).
El versionado sigue [Semantic Versioning](https://semver.org/lang/es/).

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
- Ejecución silenciosa sin ventana de consola (via `lanzar.vbs`).
- Soporte para ícono personalizado (`hito.ico`) con fallback silencioso si no existe.
- Íconos correctos en los accesos directos del Menú Inicio.
- El acceso directo en el Menú Inicio se llama "Configuración" (con tilde).