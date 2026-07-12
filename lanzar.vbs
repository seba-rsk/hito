' lanzar.vbs
' Ejecuta un script de PowerShell sin ventana de consola ni parpadeo.
' Uso: wscript.exe lanzar.vbs "ruta\script.ps1" [argumentos adicionales]
' Pensado solo para las rutas que crea el instalador (tareas programadas
' y accesos directos), no como lanzador de uso general.

Dim i

' Un argumento con comillas dobles romperia el armado del comando de abajo,
' y ninguna ruta real de Windows puede contenerlas: se rechaza por las dudas.
' Tambien se rechaza un argumento que termine en backslash: en la linea de
' comandos de Windows, un backslash justo antes de la comilla de cierre la
' "escapa" en vez de cerrarla, fusionando este argumento con el siguiente.
' Ninguna ruta real que use este lanzador (siempre un archivo .ps1) termina
' en backslash.
For i = 0 To WScript.Arguments.Count - 1
    If InStr(WScript.Arguments(i), Chr(34)) > 0 Then WScript.Quit 1
    If Right(WScript.Arguments(i), 1) = "\" Then WScript.Quit 1
Next

Set oShell = CreateObject("WScript.Shell")

' Ruta completa y no "powershell.exe" a secas: el nombre solo se resuelve
' via PATH del usuario, que es modificable.
sPowershell = oShell.ExpandEnvironmentStrings("%SystemRoot%") & "\System32\WindowsPowerShell\v1.0\powershell.exe"

sCmd = """" & sPowershell & """ -ExecutionPolicy Bypass -NonInteractive -WindowStyle Hidden -File """ & WScript.Arguments(0) & """"

For i = 1 To WScript.Arguments.Count - 1
    sCmd = sCmd & " """ & WScript.Arguments(i) & """"
Next

oShell.Run sCmd, 0, False
