@echo off
chcp 65001 >nul
title Discord Stream Optimizer

:: Verificare dacă rulează cu drepturi de Administrator (opțional dar recomandat)
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [Administrator detectat]
) else (
    echo [Rulare în mod utilizator standard]
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Optimize-Discord.ps1"

pause
