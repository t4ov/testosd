Write-Host -ForegroundColor Green "Starting OSDCloud ZTI"
Start-Sleep -Seconds 5
#Make sure I have the latest OSD Content
Write-Host -ForegroundColor Green "Updating OSD PowerShell Module"
Start-Sleep -Seconds 5
Install-Module OSD -Force
Write-Host -ForegroundColor Green "Importing OSD PowerShell Module"
Import-Module OSD -Force
#Start OSDCloud ZTI the RIGHT way
Write-Host -ForegroundColor Green "Start OSDCloud"
Start-OSDCloud -OSVersion 'Windows 11' -OSBuild 24H2 -OSEdition Pro -OSLanguage en-us -ZTI

#region OOBE Tasks
#================================================
Write-SectionHeader "[PostOS] OOBE CMD Command Line"
#================================================
Write-DarkGrayHost "Downloading Scripts for OOBE and specialize phase"

#Invoke-RestMethod http://autopilot.osdcloud.ch | Out-File -FilePath 'C:\Windows\Setup\scripts\autopilot.ps1' -Encoding ascii -Force
Invoke-RestMethod https://raw.githubusercontent.com/t4ov/testosd/refs/heads/main/OOBE.ps1 | Out-File -FilePath 'C:\Windows\Setup\scripts\oobe.ps1' -Encoding ascii -Force
#Invoke-RestMethod http://cleanup.osdcloud.ch | Out-File -FilePath 'C:\Windows\Setup\scripts\cleanup.ps1' -Encoding ascii -Force
#Invoke-RestMethod http://osdgather.osdcloud.ch | Out-File -FilePath 'C:\Windows\Setup\scripts\osdgather.ps1' -Encoding ascii -Force

$OOBEcmdTasks = @'
@echo off

REM Wait for Network 10 seconds
REM ping 127.0.0.1 -n 10 -w 1  >NUL 2>&1

REM Execute OOBE Tasks
start /wait powershell.exe -NoL -ExecutionPolicy Bypass -F C:\Windows\Setup\Scripts\oobe.ps1

#REM Execute OSD Gather Script
#REM start /wait powershell.exe -NoL -ExecutionPolicy Bypass -F C:\Windows\Setup\Scripts\osdgather.ps1

#REM Execute Cleanup Script
#start /wait powershell.exe -NoL -ExecutionPolicy Bypass -F C:\Windows\Setup\Scripts\cleanup.ps1

REM Below a PS session for debug and testing in system context, # when not needed 
REM start /wait powershell.exe -NoL -ExecutionPolicy Bypass

exit 
'@
$OOBEcmdTasks | Out-File -FilePath 'C:\Windows\Setup\scripts\oobe.cmd' -Encoding ascii -Force

#Restart from WinPE
Write-Host -ForegroundColor Green "Restarting in 20 seconds!"
Start-Sleep -Seconds 20
wpeutil reboot


