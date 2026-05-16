' lanzar.vbs
' Ejecuta un script de PowerShell sin ventana de consola ni parpadeo.
' Uso: wscript.exe lanzar.vbs "ruta\script.ps1" [argumentos adicionales]

Set oShell = CreateObject("WScript.Shell")

sCmd = "powershell.exe -ExecutionPolicy Bypass -NonInteractive -WindowStyle Hidden -File """ & WScript.Arguments(0) & """"

Dim i
For i = 1 To WScript.Arguments.Count - 1
    sCmd = sCmd & " " & WScript.Arguments(i)
Next

oShell.Run sCmd, 0, False
