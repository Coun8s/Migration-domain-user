@echo off
mkdir "C:\Migration\Scripts"
SET dst="C:\Migration\Scripts"
SET src="%~dp0"
xcopy /e /s %src%\Scripts %dst%\
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /f /v EnableLUA /t REG_DWORD /d 0
PowerShell.exe -ExecutionPolicy Bypass -File "C:\Migration\Scripts\migration-part1.ps1"