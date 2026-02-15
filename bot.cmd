@echo off
setlocal
call "%~dp0nlwuscript\openclaw-dev.bat" %*
exit /b %ERRORLEVEL%
