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

$scriptPath = "C:\Scripts\RenamePC.ps1"

# Save your rename script to $scriptPath (adjust path as needed)
@'
try {
    $serialNumber = (Get-CimInstance -ClassName Win32_BIOS).SerialNumber.Trim()
    if ([string]::IsNullOrWhiteSpace($serialNumber)) { throw "Serial number empty" }
    $newHostname = "O-FR-$serialNumber"
    Rename-Computer -NewName $newHostname -Force -ErrorAction Stop
    Restart-Computer -Force
} catch {
    # Log error or ignore
}
'@ | Out-File -FilePath $scriptPath -Encoding ASCII

# Create scheduled task XML or use Register-ScheduledTask cmdlet:
$action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument "-NoProfile -WindowStyle Hidden -File `"$scriptPath`""
$trigger = New-ScheduledTaskTrigger -AtLogOn -Once
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest

Register-ScheduledTask -TaskName "RenamePCOnFirstLogon" -Action $action -Trigger $trigger -Principal $principal

# Optionally, modify script to delete task after successful run





Start-Sleep -Seconds 10
Stop-Transcript
