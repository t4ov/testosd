#Set my working OSDCloud Template
Set-OSDCloudTemplate -Name 'Ovoko'

#Create my new OSDCloud Workspace
New-OSDCloudWorkspace -WorkspacePath D:\Ovoko\OSDCloud\Automate

#Cleanup Languages
$KeepTheseDirs = @('boot','efi','en-us','sources','fonts','resources')
Get-ChildItem "$(Get-OSDCloudWorkspace)\Media" | Where {$_.PSIsContainer} | Where {$_.Name -notin $KeepTheseDirs} | Remove-Item -Recurse -Force
Get-ChildItem "$(Get-OSDCloudWorkspace)\Media\Boot" | Where {$_.PSIsContainer} | Where {$_.Name -notin $KeepTheseDirs} | Remove-Item -Recurse -Force
Get-ChildItem "$(Get-OSDCloudWorkspace)\Media\EFI\Microsoft\Boot" | Where {$_.PSIsContainer} | Where {$_.Name -notin $KeepTheseDirs} | Remove-Item -Recurse -Force

#Edit Name
#Edit-OSDCloudWinPE -StartOSDCloudGUI -Brand 'Ovoko OSDCloud GUI'

#Edit startup.cmd
$Startnet = @'
start /wait PowerShell -NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/t4ov/testosd/refs/heads/main/osdtest.ps1 -Verbose
'@


Edit-OSDCloudWinPE -Startnet $Startnet

# Original commented code as backup
# $Startnet = @'
# start /wait PowerShell -NoL -C Install-Module OSD -Force -Verbose
# start /wait PowerShell -NoL -C Start-OSDCloud -OSVersion 'Windows 11' -OSBuild 22H2 -OSEdition Pro -OSLanguage en-us -ZTI
# '@
#Edit-OSDCloudWinPE -Startnet $Startnet

#Edit-OSDCloudWinPE -CloudDriver Wifi -WebPSScript https://github.com/t4ov/testosd/blob/main/osdtest.ps1  -Verbose

#Build WinPE to start OSDCloudGUI automatically
#Edit-OSDCloudWinPE -UseDefaultWallpaper -StartOSDCloudGUI

#Start Zero touch 
#Start-OSDCloud -ZTI