@echo off
REM ===================================================
REM  ClaudeHeartbeat - one-click SSH into your VM
REM  Edit the 3 values below, then double-click this file.
REM ===================================================

set "KEY=%USERPROFILE%\.ssh\your_key"
set "VMUSER=claudeheartbeat"
set "VMIP=YOUR_EXTERNAL_IP"

echo Connecting to %VMUSER%@%VMIP% ...
ssh -i "%KEY%" %VMUSER%@%VMIP%

echo.
echo (SSH session closed)
pause
