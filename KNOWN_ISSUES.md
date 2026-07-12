# Limitaciones conocidas

Este archivo documenta comportamientos y limitaciones reales de HITO que no
son bugs, pero que conviene conocer antes de instalar o antes de reportar
un problema.

---

## Una sola planilla por instalación

Cada instalación de HITO (una por usuario de Windows, en `%USERPROFILE%\HITO`)
guarda una única ruta de planilla en `config.json`. No hay forma de configurar
más de una planilla ni de alternar entre proyectos distintos desde la misma
cuenta sin reconfigurar manualmente en Configuración cada vez.

## No distingue feriados

El recordatorio se dispara los días activos configurados (por defecto Lunes
a Viernes, pero cualquier combinación de los 7 días es configurable) a la
hora configurada, sin excepción. No hay soporte para feriados ni para
pausar temporalmente los avisos en una fecha puntual — la única forma de
detenerlos ese día es desactivarlo manualmente en Configuración y volver a
activarlo después, o desinstalar.

## La detección de "red disponible" no verifica permisos ni bloqueos

`Test-Path` sobre la carpeta de la planilla solo confirma que la carpeta es
accesible, no que el archivo se pueda abrir. Si la planilla está bloqueada
por otra persona (modo exclusivo de Excel) o el usuario no tiene permiso de
escritura, HITO igual intenta abrirla — el aviso de "solo lectura" o de
archivo bloqueado lo muestra Excel, no HITO.

## Cerrar la ventana con la X no cancela el segundo aviso

Es un comportamiento intencional, no un bug: si se cierra el popup con la X
o se lo ignora, el segundo aviso a los 15 minutos aparece igual. Solo los
botones "Abrir planilla" y "Ya las completé" lo cancelan. Está documentado
también en el README, tabla "Qué pasa con cada acción sobre el primer aviso".

## Reinstalar sobreescribe cambios manuales en el Programador de tareas

Si alguien edita directamente alguna tarea `HITO_*` desde el Programador de
tareas de Windows (en vez de usar HITO → Configuración), esos cambios se
pierden la próxima vez que se ejecute `instalar.bat` o se guarde algo desde
Configuración.

## Las tareas eliminadas pueden tardar en desaparecer de la vista

Al desinstalar (o al desactivar un día desde Configuración), la tarea
programada se elimina correctamente, pero el Programador de tareas de
Windows (`taskschd.msc`) o una consulta posterior pueden tardar uno o dos
minutos en reflejarlo — es una demora del propio Windows, no de HITO. Si
revisás inmediatamente después y la tarea todavía aparece, esperá un
momento y volvé a consultar antes de asumir que algo falló.

## Sin soporte multi-idioma

Los mensajes de la interfaz están fijos en español. No hay mecanismo de
traducción.

## Tareas programadas bloqueadas por política de grupo

En equipos corporativos donde el Programador de tareas de Windows está
restringido por política de grupo, la creación de las tareas puede fallar.
El instalador avisa `[AVISO] Hubo problemas creando alguna tarea programada`
en ese caso, pero no hay forma de sortear la restricción desde HITO — hay
que pedir al área de IT que habilite el Programador de tareas para el
usuario.
