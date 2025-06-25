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
#   [OS] Create Unattend.xml BEFORE Install
#================================================
Write-Host -ForegroundColor Green "Creating Unattend.xml for unattended OOBE"

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
      <UserAccounts>
        <AdministratorPassword>
          <Value>Pa55w.rd</Value>
          <PlainText>true</PlainText>
        </AdministratorPassword>
      </UserAccounts>
      <AutoLogon>
        <Username>Administrator</Username>
        <Enabled>true</Enabled>
        <LogonCount>1</LogonCount>
      </AutoLogon>
      <RegisteredOrganization>Ovoko</RegisteredOrganization>
      <RegisteredOwner>Ovoko</RegisteredOwner>
      <TimeZone>UTC</TimeZone>
      <ComputerName>*</ComputerName>
    </component>
  </settings>
</unattend>
'@

$UnattendPath = "C:\OSDCloud\Unattend.xml"
If (!(Test-Path "C:\OSDCloud")) {
    New-Item -Path "C:\OSDCloud" -ItemType Directory -Force | Out-Null
}
$UnattendXml | Out-File -FilePath $UnattendPath -Encoding utf8 -Force

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
    Unattend   = $UnattendPath
}
Start-OSDCloud @Params

#================================================
#  [PostOS] OOBEDeploy Configuration
#================================================
Write-Host -ForegroundColor Green "Create C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json"

$OOBEDeployJson = @'
{
    "AddNetFX3":  { "IsPresent":  true },
    "Autopilot":  { "IsPresent":  false },
    "RemoveAppx":  [
        "MicrosoftTeams",
        "Microsoft.BingWeather",
        "Microsoft.BingNews",
        "Microsoft.GamingApp",
        "Microsoft.GetHelp",
        "Microsoft.Getstarted",
        "Microsoft.Messaging",
        "Microsoft.MicrosoftOfficeHub",
        "Microsoft.MicrosoftSolitaireCollection",
        "Microsoft.MicrosoftStickyNotes",
        "Microsoft.MSPaint",
        "Microsoft.People",
        "Microsoft.PowerAutomateDesktop",
        "Microsoft.StorePurchaseApp",
        "Microsoft.Todos",
        "microsoft.windowscommunicationsapps",
        "Microsoft.WindowsFeedbackHub",
        "Microsoft.WindowsMaps",
        "Microsoft.WindowsSoundRecorder",
        "Microsoft.Xbox.TCUI",
        "Microsoft.XboxGameOverlay",
        "Microsoft.XboxGamingOverlay",
        "Microsoft.XboxIdentityProvider",
        "Microsoft.XboxSpeechToTextOverlay",
        "Microsoft.YourPhone",
        "Microsoft.ZuneMusic",
        "Microsoft.ZuneVideo"
    ],
    "UpdateDrivers": { "IsPresent":  true },
    "UpdateWindows": { "IsPresent":  true }
}
'@

$OSDeployPath = "C:\ProgramData\OSDeploy"
If (!(Test-Path $OSDeployPath)) {
    New-Item $OSDeployPath -ItemType Directory -Force | Out-Null
}
$OOBEDeployJson | Out-File -FilePath "$OSDeployPath\OSDeploy.OOBEDeploy.json" -Encoding ascii -Force

#================================================
#  [PostOS] AutopilotOOBE Configuration
#================================================
Write-Host -ForegroundColor Green "Define Computername"
$Serial = Get-WmiObject Win32_bios | Select-Object -ExpandProperty SerialNumber
$TargetComputername = $Serial.Substring(4,3)
$AssignedComputerName = "Ovoko-$TargetComputername"
Write-Host -ForegroundColor Red $AssignedComputerName

Write-Host -ForegroundColor Green "Create OSDeploy.AutopilotOOBE.json"

$AutopilotOOBEJson = @"
{
    "AssignedComputerName" : "$AssignedComputerName",
    "Title":  "Autopilot Manual Register"
}
"@
$AutopilotOOBEJson | Out-File -FilePath "$OSDeployPath\OSDeploy.AutopilotOOBE.json" -Encoding ascii -Force

#================================================
#  [PostOS] OOBE CMD Command Line
#================================================
Write-Host -ForegroundColor Green "Downloading and creating OOBE phase script"

$ScriptPath = 'C:\Windows\Setup\Scripts'
If (!(Test-Path $ScriptPath)) {
    New-Item -Path $ScriptPath -ItemType Directory -Force | Out-Null
}

Invoke-RestMethod https://raw.githubusercontent.com/t4ov/testosd/refs/heads/main/Set-KeyboardLanguage.ps1 | Out-File -FilePath "$ScriptPath\keyboard.ps1" -Encoding ascii -Force

$OOBECMD = @'
@echo off
REM Execute OOBE Tasks
start /wait powershell.exe -NoL -ExecutionPolicy Bypass -F C:\Windows\Setup\Scripts\keyboard.ps1
REM Add more lines as needed
exit
'@
$OOBECMD | Out-File -FilePath "$ScriptPath\oobe.cmd" -Encoding ascii -Force

#================================================
#   Final Reboot
#================================================
Write-Host -ForegroundColor Green "Restarting in 20 seconds!"
Start-Sleep -Seconds 20
wpeutil reboot
