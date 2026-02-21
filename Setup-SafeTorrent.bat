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

:: Check if Docker is installed in WSL2
wsl -- docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo  [X] Docker is not installed inside WSL2!
    echo.
    echo      Open your WSL2 terminal and run:
    echo      curl -fsSL https://get.docker.com ^| sh
    echo      sudo usermod -aG docker $USER
    echo.
    echo      Then run: wsl --shutdown
    echo      Reopen WSL2 and run this again.
    echo.
    goto :done
)

:: Start Docker daemon if not running
wsl -- docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo  [!] Starting Docker daemon...
    wsl -u root -- service docker start >nul 2>&1
    timeout /t 3 /nobreak >nul
)

:: Run setup.sh - use --cd to set working directory to this folder
echo  [OK] Launching setup in WSL2...
echo.
wsl --cd "%~dp0" -- bash ./setup.sh

:done
echo.
echo  Press any key to close...
pause >nul
