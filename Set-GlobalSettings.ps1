$Title = "Set-KeyboardLanguage"
$host.UI.RawUI.WindowTitle = $Title
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials

$env:APPDATA = "C:\Windows\System32\Config\SystemProfile\AppData\Roaming"
$env:LOCALAPPDATA = "C:\Windows\System32\Config\SystemProfile\AppData\Local"
$Env:PSModulePath = $env:PSModulePath + ";C:\Program Files\WindowsPowerShell\Scripts"
$env:Path = $env:Path + ";C:\Program Files\WindowsPowerShell\Scripts"

$Global:Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Set-KeyboardLanguage.log"
Start-Transcript -Path (Join-Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\" $Global:Transcript) -ErrorAction Ignore

Write-Host -ForegroundColor Green "Set keyboard language to en-US"
Start-Sleep -Seconds 5

$LanguageList = Get-WinUserLanguageList

$LanguageList.Add("en-US")
Set-WinUserLanguageList $LanguageList -Force

Start-Sleep -Seconds 5

#$LanguageList = Get-WinUserLanguageList
#$LanguageList.Remove(($LanguageList | Where-Object LanguageTag -like 'en-US'))
#Set-WinUserLanguageList $LanguageList -Force

#$LanguageList = Get-WinUserLanguageList
#$LanguageList.Remove(($LanguageList | Where-Object LanguageTag -like 'en-US'))
#Set-WinUserLanguageList $LanguageList -Force
<#
.SYNOPSIS
    Sets the computer's hostname to "O-<SerialNumber>".
.DESCRIPTION
    This script renames the local computer using the BIOS serial number, prefixed with "O-".
    Requires administrative privileges.
#>

#Requires -RunAsAdministrator

try {
    # Retrieve the serial number from BIOS
    $serialNumber = (Get-CimInstance -ClassName Win32_BIOS).SerialNumber.Trim()

    if ([string]::IsNullOrWhiteSpace($serialNumber)) {
        throw "Serial number could not be retrieved or is empty."
    }

    # Format new hostname
    $newHostname = "O-$serialNumber"

    # Rename the computer
    Rename-Computer -NewName $newHostname -Force -ErrorAction Stop 

    Write-Host "Hostname successfully changed to $newHostname" -ForegroundColor Green
    Write-Warning "A system restart is required for the name change to take effect." 

} catch {
    Write-Error "Failed to rename the computer: $_"
}
Start-Sleep -Seconds 10
Stop-Transcript
