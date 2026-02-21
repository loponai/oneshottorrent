@echo off
setlocal
title Tom Spark's Safe Torrent Box Setup
cd /d "%~dp0"

echo.
echo  =====================================================
echo       SAFE TORRENT BOX - VPN Protected Downloads
echo  =====================================================
echo       Created by TOM SPARK
echo       YouTube: youtube.com/@TomSparkReviews
echo  =====================================================
echo.
echo  How do you want to run Docker?
echo.
echo    1. Docker Desktop  (beginner-friendly, uses more RAM)
echo    2. WSL2 Native     (lightweight, no Docker Desktop needed)
echo.
set /p choice="  Select (1-2) [default: 1]: "

if "%choice%"=="2" goto :wsl2

:dockerdesktop
powershell -ExecutionPolicy Bypass -File "%~dp0setup.ps1"
goto :done

:wsl2
echo.

:: Check if WSL is available
wsl --status >nul 2>&1
if %errorlevel% neq 0 (
    echo  [X] WSL2 is not installed!
    echo.
    echo      To install WSL2, open PowerShell as Admin and run:
    echo      wsl --install
    echo.
    goto :done
)

:: Check if Docker is NATIVELY installed in WSL2 (not a Docker Desktop symlink)
wsl -- bash -c "docker --version && test ! -L $(which docker)" >nul 2>&1
if %errorlevel% neq 0 (
    echo  [!] Docker is not natively installed inside WSL2. Installing now...
    echo.
    :: Remove Docker Desktop symlinks if they exist
    echo  [!] Removing any Docker Desktop symlinks...
    wsl -u root -- bash -c "rm -f /usr/bin/docker /usr/local/bin/docker 2>/dev/null; rm -f /usr/bin/docker-compose /usr/local/bin/docker-compose 2>/dev/null"
    echo.
    :: Install Docker natively, DOCKER_INSTALL_SKIP_WSLCHECK bypasses the WSL nag
    wsl -u root -- bash -c "SKIP_IPTABLES_CHECK=1 curl -fsSL https://get.docker.com | DOCKER_INSTALL_SKIP_WSLCHECK=1 sh"
    if %errorlevel% neq 0 (
        echo  [X] Docker installation failed!
        echo.
        goto :done
    )
    echo.
    echo  [OK] Docker installed!
    echo  [!] Adding your user to the docker group...
    wsl -u root -- usermod -aG docker %USERNAME%
    echo.
    echo  [!] Restarting WSL2 to apply group changes...
    echo      This window will close. Please run this script again.
    echo.
    echo  Press any key to restart WSL2...
    pause >nul
    wsl --shutdown
    goto :done
)

:: Start Docker daemon if not running
wsl -- docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo  [!] Starting Docker daemon...
    wsl -u root -- service docker start >nul 2>&1
    timeout /t 5 /nobreak >nul
    wsl -- docker info >nul 2>&1
    if %errorlevel% neq 0 (
        echo  [X] Could not start Docker daemon!
        echo.
        echo      Try running: wsl --shutdown
        echo      Then run this script again.
        echo.
        goto :done
    )
)

:: Run setup.sh - use --cd to set working directory to this folder
echo  [OK] Launching setup in WSL2...
echo.
wsl --cd "%~dp0" -- bash ./setup.sh

:done
echo.
echo  Press any key to close...
pause >nul
