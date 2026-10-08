@echo off
rem Starts setup.ps1 and passes on any options, for example:
rem   setup.bat -Profile personal
rem   setup.bat -DryRun
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1" %*
exit /b %ERRORLEVEL%
