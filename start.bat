@echo off
setlocal EnableDelayedExpansion
title Create Aeronautics Minecraft Server
pushd "%~dp0"

REM ==============================================================================
REM Create Aeronautics Server - Single Unified Management Script (Windows)
REM Usage:
REM   start.bat                (Double-click or run: checks deps, boots server, tails logs)
REM   start.bat -tunnel        (Boots server + Playit tunnel for internet play)
REM   start.bat stop           (Safely shuts down server)
REM   start.bat logs           (Stream live server logs)
REM   start.bat rcon [cmd]     (Open interactive console or run a Minecraft command)
REM   start.bat backup         (Zero-downtime world flush and compressed backup)
REM   start.bat setup          (Verify/install Docker, WSL2, and tune .wslconfig)
REM ==============================================================================

set "CONTAINER_NAME=mc-create-server"
set "DATA_DIR=%~dp0data"
set "BACKUP_DIR=%~dp0backups"

set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=up"
if /i "%ACTION%"=="-tunnel" (
    set "ACTION=up"
    set "OPT_TUNNEL=1"
)
if /i "%ACTION%"=="--tunnel" (
    set "ACTION=up"
    set "OPT_TUNNEL=1"
)
if /i "%~2"=="-tunnel" set "OPT_TUNNEL=1"
if /i "%~2"=="--tunnel" set "OPT_TUNNEL=1"

REM Command Router
if /i "%ACTION%"=="up" goto CMD_UP
if /i "%ACTION%"=="start" goto CMD_UP
if /i "%ACTION%"=="down" goto CMD_DOWN
if /i "%ACTION%"=="stop" goto CMD_DOWN
if /i "%ACTION%"=="restart" goto CMD_RESTART
if /i "%ACTION%"=="logs" goto CMD_LOGS
if /i "%ACTION%"=="rcon" goto CMD_RCON
if /i "%ACTION%"=="console" goto CMD_RCON
if /i "%ACTION%"=="backup" goto CMD_BACKUP
if /i "%ACTION%"=="setup" goto CMD_SETUP
if /i "%ACTION%"=="doctor" goto CMD_SETUP
if /i "%ACTION%"=="help" goto PRINT_HELP
if /i "%ACTION%"=="-h" goto PRINT_HELP
if /i "%ACTION%"=="--help" goto PRINT_HELP

echo [ERROR] Unknown command: %ACTION%
echo.
goto PRINT_HELP

REM ==============================================================================
REM 1. PREREQUISITE CHECKS & AUTO-BOOTSTRAP
REM ==============================================================================
:CHECK_PREREQS
echo ==========================================================
echo  Create Aeronautics Server Environment Pre-flight Checks
echo ==========================================================

REM 1.1 Check Docker installed
where docker >nul 2>&1
if errorlevel 1 (
    echo [WARN] Docker is not installed or not found in PATH.
    echo [INFO] Attempting to find Windows Package Manager winget...
    set "WINGET_CMD="
    where winget >nul 2>&1 && set "WINGET_CMD=winget"
    if not defined WINGET_CMD (
        if exist "%LOCALAPPDATA%\Microsoft\WindowsApps\winget.exe" (
            set "WINGET_CMD=%LOCALAPPDATA%\Microsoft\WindowsApps\winget.exe"
        )
    )
    if defined WINGET_CMD (
        echo [INFO] Installing Docker Desktop via winget...
        !WINGET_CMD! install Docker.DockerDesktop --accept-package-agreements --accept-source-agreements
        echo [SUCCESS] Docker Desktop installation package launched.
        echo [ACTION REQUIRED] Please complete the installer, reboot if prompted, and re-run start.bat.
        pause
        exit /b 1
    ) else (
        echo [ERROR] Please download and install Docker Desktop manually:
        echo https://www.docker.com/products/docker-desktop/
        pause
        exit /b 1
    )
)

REM 1.2 Check Docker daemon running
docker info >nul 2>&1
if errorlevel 1 (
    echo [INFO] Docker daemon is not currently active.
    echo [INFO] Launching Docker Desktop, please wait...
    if exist "%ProgramFiles%\Docker\Docker\Docker Desktop.exe" (
        start "" "%ProgramFiles%\Docker\Docker\Docker Desktop.exe"
    )
    set "RETRY_COUNT=0"
    :WAIT_DOCKER
    ping -n 4 127.0.0.1 >nul
    set /a RETRY_COUNT+=1
    docker info >nul 2>&1
    if not errorlevel 1 goto DOCKER_READY
    if !RETRY_COUNT! lss 20 (
        echo   ...waiting for Docker engine to initialize [!RETRY_COUNT! of 20]
        goto WAIT_DOCKER
    )
    echo [ERROR] Docker daemon did not start in time. Please verify Docker Desktop is running.
    pause
    exit /b 1
)
:DOCKER_READY
echo [OK] Docker daemon is healthy.

REM 1.3 Check & Tune .wslconfig for 16 GB Constrained Host
if not exist "%USERPROFILE%\.wslconfig" (
    echo [INFO] Generating optimized .wslconfig allocating 12 GB RAM, 4 CPU, 4 GB Swap...
    powershell -NoProfile -Command "[System.IO.File]::WriteAllText('$env:USERPROFILE\.wslconfig', \"[wsl2]`r`nmemory=12GB`r`nprocessors=4`r`nswap=4GB`r`nlocalhostForwarding=true`r`n\", [System.Text.Encoding]::UTF8)"
    echo [OK] Created .wslconfig in user profile.
)

REM 1.4 Check .env configuration
if not exist "%~dp0.env" (
    if exist "%~dp0.env.example" (
        echo [INFO] Creating .env from .env.example...
        copy /y "%~dp0.env.example" "%~dp0.env" >nul
    )
)

REM 1.5 Ensure data & backup directories exist
if not exist "%DATA_DIR%" mkdir "%DATA_DIR%"
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

REM 1.6 Seed ./data volume with template configs if mods directory is fresh
if not exist "%DATA_DIR%\mods" (
    if exist "%~dp0mods" (
        echo [INFO] Initializing ./data volume with server mods and configurations...
        mkdir "%DATA_DIR%\mods" 2>nul
        mkdir "%DATA_DIR%\config" 2>nul
        mkdir "%DATA_DIR%\defaultconfigs" 2>nul
        mkdir "%DATA_DIR%\kubejs" 2>nul
        xcopy /e /i /y "%~dp0mods" "%DATA_DIR%\mods" >nul 2>&1
        if exist "%~dp0config" xcopy /e /i /y "%~dp0config" "%DATA_DIR%\config" >nul 2>&1
        if exist "%~dp0defaultconfigs" xcopy /e /i /y "%~dp0defaultconfigs" "%DATA_DIR%\defaultconfigs" >nul 2>&1
        if exist "%~dp0kubejs" xcopy /e /i /y "%~dp0kubejs" "%DATA_DIR%\kubejs" >nul 2>&1
        if exist "%~dp0server.properties" copy /y "%~dp0server.properties" "%DATA_DIR%\server.properties" >nul 2>&1
        if exist "%~dp0eula.txt" copy /y "%~dp0eula.txt" "%DATA_DIR%\eula.txt" >nul 2>&1
        echo [OK] Data directory initialized.
    )
)
exit /b 0

REM ==============================================================================
REM COMMANDS
REM ==============================================================================

:CMD_UP
call :CHECK_PREREQS
echo.
if defined OPT_TUNNEL (
    echo [INFO] Launching Minecraft server with Playit tunnel enabled...
    docker compose --profile tunnel up -d
) else (
    echo [INFO] Launching Minecraft server in background...
    docker compose up -d
)
echo.
echo ==============================================================================
echo  [SUCCESS] Server is online!
echo  - Local connection:    localhost:25565
echo  - Interactive console: start.bat rcon
echo  - Graceful shutdown:   start.bat stop
echo  - Create safe backup:  start.bat backup
echo ==============================================================================
echo.
echo Attaching to live server logs [Press Ctrl+C to detach; server will keep running]:
echo ------------------------------------------------------------------------------
docker compose logs -f --tail=100 minecraft
goto EOF

:CMD_DOWN
echo [INFO] Gracefully stopping server and tunnel containers...
docker compose --profile tunnel down
echo [SUCCESS] Server stopped cleanly.
goto EOF

:CMD_RESTART
call :CMD_DOWN
call :CMD_UP
goto EOF

:CMD_LOGS
echo [INFO] Streaming logs for %CONTAINER_NAME% [Press Ctrl+C to exit]...
docker compose logs -f --tail=100 minecraft
goto EOF

:CMD_RCON
docker ps --format "{{.Names}}" | findstr /i /x "%CONTAINER_NAME%" >nul
if errorlevel 1 (
    echo [ERROR] Container %CONTAINER_NAME% is not running. Start it first with: start.bat
    goto EOF
)
shift
set "RCON_ARGS=%*"
if defined RCON_ARGS (
    docker exec -i %CONTAINER_NAME% rcon-cli %RCON_ARGS%
) else (
    echo [INFO] Connecting to interactive RCON CLI...
    echo [INFO] Type 'help' for Minecraft commands, Ctrl+C to exit.
    echo.
    docker exec -it %CONTAINER_NAME% rcon-cli
)
goto EOF

:CMD_BACKUP
if not exist "%DATA_DIR%\world" (
    echo [WARN] World folder '%DATA_DIR%\world' not found. Start the server first to generate the world.
    goto EOF
)
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "DT=%%I"
set "BACKUP_FILE=%BACKUP_DIR%\world_backup_%DT%.tar.gz"

set "IS_RUNNING=0"
docker ps --format "{{.Names}}" | findstr /i /x "%CONTAINER_NAME%" >nul && set "IS_RUNNING=1"

if "%IS_RUNNING%"=="1" (
    echo [INFO] Freezing world save operations via RCON...
    docker exec %CONTAINER_NAME% rcon-cli save-off
    echo [INFO] Flushing chunk writes to disk...
    docker exec %CONTAINER_NAME% rcon-cli save-all flush
    ping -n 3 127.0.0.1 >nul
) else (
    echo [INFO] Server container is stopped; archiving world directly...
)

echo [INFO] Creating compressed backup archive: %BACKUP_FILE% ...
where tar.exe >nul 2>&1
if not errorlevel 1 (
    tar.exe -czf "%BACKUP_FILE%" -C "%DATA_DIR%" world
) else (
    powershell -NoProfile -Command "Compress-Archive -Path '%DATA_DIR%\world' -DestinationPath '%BACKUP_DIR%\world_backup_%DT%.zip' -CompressionLevel Optimal"
    set "BACKUP_FILE=%BACKUP_DIR%\world_backup_%DT%.zip"
)

if "%IS_RUNNING%"=="1" (
    echo [INFO] Re-enabling world auto-save via RCON...
    docker exec %CONTAINER_NAME% rcon-cli save-on
)

echo [SUCCESS] World backup completed!
echo  - Destination: %BACKUP_FILE%
goto EOF

:CMD_SETUP
call :CHECK_PREREQS
echo.
echo [SUCCESS] Host environment setup and verification complete.
goto EOF

:PRINT_HELP
echo ==============================================================================
echo  Create Aeronautics Server Management [Windows]
echo ==============================================================================
echo Usage: start.bat [command] [options]
echo.
echo Commands:
echo   [no args]       Check environment, start server, and stream console logs
echo   -tunnel         Start server AND Playit tunnel for WAN / internet play
echo   stop / down     Gracefully stop the server container
echo   restart         Restart server container
echo   logs            Follow real-time server console output
echo   rcon [cmd]      Open interactive RCON shell or run single command
echo   backup          Safely freeze saving, flush chunks, archive world to ./backups/
echo   setup / doctor  Verify/install dependencies
echo   help            Display this help message
echo.
goto EOF

:EOF
popd
