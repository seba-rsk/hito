#Requires -Version 5.1
# Validaciones.Tests.ps1
# Tests Pester para validaciones.psm1 (lógica de validación de horarios).

BeforeAll {
    $moduloPath = Join-Path $PSScriptRoot "..\validaciones.psm1"
    Import-Module $moduloPath -Force
}

Describe "ConvertTo-HoraNormalizada" {

    It "convierte el punto en dos puntos" {
        ConvertTo-HoraNormalizada "17.30" | Should -Be "17:30"
    }

    It "convierte la coma en dos puntos" {
        ConvertTo-HoraNormalizada "17,30" | Should -Be "17:30"
    }

    It "deja igual una hora ya normalizada" {
        ConvertTo-HoraNormalizada "17:30" | Should -Be "17:30"
    }

    It "recorta los espacios alrededor" {
        ConvertTo-HoraNormalizada " 17:30 " | Should -Be "17:30"
    }

    It "no convierte en hora válida un texto sin sentido" {
        (Test-HoraValida (ConvertTo-HoraNormalizada "abc")).Valida | Should -Be $false
    }
}

Describe "Test-HoraValida" {

    It "acepta una hora válida en formato HH:MM" {
        (Test-HoraValida "17:30").Valida | Should -Be $true
    }

    It "acepta una hora válida de un solo dígito en las horas" {
        (Test-HoraValida "9:05").Valida | Should -Be $true
    }

    It "rechaza un formato sin dos puntos" {
        $r = Test-HoraValida "1730"
        $r.Valida | Should -Be $false
        $r.Motivo | Should -Be "formato"
    }

    It "rechaza una hora fuera de rango (24 horas)" {
        $r = Test-HoraValida "24:00"
        $r.Valida | Should -Be $false
        $r.Motivo | Should -Be "rango"
    }

    It "rechaza minutos fuera de rango" {
        $r = Test-HoraValida "17:60"
        $r.Valida | Should -Be $false
        $r.Motivo | Should -Be "rango"
    }

    It "rechaza texto vacío" {
        (Test-HoraValida "").Valida | Should -Be $false
    }

    It "rechaza texto sin sentido" {
        (Test-HoraValida "abc").Valida | Should -Be $false
    }
}

Describe "Test-Inputs" {

    It "rechaza cuando falta la ruta de la planilla" {
        $horas = [ordered]@{ Lunes = "17:30" }
        $r = Test-Inputs -RutaPlanilla "" -Horas $horas
        $r.Ok | Should -Be $false
        $r.MotivoTipo | Should -Be "planilla"
    }

    It "rechaza cuando ningún día está activo" {
        $horas = [ordered]@{}
        $r = Test-Inputs -RutaPlanilla "C:\planilla.xlsx" -Horas $horas
        $r.Ok | Should -Be $false
        $r.MotivoTipo | Should -Be "sin_dias"
    }

    It "rechaza cuando un día tiene formato inválido y devuelve cuál" {
        $horas = [ordered]@{ Lunes = "17:30"; Martes = "17.xx" }
        $r = Test-Inputs -RutaPlanilla "C:\planilla.xlsx" -Horas $horas
        $r.Ok | Should -Be $false
        $r.MotivoTipo | Should -Be "hora"
        $r.Dia | Should -Be "Martes"
        $r.Motivo | Should -Be "formato"
    }

    It "rechaza cuando un día tiene la hora fuera de rango y devuelve cuál" {
        $horas = [ordered]@{ Lunes = "17:30"; Martes = "24:00" }
        $r = Test-Inputs -RutaPlanilla "C:\planilla.xlsx" -Horas $horas
        $r.Ok | Should -Be $false
        $r.MotivoTipo | Should -Be "hora"
        $r.Dia | Should -Be "Martes"
        $r.Motivo | Should -Be "rango"
    }

    It "acepta horas válidas y devuelve el hashtable normalizado" {
        $horas = [ordered]@{ Lunes = "9:05"; Martes = "17:30" }
        $r = Test-Inputs -RutaPlanilla "C:\planilla.xlsx" -Horas $horas
        $r.Ok | Should -Be $true
        $r.HorasNormalizadas["Lunes"] | Should -Be "09:05"
        $r.HorasNormalizadas["Martes"] | Should -Be "17:30"
    }

    It "acepta punto o coma como separador y normaliza a dos puntos" {
        $horas = [ordered]@{ Lunes = "17.30"; Martes = "9,05" }
        $r = Test-Inputs -RutaPlanilla "C:\planilla.xlsx" -Horas $horas
        $r.Ok | Should -Be $true
        $r.HorasNormalizadas["Lunes"] | Should -Be "17:30"
        $r.HorasNormalizadas["Martes"] | Should -Be "09:05"
    }
}
