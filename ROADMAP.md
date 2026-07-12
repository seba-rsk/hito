# ROADMAP — Mejoras diferidas

Mejoras identificadas y pospuestas a propósito, cada una con la condición
que la reactiva. Al implementar un ítem, se registra en `CHANGELOG.md` y se
quita de este archivo.

| Fecha | Mejora | Motivo del diferimiento | Condición que la reabre |
|---|---|---|---|
| 2026-07-10 | Alternar idioma español/inglés en la interfaz. | Implica extraer ~40 textos a una tabla de idioma, un selector en la ventana principal y persistir la preferencia — y hoy no hay ningún usuario que lo necesite (`KNOWN_ISSUES.md` ya documenta "sin soporte multi-idioma"). | Que aparezca un usuario real de habla inglesa que vaya a usar HITO. |
| 2026-07-11 | Partir `estilos.ps1` en dos archivos (interop nativo por un lado; paleta, fábricas de controles y diálogo por el otro). | Hoy tiene ~470 líneas cohesivas y funciona bien como fuente única; partirlo ahora agrega un archivo más a la raíz sin dolor real que lo justifique (detectado en la auditoría del 2026-07-11 como riesgo de escalabilidad, no como problema). | Que `estilos.ps1` supere las ~600 líneas o que se agregue una cuarta ventana compleja al software. |
