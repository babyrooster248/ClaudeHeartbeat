@echo off
REM ===================================================
REM  ClaudeHeartbeat - show the next auto-ping time
REM  Edit the 3 values below, then double-click.
REM ===================================================

set "KEY=%USERPROFILE%\.ssh\your_key"
set "VMUSER=claudeheartbeat"
set "VMIP=YOUR_EXTERNAL_IP"

ssh -i "%KEY%" %VMUSER%@%VMIP% "sh ~/ClaudeHeartbeat/next-ping.sh"

echo.
pause
