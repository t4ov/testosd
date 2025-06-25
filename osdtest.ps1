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


#Restart from WinPE
Write-Host -ForegroundColor Green "Restarting in 20 seconds!"
Start-Sleep -Seconds 20
wpeutil reboot


