@echo off
setlocal enabledelayedexpansion

set "OUTPUT=..\dart_code.txt"
set "FOLDER=%~dp0lib"
set "COUNT=0"

if exist "%OUTPUT%" del "%OUTPUT%"

echo // ============================================================================ > "%OUTPUT%"
echo // Dart Code - Vee App >> "%OUTPUT%"
echo // Generated: %date% >> "%OUTPUT%"
echo // ============================================================================ >> "%OUTPUT%"
echo. >> "%OUTPUT%"

for /r "%FOLDER%" %%f in (*.dart) do (
    echo // --------------------------------------------------------------------------- >> "%OUTPUT%"
    echo // FILE: %%~nxf >> "%OUTPUT%"
    echo // --------------------------------------------------------------------------- >> "%OUTPUT%"
    type "%%f" >> "%OUTPUT%"
    echo. >> "%OUTPUT%"
    echo. >> "%OUTPUT%"
    set /a COUNT+=1
)

echo // ============================================================================ >> "%OUTPUT%"
echo // Total files: !COUNT! >> "%OUTPUT%"
echo // ============================================================================ >> "%OUTPUT%"

echo Done. !COUNT! Dart files consolidated to %OUTPUT%
