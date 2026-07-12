#Requires -Version 5.1
# Configuracion.Tests.ps1
# Tests Pester para configuracion.psm1 (lectura de config.json).

BeforeAll {
    $moduloPath = Join-Path $PSScriptRoot "..\configuracion.psm1"
    Import-Module $moduloPath -Force
    $script:configTemp = Join-Path $TestDrive "config.json"
}

Describe "Get-HitoConfig" {

    It "indica que no existe cuando el archivo no está" {
        $r = Get-HitoConfig -RutaConfig (Join-Path $TestDrive "no_existe.json")
        $r.Existe | Should -Be $false
        $r.Ok | Should -Be $false
        $r.Planilla | Should -Be ""
        $r.Horarios.Count | Should -Be 0
    }

    It "lee la planilla y los horarios de un archivo válido" {
        @'
{
    "planilla": "C:\\Proyectos\\planilla.xlsx",
    "horarios": { "Lunes": "17:30", "Martes": "9:05" }
}
'@ | Set-Content -Path $configTemp -Encoding UTF8

        $r = Get-HitoConfig -RutaConfig $configTemp
        $r.Existe | Should -Be $true
        $r.Ok | Should -Be $true
        $r.Planilla | Should -Be "C:\Proyectos\planilla.xlsx"
        $r.Horarios["Lunes"] | Should -Be "17:30"
        $r.Horarios["Martes"] | Should -Be "9:05"
    }

    It "recorta espacios alrededor de la ruta de la planilla" {
        @'
{ "planilla": "  C:\\Proyectos\\planilla.xlsx  ", "horarios": {} }
'@ | Set-Content -Path $configTemp -Encoding UTF8

        (Get-HitoConfig -RutaConfig $configTemp).Planilla | Should -Be "C:\Proyectos\planilla.xlsx"
    }

    It "devuelve planilla vacía y sin horarios cuando el JSON es válido pero no tiene esas claves" {
        '{}' | Set-Content -Path $configTemp -Encoding UTF8

        $r = Get-HitoConfig -RutaConfig $configTemp
        $r.Ok | Should -Be $true
        $r.Planilla | Should -Be ""
        $r.Horarios.Count | Should -Be 0
    }

    It "marca Ok en false cuando el JSON está dañado, sin lanzar excepción" {
        "{ esto no es JSON valido" | Set-Content -Path $configTemp -Encoding UTF8

        $r = Get-HitoConfig -RutaConfig $configTemp
        $r.Existe | Should -Be $true
        $r.Ok | Should -Be $false
        $r.Planilla | Should -Be ""
        $r.Horarios.Count | Should -Be 0
    }
}
