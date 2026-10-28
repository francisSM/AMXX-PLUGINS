@echo off
setlocal enabledelayedexpansion
title AMX Mod X Pawn Compiler

set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"

set AMXXPC="%SCRIPT_DIR%amxxpc.exe"
set INCLUDES=-i"%SCRIPT_DIR%..\include" -i"%SCRIPT_DIR%..\plugins\antispam\scripting\include" -i"%SCRIPT_DIR%..\plugins\server_mute\scripting\include"

if "%~1"=="" goto compile_all

:compile_single
set SOURCE_FILE=%~f1
set OUTPUT_FILE=%~dpn1.amxx
echo Compilando: %SOURCE_FILE%
%AMXXPC% "%SOURCE_FILE%" %INCLUDES% -o"%OUTPUT_FILE%"
if %ERRORLEVEL% EQU 0 (
    echo [EXITO] Compilacion finalizada: %OUTPUT_FILE%
) else (
    echo [ERROR] Fallo la compilacion.
)
goto end

:compile_all
echo ========================================================
echo   Compilador AMX Mod X 1.10 - Compilando todos los plugins
echo ========================================================
echo.

for /r "%SCRIPT_DIR%..\plugins" %%f in (*.sma) do (
    set FILE=%%f
    set OUT=%%~dpnf.amxx
    echo ----------------------------------------------------
    echo Compilando: %%~nxf
    %AMXXPC% "%%f" %INCLUDES% -o"!OUT!"
    if !ERRORLEVEL! EQU 0 (
        echo [OK] Generado: !OUT!
    ) else (
        echo [ERROR] Error al compilar %%~nxf
    )
)

:end
echo.
echo Proceso finalizado.
pause
