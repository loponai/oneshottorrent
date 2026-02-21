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
    echo  [!] Docker is installed but the daemon is not running.
    echo      Starting Docker daemon in WSL2...
    echo.
    wsl -- sudo service docker start
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

:: Convert Windows path to WSL path
set "SCRIPT_DIR=%~dp0"
for /f "delims=" %%i in ('wsl -- wslpath -u "%SCRIPT_DIR%"') do set "WSL_DIR=%%i"

:: Run setup.sh inside WSL2
wsl -- bash -c "cd '%WSL_DIR%' && chmod +x setup.sh && ./setup.sh"

:done
pause
