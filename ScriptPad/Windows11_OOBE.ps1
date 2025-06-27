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
    Firmware   = $false
}
Start-OSDCloud @Params


#=======================================================================
#   [PostOS] Apply Provisioning Package (JumpCloud)
#=======================================================================

# Target location inside system drive
$ProvisioningPath = "$env:SystemDrive\OSDCloud\Automate\Provisioning"
if (!(Test-Path $ProvisioningPath)) {
    New-Item -ItemType Directory -Path $ProvisioningPath -Force | Out-Null
}

# Detect external media containing the .ppkg
$ppkgSourcePath = Get-PSDrive -PSProvider FileSystem | ForEach-Object {
    $candidate = "$($_.Root)Ovoko\OSDCloud\Media\OSDCloud\Automate\Provisioning"
    if (Test-Path $candidate) { return $candidate }
} | Select-Object -First 1

if ($ppkgSourcePath) {
    Write-Host "Found provisioning package source at: $ppkgSourcePath" -ForegroundColor Green

    # Copy all .ppkg files
    Copy-Item -Path "$ppkgSourcePath\*.ppkg" -Destination $ProvisioningPath -Force

    # Apply each provisioning package
    Get-ChildItem -Path $ProvisioningPath -Filter *.ppkg | ForEach-Object {
        Write-Host "Applying Provisioning Package: $($_.FullName)" -ForegroundColor Cyan
        try {
            Install-ProvisioningPackage -PackagePath $_.FullName -ForceInstall -QuietInstall -Verbose
        } catch {
            Write-Warning "Failed to apply provisioning package: $_"
        }
    }
} else {
    Write-Warning "Provisioning package source folder not found on any attached drive."
}

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
$OOBEDeployJson | Out-File -FilePath "C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json" -Encoding ascii -Force

#================================================
#   [PostOS] AutopilotOOBE Configuration
#================================================
Write-Host -ForegroundColor Green "Define Computername:"
$Serial = Get-WmiObject Win32_bios | Select-Object -ExpandProperty SerialNumber
$TargetComputername = $Serial.Substring(4,3)
$AssignedComputerName = "Ovoko-$TargetComputername"
Write-Host -ForegroundColor Red $AssignedComputerName
Write-Host ""

Write-Host -ForegroundColor Green "Creating AutopilotOOBE JSON config"
$AutopilotOOBEJson = @"
{
    "AssignedComputerName" : "$AssignedComputerName",
    "Title":  "Autopilot Manual Register"
}
"@
$AutopilotOOBEJson | Out-File -FilePath "C:\ProgramData\OSDeploy\OSDeploy.AutopilotOOBE.json" -Encoding ascii -Force

#================================================
#   [PostOS] OOBE CMD Command Line
#================================================
Write-Host -ForegroundColor Green "Downloading and creating script for OOBE phase"
Invoke-RestMethod https://raw.githubusercontent.com/t4ov/testosd/refs/heads/main/Set-KeyboardLanguage.ps1 | Out-File -FilePath 'C:\Windows\Setup\scripts\keyboard.ps1' -Encoding ascii -Force
# Optional scripts (uncomment if needed):
 Invoke-RestMethod https://raw.githubusercontent.com/t4ov/testosd/refs/heads/main/Install-Packages.ps1 | Out-File -FilePath 'C:\Windows\Setup\scripts\packages.ps1' -Encoding ascii -Force
# Invoke-RestMethod https://check-autopilotprereq.osdcloud.ch | Out-File -FilePath 'C:\Windows\Setup\scripts\autopilotprereq.ps1' -Encoding ascii -Force
# Invoke-RestMethod https://start-autopilotoobe.osdcloud.ch | Out-File -FilePath 'C:\Windows\Setup\scripts\autopilotoobe.ps1' -Encoding ascii -Force

$OOBECMD = @'
@echo off
start /wait powershell.exe -NoL -ExecutionPolicy Bypass -F C:\Windows\Setup\Scripts\keyboard.ps1
start /wait powershell.exe -NoL -ExecutionPolicy Bypass -F C:\Windows\Setup\Scripts\packages.ps1
:: start /wait powershell.exe -NoL -ExecutionPolicy Bypass -F C:\Windows\Setup\Scripts\autopilotprereq.ps1
:: start /wait powershell.exe -NoL -ExecutionPolicy Bypass -F C:\Windows\Setup\Scripts\autopilotoobe.ps1
exit
'@
$OOBECMD | Out-File -FilePath 'C:\Windows\Setup\scripts\oobe.cmd' -Encoding ascii -Force

$UnattendXml = @'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <InputLocale>en-US</InputLocale>
      <SystemLocale>en-US</SystemLocale>
      <UILanguage>en-US</UILanguage>
      <UserLocale>en-US</UserLocale>
    </component>
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <OOBE>
        <HideEULAPage>true</HideEULAPage>
        <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
        <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
        <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
        <NetworkLocation>Work</NetworkLocation>
        <ProtectYourPC>1</ProtectYourPC>
      </OOBE>
      <RegisteredOrganization>Ovoko</RegisteredOrganization>
      <RegisteredOwner>Ovoko</RegisteredOwner>
      <TimeZone>UTC</TimeZone>
      <ComputerName>*</ComputerName>
    </component>
  </settings>
</unattend>
'@

$PantherPath = "C:\Windows\Panther"
If (!(Test-Path $PantherPath)) {
    New-Item -Path $PantherPath -ItemType Directory -Force | Out-Null
}
$UnattendXml | Out-File -FilePath "$PantherPath\Unattend.xml" -Encoding utf8 -Force

#================================================
#   Restart-Computer
#================================================
Write-Host -ForegroundColor Green "Restarting in 20 seconds!"
Start-Sleep -Seconds 20
wpeutil reboot
