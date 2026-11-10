@echo off
chcp 65001 >nul
title Optimizare Rapida Discord
echo ================================================================
echo Pornire optimizare automata Discord...
echo ================================================================

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Optimize-Discord.ps1" -Auto

echo.
echo ================================================================
echo Optimizarea este completa! Poti redeschide Discord.
echo ================================================================
pause
