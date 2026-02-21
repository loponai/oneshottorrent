@echo off
title Tom Spark's Safe Torrent Box Setup
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
cd /d "%~dp0"
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
    echo      Then restart your computer and run this again.
    echo.
    pause
    exit /b 1
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
    echo      Then restart WSL2:
    echo      1. Open PowerShell and run: wsl --shutdown
    echo      2. Reopen your WSL2 terminal
    echo      3. Run this batch file again
    echo.
    pause
    exit /b 1
)

:: Check if Docker daemon is actually running in WSL2
wsl -- docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo  [!] Docker daemon is not running. Starting it...
    echo.
    wsl -u root -- service docker start
    timeout /t 3 /nobreak >nul
    wsl -- docker info >nul 2>&1
    if %errorlevel% neq 0 (
        echo  [X] Could not start Docker daemon!
        echo.
        echo      Open your WSL2 terminal and run:
        echo      sudo service docker start
        echo.
        echo      Then run this batch file again.
        echo.
        pause
        exit /b 1
    )
    echo  [OK] Docker daemon started!
    echo.
)

:: Convert Windows path to WSL path and run setup.sh
set "SCRIPT_DIR=%~dp0"
for /f "usebackq delims=" %%i in (`wsl wslpath -u "%SCRIPT_DIR%"`) do set "WSL_DIR=%%i"

echo  [OK] Launching setup in WSL2...
echo       Path: %WSL_DIR%
echo.

:: Use bash with the full script path (not bash -c) so stdin stays interactive
wsl -- bash "%WSL_DIR%setup.sh"

echo.
echo  =====================================================
echo  Setup script finished. If you saw errors above,
echo  check that Docker is running: wsl -- docker info
echo  =====================================================

:done
echo.
pause
