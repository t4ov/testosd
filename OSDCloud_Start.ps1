Write-Host -ForegroundColor Green "Starting OSDCloud ZTI"
Start-Sleep -Seconds 5

#Make sure I have the latest OSD Content
Write-Host -ForegroundColor Green "Updating OSD PowerShell Module"
Install-Module OSD -Force

Write-Host  -ForegroundColor Green "Importing OSD PowerShell Module"
Import-Module OSD -Force

#Start OSDCloudScriptPad
Write-Host -ForegroundColor Green "Start OSDPad"
Start-OSDPad -RepoOwner t4ov -RepoName testosd -RepoFolder ScriptPad -Hide Script -BrandingTitle 'Ovoko Windows Cloud Deployment'
