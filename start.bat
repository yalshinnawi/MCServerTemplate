@ECHO OFF
TITLE Create Aeronautics Server Launcher
PUSHD %~dp0

:: 1. Launch Playit.gg tunnel if present and not already running
IF EXIST "%~dp0playit.exe" (
    tasklist /FI "IMAGENAME eq playit.exe" 2>NUL | find /I /N "playit.exe" >NUL
    IF ERRORLEVEL 1 (
        ECHO Starting Playit.gg tunnel in background...
        start "Playit Tunnel" "%~dp0playit.exe"
    ) ELSE (
        ECHO Playit.gg tunnel is already active.
    )
)

:: 2. Portability check: if local java-runtime is missing, fallback to system Java 21
IF NOT EXIST "%~dp0java-runtime\jdk-21.0.13+9\bin\java.exe" (
    PowerShell -NoProfile -Command "$f = '%~dp0variables.txt'; if (Test-Path $f) { (Get-Content $f) -replace '^JAVA=.*', 'JAVA=java' -replace '^SKIP_JAVA_CHECK=.*', 'SKIP_JAVA_CHECK=false' | Set-Content $f }"
)

:: 3. Launch Minecraft Server
ECHO Starting Minecraft Server...
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& '%~dp0start.ps1' %*";
POPD
