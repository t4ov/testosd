#================================================
#   [PreOS] Update Module
#================================================
if ((Get-MyComputerModel) -match 'Virtual') {
    Write-Host -ForegroundColor Green "Setting Display Resolution to 1600x"
    Set-DisRes 1600
}

Write-Host -ForegroundColor Green "Updating OSD PowerShell Module"
Install-Module OSD -Force

Write-Host -ForegroundColor Green "Importing OSD PowerShell Module"
Import-Module OSD -Force

#================================================
#   [OS] Params and Start-OSDCloud
#================================================
$Params = @{
    OSVersion  = "Windows 11"
    OSBuild    = "24H2"
    OSEdition  = "Pro"
    OSLanguage = "en-us"
    OSLicense  = "Retail"
    ZTI        = $true
    Firmware   = $true
}
Start-OSDCloud @Params
#================================================
#   [PostOS] OOBE CMD Command Line
#================================================
Write-Host -ForegroundColor Green "Downloading and creating script for OOBE phase"
Invoke-RestMethod https://raw.githubusercontent.com/t4ov/testosd/refs/heads/main/Set-KeyboardLanguage.ps1 | Out-File -FilePath 'C:\Windows\Setup\scripts\keyboard.ps1' -Encoding ascii -Force
# Optional scripts (uncomment if needed):
# Invoke-RestMethod https://raw.githubusercontent.com/t4ov/testosd/refs/heads/main/Install-Packages.ps1 | Out-File -FilePath 'C:\Windows\Setup\scripts\packages.ps1' -Encoding ascii -Force
# Invoke-RestMethod https://check-autopilotprereq.osdcloud.ch | Out-File -FilePath 'C:\Windows\Setup\scripts\autopilotprereq.ps1' -Encoding ascii -Force
# Invoke-RestMethod https://start-autopilotoobe.osdcloud.ch | Out-File -FilePath 'C:\Windows\Setup\scripts\autopilotoobe.ps1' -Encoding ascii -Force

$OOBECMD = @'
@echo off
start /wait powershell.exe -NoL -ExecutionPolicy Bypass -F C:\Windows\Setup\Scripts\keyboard.ps1
::start /wait powershell.exe -NoL -ExecutionPolicy Bypass -F C:\Windows\Setup\Scripts\packages.ps1
:: start /wait powershell.exe -NoL -ExecutionPolicy Bypass -F C:\Windows\Setup\Scripts\autopilotprereq.ps1
:: start /wait powershell.exe -NoL -ExecutionPolicy Bypass -F C:\Windows\Setup\Scripts\autopilotoobe.ps1
exit
'@
$OOBECMD | Out-File -FilePath 'C:\Windows\Setup\scripts\oobe.cmd' -Encoding ascii -Force


#================================================
#   Restart-Computer
#================================================
Write-Host -ForegroundColor Green "Restarting in 20 seconds!"
Start-Sleep -Seconds 20
wpeutil reboot
