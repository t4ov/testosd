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
#   [PostOS] OOBEDeploy Configuration
#================================================
Write-Host -ForegroundColor Green "Creating OOBEDeploy JSON config"
$OOBEDeployJson = @'
{
    "AddNetFX3":  { "IsPresent": true },
    "Autopilot":  { "IsPresent": false },
    "RemoveAppx":  [
        "MicrosoftTeams", "Microsoft.BingWeather", "Microsoft.BingNews", "Microsoft.GamingApp",
        "Microsoft.GetHelp", "Microsoft.Getstarted", "Microsoft.Messaging", "Microsoft.MicrosoftOfficeHub",
        "Microsoft.MicrosoftSolitaireCollection", "Microsoft.MicrosoftStickyNotes", "Microsoft.MSPaint",
        "Microsoft.People", "Microsoft.PowerAutomateDesktop", "Microsoft.StorePurchaseApp", "Microsoft.Todos",
        "microsoft.windowscommunicationsapps", "Microsoft.WindowsFeedbackHub", "Microsoft.WindowsMaps",
        "Microsoft.WindowsSoundRecorder", "Microsoft.Xbox.TCUI", "Microsoft.XboxGameOverlay",
        "Microsoft.XboxGamingOverlay", "Microsoft.XboxIdentityProvider", "Microsoft.XboxSpeechToTextOverlay",
        "Microsoft.YourPhone", "Microsoft.ZuneMusic", "Microsoft.ZuneVideo"
    ],
    "UpdateDrivers": { "IsPresent": true },
    "UpdateWindows": { "IsPresent": true }
}
'@

If (!(Test-Path "C:\ProgramData\OSDeploy")) {
    New-Item "C:\ProgramData\OSDeploy" -ItemType Directory -Force | Out-Null
}
$OOBEDeployJson | Out-File -FilePath "C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json" -Encoding utf8 -Force

#==================================================================
# [PostOS] Staging Rename Script for SetupComplete
# --- THIS SECTION HAS BEEN CORRECTED ---
#==================================================================
Write-Host -ForegroundColor Green "Staging computer rename script for SetupComplete phase"

# This is the PowerShell script that will perform the rename
$RenameScriptContent = @'
#Requires -RunAsAdministrator
try {
    # Retrieve the serial number from BIOS
    $serialNumber = (Get-CimInstance -ClassName Win32_BIOS).SerialNumber.Trim()

    # --- IMPROVEMENT: Hostname Validation ---
    # NetBIOS names are limited to 15 characters. To ensure compatibility,
    # we truncate the serial number. Prefix "O-LT-" is 5 chars, leaving 10.
    if ($serialNumber.Length -gt 10) {
        $serialNumber = $serialNumber.Substring(0, 10)
    }

    if (-not [string]::IsNullOrWhiteSpace($serialNumber)) {
        # Format new hostname
        $newHostname = "O-LT-$serialNumber"

        # --- FIX: Added -Restart parameter to force the required reboot ---
        Rename-Computer -NewName $newHostname -Force -Restart -ErrorAction Stop
    }
} catch {
    # --- IMPROVEMENT: More detailed error logging ---
    $errorMessage = @"
Error occurred at: $(Get-Date)
Failed to rename computer.
Exception:
$($_.Exception.Message)
"@
    # Log errors to a file for later review
    $errorMessage | Out-File -FilePath C:\Windows\Temp\Rename-Computer-Error.log -Encoding utf8 -Append
}
'@

# Create the necessary directory on the new OS
$SetupScriptsPath = "C:\Windows\Setup\Scripts"
if (!(Test-Path $SetupScriptsPath)) {
    New-Item $SetupScriptsPath -ItemType Directory -Force | Out-Null
}

# Write the PowerShell rename script to the new OS
$RenameScriptContent | Out-File -FilePath "$SetupScriptsPath\RenamePC.ps1" -Encoding utf8 -Force

# Create SetupComplete.cmd to execute our PowerShell script.
$SetupCompleteCmdContent = '@echo off
powershell.exe -ExecutionPolicy Bypass -File C:\Windows\Setup\Scripts\RenamePC.ps1
'
$SetupCompleteCmdContent | Out-File -FilePath "$SetupScriptsPath\SetupComplete.cmd" -Encoding ascii -Force

Write-Host "RenamePC.ps1 and SetupComplete.cmd have been created for pre-OOBE execution." -ForegroundColor Green

#================================================
#   [PostOS] OOBE CMD Command Line
#================================================
Write-Host -ForegroundColor Green "Downloading and creating script for OOBE phase"
Invoke-RestMethod https://raw.githubusercontent.com/t4ov/testosd/refs/heads/main/Set-GlobalSettings.ps1 | Out-File -FilePath 'C:\Windows\Setup\scripts\global.ps1' -Encoding ascii -Force
# Optional scripts (uncomment if needed):
# Invoke-RestMethod https://raw.githubusercontent.com/t4ov/testosd/refs/heads/main/Install-Packages.ps1 | Out-File -FilePath 'C:\Windows\Setup\scripts\packages.ps1' -Encoding ascii -Force

$OOBECMD = @'
@echo off
start /wait powershell.exe -NoL -ExecutionPolicy Bypass -F C:\Windows\Setup\Scripts\global.ps1
:: start /wait powershell.exe -NoL -ExecutionPolicy Bypass -F C:\Windows\Setup\Scripts\packages.ps1
exit
'@
$OOBECMD | Out-File -FilePath 'C:\Windows\Setup\scripts\oobe.cmd' -Encoding ascii -Force

#================================================
#   Restart-Computer
#================================================
Write-Host -ForegroundColor Green "Restarting in 10 seconds to begin Windows Setup!"
Start-Sleep -Seconds 10
wpeutil reboot
