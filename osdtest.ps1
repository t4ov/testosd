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
Start-OSDCloud -OSVersion 'Windows 11' -OSBuild 22H2 -OSEdition Pro -OSLanguage en-us -ZTI
#Restart from WinPE
Write-Host -ForegroundColor Green "Restarting in 20 seconds!"
Start-Sleep -Seconds 20
wpeutil reboot
