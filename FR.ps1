#$Title = "Set-KeyboardLanguage-and-TimeZone"
#$host.UI.RawUI.WindowTitle = $Title
#[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#[System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials

#$env:APPDATA = "C:\Windows\System32\Config\SystemProfile\AppData\Roaming"
#$env:LOCALAPPDATA = "C:\Windows\System32\Config\SystemProfile\AppData\Local"
#$Env:PSModulePath = $env:PSModulePath + ";C:\Program Files\WindowsPowerShell\Scripts"
#$env:Path = $env:Path + ";C:\Program Files\WindowsPowerShell\Scripts"

#$Global:Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Set-KeyboardLanguage-and-TimeZone.log"
#Start-Transcript -Path (Join-Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\" $Global:Transcript) -ErrorAction Ignore

#================================================
#  Set Time Zone
#================================================
#Write-Host -ForegroundColor Green "Setting Time Zone to France (Romance Standard Time)..."
#try {
#    Set-TimeZone -Id "Romance Standard Time" -ErrorAction Stop
#    Write-Host "Time zone set successfully." -ForegroundColor Green
#}
#catch {
#    Write-Warning "Failed to set the time zone. Error: $_"
#}
##================================================

#Write-Host -ForegroundColor Green "Set keyboard language to en-US"
#Start-Sleep -Seconds 5

#$LanguageList = Get-WinUserLanguageList

#$LanguageList.Add("en-US")
#Set-WinUserLanguageList $LanguageList -Force

#Start-Sleep -Seconds 5

#$LanguageList = Get-WinUserLanguageList
#$LanguageList.Remove(($LanguageList | Where-Object LanguageTag -like 'en-US'))
#Set-WinUserLanguageList $LanguageList -Force

#$LanguageList = Get-WinUserLanguageList
#$LanguageList.Remove(($LanguageList | Where-Object LanguageTag -like 'en-US'))
#Set-WinUserLanguageList $LanguageList -Force

#Start-Sleep -Seconds 10
#Stop-Transcript
