@echo off
title Tom Spark's Safe Torrent Box Setup
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "%~dp0setup.ps1"
pause
