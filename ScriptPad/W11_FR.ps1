#================================================
#   [PreOS] Update Module
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
#   [OS] Params and Start-OSDCloud
#================================================
$Params = @{
    OSVersion  = "Windows 11"
    OSBuild    = "24H2"
    OSEdition  = "Pro"
    OSLanguage = "en-us"
    OSLicense  = "Retail"
    ZTI        = $true
    Firmware   = $false
}
Start-OSDCloud @Params

#==================================================================
# [PostOS] Staging Rename Script for SetupComplete
# This block replaces the previous JSON methods for renaming the PC
#==================================================================
Write-Host -ForegroundColor Green "Staging computer rename script for SetupComplete phase"

# This is the PowerShell script that will perform the rename
$RenameScriptContent = @'
#Requires -RunAsAdministrator
try {
    # Retrieve the serial number from BIOS
    $serialNumber = (Get-CimInstance -ClassName Win32_BIOS).SerialNumber.Trim()

    if (-not [string]::IsNullOrWhiteSpace($serialNumber)) {
        # Format new hostname and rename the computer
        $newHostname = "O-FR-$serialNumber"
        Rename-Computer -NewName $newHostname -Force -ErrorAction Stop
    }
} catch {
    # Log errors to a file for later review
    "$_" | Out-File -FilePath C:\Windows\Temp\Rename-Computer-Error.log -Encoding ascii
}
# A reboot is implicitly handled by the end of the Setup phase
'@

# Create the necessary directory on the new OS
# This path is a standard Windows location for setup scripts
$SetupScriptsPath = "C:\Windows\Setup\Scripts"
if (!(Test-Path $SetupScriptsPath)) {
    New-Item $SetupScriptsPath -ItemType Directory -Force | Out-Null
}

# Write the PowerShell rename script to the new OS
$RenameScriptContent | Out-File -FilePath "$SetupScriptsPath\RenamePC.ps1" -Encoding ascii -Force

# Create SetupComplete.cmd to execute our PowerShell script.
# Windows automatically finds and runs this file at the end of the setup process.
$SetupCompleteCmdContent = '@echo off
powershell.exe -ExecutionPolicy Bypass -File C:\Windows\Setup\Scripts\RenamePC.ps1
'
$SetupCompleteCmdContent | Out-File -FilePath "$SetupScriptsPath\SetupComplete.cmd" -Encoding ascii -Force

Write-Host "RenamePC.ps1 and SetupComplete.cmd have been created for pre-OOBE execution." -ForegroundColor Green


#================================================
#   [PostOS] OOBE CMD Command Line
#================================================
Write-Host -ForegroundColor Green "Downloading and creating script for OOBE phase"
# This script will now only handle tasks like setting the keyboard layout
Invoke-RestMethod https://raw.githubusercontent.com/t4ov/testosd/refs/heads/main/FR.ps1 | Out-File -FilePath 'C:\Windows\Setup\Scripts\fr.ps1' -Encoding ascii -Force

# Optional scripts (uncomment if needed):
# Invoke-RestMethod https://raw.githubusercontent.com/t4ov/testosd/refs/heads/main/Install-Packages.ps1 | Out-File -FilePath 'C:\Windows\Setup\scripts\packages.ps1' -Encoding ascii -Force
# Invoke-RestMethod https://check-autopilotprereq.osdcloud.ch | Out-File -FilePath 'C:\Windows\Setup\scripts\autopilotprereq.ps1' -Encoding ascii -Force
# Invoke-RestMethod https://start-autopilotoobe.osdcloud.ch | Out-File -FilePath 'C:\Windows\Setup\scripts\autopilotoobe.ps1' -Encoding ascii -Force

# Note: Removed the reference to the old RenameFR.ps1 script from this CMD file
$OOBECMD = @'
@echo off
start /wait powershell.exe -NoL -ExecutionPolicy Bypass -F C:\Windows\Setup\Scripts\fr.ps1
:: start /wait powershell.exe -NoL -ExecutionPolicy Bypass -F C:\Windows\Setup\Scripts\packages.ps1
:: start /wait powershell.exe -NoL -ExecutionPolicy Bypass -F C:\Windows\Setup\Scripts\autopilotprereq.ps1
:: start /wait powershell.exe -NoL -ExecutionPolicy Bypass -F C:\Windows\Setup\Scripts\autopilotoobe.ps1
exit
'@
$OOBECMD | Out-File -FilePath 'C:\Windows\Setup\scripts\oobe.cmd' -Encoding ascii -Force

#================================================
#   Restart-Computer
#================================================
Write-Host -ForegroundColor Green "Restarting in 10 seconds!"
Start-Sleep -Seconds 10
wpeutil reboot
