@echo off
setlocal
title Tom Spark's Safe Torrent Box Manager
cd /d "%~dp0"

:menu
cls
echo.
echo  =====================================================
echo       SAFE TORRENT BOX - Manager
echo  =====================================================
echo       Created by TOM SPARK
echo       YouTube: youtube.com/@TomSparkReviews
echo  =====================================================
echo.
echo    1. Start          - Start the VPN + qBittorrent
echo    2. Stop           - Stop everything
echo    3. Status         - Check if containers are running
echo    4. VPN Check      - Show your VPN IP address
echo    5. Get Password   - Show qBittorrent login password
echo    6. View Logs      - Show VPN connection logs
echo    7. Open qBittorrent - Open Web UI in browser
echo    8. Restart        - Stop and start again
echo    9. Uninstall      - Remove containers and images
echo    0. Exit
echo.
set /p choice="  Select (0-9): "

if "%choice%"=="1" goto :start
if "%choice%"=="2" goto :stop
if "%choice%"=="3" goto :status
if "%choice%"=="4" goto :vpncheck
if "%choice%"=="5" goto :password
if "%choice%"=="6" goto :logs
if "%choice%"=="7" goto :open
if "%choice%"=="8" goto :restart
if "%choice%"=="9" goto :uninstall
if "%choice%"=="0" exit /b 0
goto :menu

:start
echo.
echo  [*] Starting Safe Torrent Box...
call :rundocker compose up -d
echo.
echo  [OK] Started! Open http://localhost:8080 in your browser.
goto :pause_menu

:stop
echo.
echo  [*] Stopping Safe Torrent Box...
call :rundocker compose down
echo.
echo  [OK] Stopped.
goto :pause_menu

:status
echo.
echo  Container Status:
echo  -----------------
call :rundocker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" --filter "name=gluetun" --filter "name=qbittorrent"
goto :pause_menu

:vpncheck
echo.
echo  Checking VPN IP...
echo.
call :rundocker exec gluetun sh -c "wget -qO- https://ipinfo.io 2>/dev/null || echo 'Could not reach internet - VPN may be disconnected'"
goto :pause_menu

:password
echo.
echo  qBittorrent Login:
echo  ------------------
echo  Username: admin
echo  Password:
call :rundocker logs qbittorrent 2>&1 | findstr /i "password"
echo.
echo  Change your password after login: Tools ^> Options ^> Web UI
goto :pause_menu

:logs
echo.
echo  VPN Logs (last 30 lines):
echo  -------------------------
call :rundocker logs --tail 30 gluetun
goto :pause_menu

:open
echo.
echo  [*] Opening qBittorrent Web UI...
start http://localhost:8080
goto :menu

:restart
echo.
echo  [*] Restarting Safe Torrent Box...
call :rundocker compose down
timeout /t 2 /nobreak >nul
call :rundocker compose up -d
echo.
echo  [OK] Restarted!
goto :pause_menu

:uninstall
echo.
echo  WARNING: This will remove all containers, images, and config!
echo  Your downloaded files in the 'downloads' folder will NOT be deleted.
echo.
set /p confirm="  Are you sure? (Y/N): "
if /i not "%confirm%"=="Y" goto :menu
echo.
echo  [*] Removing containers...
call :rundocker compose down -v --rmi all
echo.
echo  [OK] Uninstalled. You can delete this folder to fully remove.
goto :pause_menu

:pause_menu
echo.
echo  Press any key to return to menu...
pause >nul
goto :menu

:: --- Docker command router ---
:: Tries docker directly (Docker Desktop), falls back to WSL
:rundocker
docker info >nul 2>&1
if %errorlevel%==0 (
    docker %*
) else (
    wsl -- docker %*
)
exit /b
