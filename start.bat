@echo off
setlocal EnableDelayedExpansion
title Create Aeronautics Minecraft Server
pushd "%~dp0"

REM ==============================================================================
REM Create Aeronautics Server - Unified Native Launcher (Windows)
REM ==============================================================================

set "ACTION=%~1"
set "OPT_TUNNEL=1"

REM Command line parsing
if "%ACTION%"=="" goto START_SERVER
if /i "%ACTION%"=="help" goto PRINT_HELP
if /i "%ACTION%"=="-h" goto PRINT_HELP
if /i "%ACTION%"=="--help" goto PRINT_HELP
if /i "%ACTION%"=="backup" goto CMD_BACKUP
if /i "%ACTION%"=="-local" set "OPT_TUNNEL=0"
if /i "%ACTION%"=="--no-tunnel" set "OPT_TUNNEL=0"
if /i "%ACTION%"=="-notunnel" set "OPT_TUNNEL=0"
if /i "%~2"=="-local" set "OPT_TUNNEL=0"
if /i "%~2"=="--no-tunnel" set "OPT_TUNNEL=0"
if /i "%~2"=="-notunnel" set "OPT_TUNNEL=0"
goto START_SERVER

:START_SERVER
echo ==============================================================================
echo       Create Aeronautics Skybound - Native Server Launcher
echo ==============================================================================
echo.

REM 1. Java 21 Detection
set "JAVA_CMD="

REM Check if system Java is available and >= 21
where java >nul 2>&1
if errorlevel 1 goto CHECK_LOCAL_JAVA

for /f "tokens=3" %%v in ('java -version 2^>^&1 ^| findstr /i "version"') do (
    set "RAW_VER=%%~v"
    set "RAW_VER=!RAW_VER:"=!"
    for /f "tokens=1 delims=." %%m in ("!RAW_VER!") do set "JAVA_MAJOR=%%m"
)

if not defined JAVA_MAJOR goto CHECK_LOCAL_JAVA
if !JAVA_MAJOR! LSS 21 goto CHECK_LOCAL_JAVA

set "JAVA_CMD=java"
echo [OK] Detected System Java !JAVA_MAJOR!
goto JAVA_FOUND

:CHECK_LOCAL_JAVA
for /f "delims=" %%j in ('dir /b /s "%~dp0java-runtime\*java.exe" 2^>nul') do (
    if exist "%%j" (
        set "JAVA_CMD=%%j"
        echo [OK] Using local bundled Java runtime: %%j
        goto JAVA_FOUND
    )
)

:INSTALL_JAVA_PROMPT
echo [WARN] Java 21 was not found on your system.
where winget >nul 2>&1
if errorlevel 1 goto MANUAL_JAVA_INSTALL

echo [INFO] Installing OpenJDK 21 via Windows Package Manager winget...
winget install EclipseAdoptium.Temurin.21.JDK --accept-package-agreements --accept-source-agreements
echo [INFO] Re-checking Java installation...
where java >nul 2>&1
if errorlevel 1 goto RESTART_REQUIRED

set "JAVA_CMD=java"
echo [OK] Java 21 installed successfully.
goto JAVA_FOUND

:RESTART_REQUIRED
echo [ACTION REQUIRED] Please restart your terminal/PC to complete Java installation.
popd
pause
exit /b 1

:MANUAL_JAVA_INSTALL
echo [ERROR] Java 21 is required. Please download and install Eclipse Temurin 21 from:
echo https://adoptium.net/temurin/releases/?version=21
popd
pause
exit /b 1

:JAVA_FOUND
REM 2. Verify EULA acceptance
if exist "%~dp0eula.txt" (
    findstr /i "eula=true" "%~dp0eula.txt" >nul 2>&1
    if errorlevel 1 (
        echo eula=true> "%~dp0eula.txt"
        echo [OK] Minecraft EULA accepted in eula.txt
    )
) else (
    echo eula=true> "%~dp0eula.txt"
    echo [OK] Created eula.txt with eula=true
)

REM 3. Launch Playit.gg tunnel if requested
if "%OPT_TUNNEL%"=="1" (
    if exist "%~dp0playit.exe" (
        tasklist /FI "IMAGENAME eq playit.exe" 2>nul | find /I /N "playit.exe" >nul
        if errorlevel 1 (
            echo [INFO] Starting Playit.gg WAN tunnel in background...
            start "Playit Tunnel" /min "%~dp0playit.exe"
        ) else (
            echo [OK] Playit.gg WAN tunnel is already running.
        )
    ) else (
        echo [WARN] playit.exe not found in server directory.
    )
)

REM 4. Launch NeoForge Server
echo [INFO] Booting NeoForge Minecraft Server...
echo [INFO] Memory and JVM flags: user_jvm_args.txt
echo ==============================================================================
echo.

"%JAVA_CMD%" @user_jvm_args.txt @libraries/net/neoforged/neoforge/21.1.264/win_args.txt nogui %*

echo.
echo [INFO] Minecraft server has stopped.
popd
pause
exit /b 0

REM ==============================================================================
REM BACKUP COMMAND
REM ==============================================================================
:CMD_BACKUP
echo [INFO] Creating timestamped backup of world...
if not exist "%~dp0world" (
    echo [ERROR] No world folder found to backup.
    popd
    pause
    exit /b 1
)
if not exist "%~dp0backups" mkdir "%~dp0backups"

for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value 2^>nul') do set "LDT=%%I"
set "TIMESTAMP=%LDT:~0,4%-%LDT:~4,2%-%LDT:~6,2%_%LDT:~8,2%-%LDT:~10,2%"
set "BACKUP_FILE=%~dp0backups\world-%TIMESTAMP%.zip"

powershell -NoProfile -Command "Compress-Archive -Path '%~dp0world' -DestinationPath '%BACKUP_FILE%' -Force"
if exist "%BACKUP_FILE%" (
    echo [SUCCESS] Backup created at: %BACKUP_FILE%
) else (
    echo [ERROR] Backup failed.
)
popd
pause
exit /b 0

REM ==============================================================================
REM HELP
REM ==============================================================================
:PRINT_HELP
echo ==============================================================================
echo  Create Aeronautics Skybound - Native Server Launcher
echo ==============================================================================
echo Usage: start.bat [command] [options]
echo.
echo Commands:
echo   (no arguments)     Start the Minecraft server + Playit.gg tunnel for friends (Default)
echo   -local             Start server in local LAN mode (no tunnel)
echo   backup             Safely compress the world folder into ./backups/
echo   help               Show this help message
echo.
echo Configuration files:
echo   user_jvm_args.txt  Set RAM allocation (-Xmx8G) and garbage collection flags
echo   server.properties  Server settings, difficulty, view distance, port
echo ==============================================================================
popd
exit /b 0
