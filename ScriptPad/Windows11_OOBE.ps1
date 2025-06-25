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
$ProvisioningPath = "$env:SystemDrive\OSDCloud\Automate\Provisioning"
if (!(Test-Path $ProvisioningPath)) {
    New-Item -ItemType Directory -Path $ProvisioningPath -Force | Out-Null
}

# Copy from external media (adjust drive letter if needed)
Copy-Item -Path "D:\Ovoko\OSDCloud\Media\OSDCloud\Automate\Provisioning\*.ppkg" -Destination $ProvisioningPath -Force

# Apply all PPKG packages found
Get-ChildItem -Path $ProvisioningPath -Filter *.ppkg | ForEach-Object {
    Write-Host "Applying Provisioning Package: $($_.FullName)" -ForegroundColor Cyan
    try {
        Install-ProvisioningPackage -PackagePath $_.FullName -ForceInstall -QuietInstall -Verbose
    } catch {
        Write-Warning "Failed to apply provisioning package: $_"
    }
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
$AssignedComputerName = "Oovko-$TargetComputername"
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
# Invoke-RestMethod https://raw.githubusercontent.com/AkosBakos/OSDCloud/main/Install-EmbeddedProductKey.ps1 | Out-File -FilePath 'C:\Windows\Setup\scripts\productkey.ps1' -Encoding ascii -Force
# Invoke-RestMethod https://check-autopilotprereq.osdcloud.ch | Out-File -FilePath 'C:\Windows\Setup\scripts\autopilotprereq.ps1' -Encoding ascii -Force
# Invoke-RestMethod https://start-autopilotoobe.osdcloud.ch | Out-File -FilePath 'C:\Windows\Setup\scripts\autopilotoobe.ps1' -Encoding ascii -Force

$OOBECMD = @'
@echo off
start /wait powershell.exe -NoL -ExecutionPolicy Bypass -F C:\Windows\Setup\Scripts\keyboard.ps1
:: start /wait powershell.exe -NoL -ExecutionPolicy Bypass -F C:\Windows\Setup\Scripts\productkey.ps1
:: start /wait powershell.exe -NoL -ExecutionPolicy Bypass -F C:\Windows\Setup\Scripts\autopilotprereq.ps1
:: start /wait powershell.exe -NoL -ExecutionPolicy Bypass -F C:\Windows\Setup\Scripts\autopilotoobe.ps1
exit
'@
$OOBECMD | Out-File -FilePath 'C:\Windows\Setup\scripts\oobe.cmd' -Encoding ascii -Force

#================================================
#   [PostOS] Generate and Place Unattend.xml
#================================================
Write-Host -ForegroundColor Green "Generating Unattend.xml"

$UnattendXml = @'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
	<!--https://schneegans.de/windows/unattend-generator/?LanguageMode=Unattended&UILanguage=en-US&Locale=en-US&Keyboard=00000409&GeoLocation=244&ProcessorArchitecture=amd64&ComputerNameMode=Random&CompactOsMode=Default&TimeZoneMode=Implicit&PartitionMode=Interactive&DiskAssertionMode=Skip&WindowsEditionMode=Generic&WindowsEdition=pro&InstallFromMode=Automatic&UserAccountMode=Unattended&AccountName0=Admin&AccountDisplayName0=Ovoko+Admin&AccountPassword0=WelcomeOvoko2025&AccountGroup0=Administrators&AccountName1=User&AccountDisplayName1=&AccountPassword1=&AccountGroup1=Users&AutoLogonMode=None&PasswordExpirationMode=Unlimited&LockoutMode=Default&HideFiles=Hidden&TaskbarSearch=Box&TaskbarIconsMode=Empty&StartTilesMode=Empty&StartPinsMode=Empty&HideEdgeFre=true&DisableEdgeStartupBoost=true&EffectsMode=Default&DesktopIconsMode=Default&WifiMode=Unattended&WifiName=Ovoko+Guest&WifiAuthentication=WPA2PSK&WifiPassword=rrr.ovoko&ExpressSettings=DisableAll&KeysMode=Skip&StickyKeysMode=Default&ColorMode=Default&WallpaperMode=Default&Remove3DViewer=true&RemoveBingSearch=true&RemoveClipchamp=true&RemoveCopilot=true&RemoveCortana=true&RemoveFamily=true&RemoveFeedbackHub=true&RemoveHandwriting=true&RemoveMixedReality=true&RemoveZuneVideo=true&RemoveNews=true&RemoveOffice365=true&RemoveOneNote=true&RemoveOneSync=true&RemoveOutlook=true&RemovePaint3D=true&RemovePeople=true&RemoveQuickAssist=true&RemoveRecall=true&RemoveSkype=true&RemoveSolitaire=true&RemoveSpeech=true&RemoveTeams=true&RemoveWallet=true&RemoveWeather=true&RemoveXboxApps=true&WdacMode=Skip-->
	<settings pass="offlineServicing"></settings>
	<settings pass="windowsPE">
		<component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
			<SetupUILanguage>
				<UILanguage>en-US</UILanguage>
			</SetupUILanguage>
			<InputLocale>0409:00000409</InputLocale>
			<SystemLocale>en-US</SystemLocale>
			<UILanguage>en-US</UILanguage>
			<UserLocale>en-US</UserLocale>
		</component>
		<component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
			<UserData>
				<ProductKey>
					<Key>VK7JG-NPHTM-C97JM-9MPGT-3V66T</Key>
					<WillShowUI>OnError</WillShowUI>
				</ProductKey>
				<AcceptEula>true</AcceptEula>
			</UserData>
			<UseConfigurationSet>false</UseConfigurationSet>
		</component>
	</settings>
	<settings pass="generalize"></settings>
	<settings pass="specialize">
		<component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
			<RunSynchronous>
				<RunSynchronousCommand wcm:action="add">
					<Order>1</Order>
					<Path>powershell.exe -WindowStyle Normal -NoProfile -Command "$xml = [xml]::new(); $xml.Load('C:\Windows\Panther\unattend.xml'); $sb = [scriptblock]::Create( $xml.unattend.Extensions.ExtractScript ); Invoke-Command -ScriptBlock $sb -ArgumentList $xml;"</Path>
				</RunSynchronousCommand>
				<RunSynchronousCommand wcm:action="add">
					<Order>2</Order>
					<Path>powershell.exe -WindowStyle Normal -NoProfile -Command "Get-Content -LiteralPath 'C:\Windows\Setup\Scripts\Specialize.ps1' -Raw | Invoke-Expression;"</Path>
				</RunSynchronousCommand>
				<RunSynchronousCommand wcm:action="add">
					<Order>3</Order>
					<Path>reg.exe load "HKU\DefaultUser" "C:\Users\Default\NTUSER.DAT"</Path>
				</RunSynchronousCommand>
				<RunSynchronousCommand wcm:action="add">
					<Order>4</Order>
					<Path>powershell.exe -WindowStyle Normal -NoProfile -Command "Get-Content -LiteralPath 'C:\Windows\Setup\Scripts\DefaultUser.ps1' -Raw | Invoke-Expression;"</Path>
				</RunSynchronousCommand>
				<RunSynchronousCommand wcm:action="add">
					<Order>5</Order>
					<Path>reg.exe unload "HKU\DefaultUser"</Path>
				</RunSynchronousCommand>
			</RunSynchronous>
		</component>
	</settings>
	<settings pass="auditSystem"></settings>
	<settings pass="auditUser"></settings>
	<settings pass="oobeSystem">
		<component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
			<InputLocale>0409:00000409</InputLocale>
			<SystemLocale>en-US</SystemLocale>
			<UILanguage>en-US</UILanguage>
			<UserLocale>en-US</UserLocale>
		</component>
		<component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
			<UserAccounts>
				<LocalAccounts>
					<LocalAccount wcm:action="add">
						<Name>Ovoko</Name>
						<DisplayName>Ovoko Admin</DisplayName>
						<Group>Administrators</Group>
						<Password>
							<Value>WelcomeOvoko2025</Value>
							<PlainText>true</PlainText>
						</Password>
					</LocalAccount>
					<LocalAccount wcm:action="add">
						<Name>User</Name>
						<DisplayName></DisplayName>
						<Group>Users</Group>
						<Password>
							<Value></Value>
							<PlainText>true</PlainText>
						</Password>
					</LocalAccount>
				</LocalAccounts>
			</UserAccounts>
			<OOBE>
				<ProtectYourPC>3</ProtectYourPC>
				<HideEULAPage>true</HideEULAPage>
				<HideOnlineAccountScreens>false</HideOnlineAccountScreens>
			</OOBE>
		</component>
	</settings>
	<Extensions xmlns="https://schneegans.de/windows/unattend-generator/">
		<ExtractScript>
param(
    [xml] $Document
);

foreach( $file in $Document.unattend.Extensions.File ) {
    $path = [System.Environment]::ExpandEnvironmentVariables( $file.GetAttribute( 'path' ) );
    mkdir -Path( $path | Split-Path -Parent ) -ErrorAction 'SilentlyContinue';
    $encoding = switch( [System.IO.Path]::GetExtension( $path ) ) {
        { $_ -in '.ps1', '.xml' } { [System.Text.Encoding]::UTF8; }
        { $_ -in '.reg', '.vbs', '.js' } { [System.Text.UnicodeEncoding]::new( $false, $true ); }
        default { [System.Text.Encoding]::Default; }
    };
    $bytes = $encoding.GetPreamble() + $encoding.GetBytes( $file.InnerText.Trim() );
    [System.IO.File]::WriteAllBytes( $path, $bytes );
}
		</ExtractScript>
		<File path="C:\Windows\Setup\Scripts\RemovePackages.ps1">
$selectors = @(
	'Microsoft.Microsoft3DViewer';
	'Microsoft.BingSearch';
	'Clipchamp.Clipchamp';
	'Microsoft.549981C3F5F10';
	'MicrosoftCorporationII.MicrosoftFamily';
	'Microsoft.WindowsFeedbackHub';
	'Microsoft.MixedReality.Portal';
	'Microsoft.BingNews';
	'Microsoft.MicrosoftOfficeHub';
	'Microsoft.Office.OneNote';
	'Microsoft.OutlookForWindows';
	'Microsoft.MSPaint';
	'Microsoft.People';
	'MicrosoftCorporationII.QuickAssist';
	'Microsoft.SkypeApp';
	'Microsoft.MicrosoftSolitaireCollection';
	'MicrosoftTeams';
	'MSTeams';
	'Microsoft.Wallet';
	'Microsoft.BingWeather';
	'Microsoft.Xbox.TCUI';
	'Microsoft.XboxApp';
	'Microsoft.XboxGameOverlay';
	'Microsoft.XboxGamingOverlay';
	'Microsoft.XboxIdentityProvider';
	'Microsoft.XboxSpeechToTextOverlay';
	'Microsoft.GamingApp';
	'Microsoft.ZuneVideo';
);
$getCommand = {
  Get-AppxProvisionedPackage -Online;
};
$filterCommand = {
  $_.DisplayName -eq $selector;
};
$removeCommand = {
  [CmdletBinding()]
  param(
    [Parameter( Mandatory, ValueFromPipeline )]
    $InputObject
  );
  process {
    $InputObject | Remove-AppxProvisionedPackage -AllUsers -Online -ErrorAction 'Continue';
  }
};
$type = 'Package';
$logfile = 'C:\Windows\Setup\Scripts\RemovePackages.log';
&amp; {
	$installed = &amp; $getCommand;
	foreach( $selector in $selectors ) {
		$result = [ordered] @{
			Selector = $selector;
		};
		$found = $installed | Where-Object -FilterScript $filterCommand;
		if( $found ) {
			$result.Output = $found | &amp; $removeCommand;
			if( $? ) {
				$result.Message = "$type removed.";
			} else {
				$result.Message = "$type not removed.";
				$result.Error = $Error[0];
			}
		} else {
			$result.Message = "$type not installed.";
		}
		$result | ConvertTo-Json -Depth 3 -Compress;
	}
} *&gt;&amp;1 &gt;&gt; $logfile;
		</File>
		<File path="C:\Windows\Setup\Scripts\RemoveCapabilities.ps1">
$selectors = @(
	'Language.Handwriting';
	'OneCoreUAP.OneSync';
	'App.Support.QuickAssist';
	'Language.Speech';
	'Language.TextToSpeech';
);
$getCommand = {
  Get-WindowsCapability -Online | Where-Object -Property 'State' -NotIn -Value @(
    'NotPresent';
    'Removed';
  );
};
$filterCommand = {
  ($_.Name -split '~')[0] -eq $selector;
};
$removeCommand = {
  [CmdletBinding()]
  param(
    [Parameter( Mandatory, ValueFromPipeline )]
    $InputObject
  );
  process {
    $InputObject | Remove-WindowsCapability -Online -ErrorAction 'Continue';
  }
};
$type = 'Capability';
$logfile = 'C:\Windows\Setup\Scripts\RemoveCapabilities.log';
&amp; {
	$installed = &amp; $getCommand;
	foreach( $selector in $selectors ) {
		$result = [ordered] @{
			Selector = $selector;
		};
		$found = $installed | Where-Object -FilterScript $filterCommand;
		if( $found ) {
			$result.Output = $found | &amp; $removeCommand;
			if( $? ) {
				$result.Message = "$type removed.";
			} else {
				$result.Message = "$type not removed.";
				$result.Error = $Error[0];
			}
		} else {
			$result.Message = "$type not installed.";
		}
		$result | ConvertTo-Json -Depth 3 -Compress;
	}
} *&gt;&amp;1 &gt;&gt; $logfile;
		</File>
		<File path="C:\Windows\Setup\Scripts\RemoveFeatures.ps1">
$selectors = @(
	'Recall';
);
$getCommand = {
  Get-WindowsOptionalFeature -Online | Where-Object -Property 'State' -NotIn -Value @(
    'Disabled';
    'DisabledWithPayloadRemoved';
  );
};
$filterCommand = {
  $_.FeatureName -eq $selector;
};
$removeCommand = {
  [CmdletBinding()]
  param(
    [Parameter( Mandatory, ValueFromPipeline )]
    $InputObject
  );
  process {
    $InputObject | Disable-WindowsOptionalFeature -Online -Remove -NoRestart -ErrorAction 'Continue';
  }
};
$type = 'Feature';
$logfile = 'C:\Windows\Setup\Scripts\RemoveFeatures.log';
&amp; {
	$installed = &amp; $getCommand;
	foreach( $selector in $selectors ) {
		$result = [ordered] @{
			Selector = $selector;
		};
		$found = $installed | Where-Object -FilterScript $filterCommand;
		if( $found ) {
			$result.Output = $found | &amp; $removeCommand;
			if( $? ) {
				$result.Message = "$type removed.";
			} else {
				$result.Message = "$type not removed.";
				$result.Error = $Error[0];
			}
		} else {
			$result.Message = "$type not installed.";
		}
		$result | ConvertTo-Json -Depth 3 -Compress;
	}
} *&gt;&amp;1 &gt;&gt; $logfile;
		</File>
		<File path="C:\Windows\Setup\Scripts\Wifi.xml">
&lt;WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1"&gt;
	&lt;name&gt;Ovoko Guest&lt;/name&gt;
	&lt;SSIDConfig&gt;
		&lt;SSID&gt;
			&lt;hex&gt;4F766F6B6F204775657374&lt;/hex&gt;
			&lt;name&gt;Ovoko Guest&lt;/name&gt;
		&lt;/SSID&gt;
	&lt;/SSIDConfig&gt;
	&lt;connectionType&gt;ESS&lt;/connectionType&gt;
	&lt;connectionMode&gt;auto&lt;/connectionMode&gt;
	&lt;MSM&gt;
		&lt;security&gt;
			&lt;authEncryption&gt;
				&lt;authentication&gt;WPA2PSK&lt;/authentication&gt;
				&lt;encryption&gt;AES&lt;/encryption&gt;
				&lt;useOneX&gt;false&lt;/useOneX&gt;
			&lt;/authEncryption&gt;
			&lt;sharedKey&gt;
				&lt;keyType&gt;passPhrase&lt;/keyType&gt;
				&lt;protected&gt;false&lt;/protected&gt;
				&lt;keyMaterial&gt;rrr.ovoko&lt;/keyMaterial&gt;
			&lt;/sharedKey&gt;
		&lt;/security&gt;
	&lt;/MSM&gt;
&lt;/WLANProfile&gt;
		</File>
		<File path="C:\Windows\Setup\Scripts\TaskbarLayoutModification.xml">
&lt;LayoutModificationTemplate xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification" xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout" xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout" xmlns:taskbar="http://schemas.microsoft.com/Start/2014/TaskbarLayout" Version="1"&gt;
	&lt;CustomTaskbarLayoutCollection PinListPlacement="Replace"&gt;
		&lt;defaultlayout:TaskbarLayout&gt;
			&lt;taskbar:TaskbarPinList&gt;
				&lt;taskbar:DesktopApp DesktopApplicationLinkPath="#leaveempty" /&gt;
			&lt;/taskbar:TaskbarPinList&gt;
		&lt;/defaultlayout:TaskbarLayout&gt;
	&lt;/CustomTaskbarLayoutCollection&gt;
&lt;/LayoutModificationTemplate&gt;
		</File>
		<File path="C:\Windows\Setup\Scripts\UnlockStartLayout.vbs">
HKU = &amp;H80000003
Set reg = GetObject("winmgmts://./root/default:StdRegProv")
Set fso = CreateObject("Scripting.FileSystemObject")

If reg.EnumKey(HKU, "", sids) = 0 Then
	If Not IsNull(sids) Then
		For Each sid In sids
			key = sid + "\Software\Policies\Microsoft\Windows\Explorer"
			name = "LockedStartLayout"
			If reg.GetDWORDValue(HKU, key, name, existing) = 0 Then
				reg.SetDWORDValue HKU, key, name, 0
			End If
		Next
	End If
End If
		</File>
		<File path="C:\Windows\Setup\Scripts\UnlockStartLayout.xml">
&lt;Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task"&gt;
	&lt;Triggers&gt;
		&lt;EventTrigger&gt;
			&lt;Enabled&gt;true&lt;/Enabled&gt;
			&lt;Subscription&gt;&amp;lt;QueryList&amp;gt;&amp;lt;Query Id="0" Path="Application"&amp;gt;&amp;lt;Select Path="Application"&amp;gt;*[System[Provider[@Name='UnattendGenerator'] and EventID=1]]&amp;lt;/Select&amp;gt;&amp;lt;/Query&amp;gt;&amp;lt;/QueryList&amp;gt;&lt;/Subscription&gt;
		&lt;/EventTrigger&gt;
	&lt;/Triggers&gt;
	&lt;Principals&gt;
		&lt;Principal id="Author"&gt;
			&lt;UserId&gt;S-1-5-18&lt;/UserId&gt;
			&lt;RunLevel&gt;LeastPrivilege&lt;/RunLevel&gt;
		&lt;/Principal&gt;
	&lt;/Principals&gt;
	&lt;Settings&gt;
		&lt;MultipleInstancesPolicy&gt;IgnoreNew&lt;/MultipleInstancesPolicy&gt;
		&lt;DisallowStartIfOnBatteries&gt;false&lt;/DisallowStartIfOnBatteries&gt;
		&lt;StopIfGoingOnBatteries&gt;false&lt;/StopIfGoingOnBatteries&gt;
		&lt;AllowHardTerminate&gt;true&lt;/AllowHardTerminate&gt;
		&lt;StartWhenAvailable&gt;false&lt;/StartWhenAvailable&gt;
		&lt;RunOnlyIfNetworkAvailable&gt;false&lt;/RunOnlyIfNetworkAvailable&gt;
		&lt;IdleSettings&gt;
			&lt;StopOnIdleEnd&gt;true&lt;/StopOnIdleEnd&gt;
			&lt;RestartOnIdle&gt;false&lt;/RestartOnIdle&gt;
		&lt;/IdleSettings&gt;
		&lt;AllowStartOnDemand&gt;true&lt;/AllowStartOnDemand&gt;
		&lt;Enabled&gt;true&lt;/Enabled&gt;
		&lt;Hidden&gt;false&lt;/Hidden&gt;
		&lt;RunOnlyIfIdle&gt;false&lt;/RunOnlyIfIdle&gt;
		&lt;WakeToRun&gt;false&lt;/WakeToRun&gt;
		&lt;ExecutionTimeLimit&gt;PT72H&lt;/ExecutionTimeLimit&gt;
		&lt;Priority&gt;7&lt;/Priority&gt;
	&lt;/Settings&gt;
	&lt;Actions Context="Author"&gt;
		&lt;Exec&gt;
			&lt;Command&gt;C:\Windows\System32\wscript.exe&lt;/Command&gt;
			&lt;Arguments&gt;C:\Windows\Setup\Scripts\UnlockStartLayout.vbs&lt;/Arguments&gt;
		&lt;/Exec&gt;
	&lt;/Actions&gt;
&lt;/Task&gt;
		</File>
		<File path="C:\Windows\Setup\Scripts\SetStartPins.ps1">
$json = '{"pinnedList":[]}';
if( [System.Environment]::OSVersion.Version.Build -lt 20000 ) {
	return;
}
$key = 'Registry::HKLM\SOFTWARE\Microsoft\PolicyManager\current\device\Start';
New-Item -Path $key -ItemType 'Directory' -ErrorAction 'SilentlyContinue';
Set-ItemProperty -LiteralPath $key -Name 'ConfigureStartPins' -Value $json -Type 'String';
		</File>
		<File path="C:\Users\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml">
&lt;LayoutModificationTemplate Version="1" xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification"&gt;
	&lt;LayoutOptions StartTileGroupCellWidth="6" /&gt;
	&lt;DefaultLayoutOverride&gt;
		&lt;StartLayoutCollection&gt;
			&lt;StartLayout GroupCellWidth="6" xmlns="http://schemas.microsoft.com/Start/2014/FullDefaultLayout" /&gt;
		&lt;/StartLayoutCollection&gt;
	&lt;/DefaultLayoutOverride&gt;
&lt;/LayoutModificationTemplate&gt;
		</File>
		<File path="C:\Windows\Setup\Scripts\Specialize.ps1">
$scripts = @(
	{
		Remove-Item -LiteralPath 'Registry::HKLM\Software\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate' -Force -ErrorAction 'SilentlyContinue';
	};
	{
		reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Communications" /v ConfigureChatAutoInstall /t REG_DWORD /d 0 /f;
	};
	{
		Get-Content -LiteralPath 'C:\Windows\Setup\Scripts\RemovePackages.ps1' -Raw | Invoke-Expression;
	};
	{
		Get-Content -LiteralPath 'C:\Windows\Setup\Scripts\RemoveCapabilities.ps1' -Raw | Invoke-Expression;
	};
	{
		Get-Content -LiteralPath 'C:\Windows\Setup\Scripts\RemoveFeatures.ps1' -Raw | Invoke-Expression;
	};
	{
		netsh.exe wlan add profile filename="C:\Windows\Setup\Scripts\Wifi.xml" user=all;
	};
	{
		netsh.exe wlan connect name="Ovoko Guest" ssid="Ovoko Guest";
	};
	{
		net.exe accounts /maxpwage:UNLIMITED;
	};
	{
		reg.exe add "HKLM\Software\Policies\Microsoft\Windows\CloudContent" /v "DisableCloudOptimizedContent" /t REG_DWORD /d 1 /f;
		[System.Diagnostics.EventLog]::CreateEventSource( 'UnattendGenerator', 'Application' );
	};
	{
		Register-ScheduledTask -TaskName 'UnlockStartLayout' -Xml $( Get-Content -LiteralPath 'C:\Windows\Setup\Scripts\UnlockStartLayout.xml' -Raw );
	};
	{
		reg.exe add "HKLM\Software\Policies\Microsoft\Edge" /v HideFirstRunExperience /t REG_DWORD /d 1 /f;
	};
	{
		reg.exe add "HKLM\Software\Policies\Microsoft\Edge\Recommended" /v BackgroundModeEnabled /t REG_DWORD /d 0 /f;
		reg.exe add "HKLM\Software\Policies\Microsoft\Edge\Recommended" /v StartupBoostEnabled /t REG_DWORD /d 0 /f;
	};
	{
		Get-Content -LiteralPath 'C:\Windows\Setup\Scripts\SetStartPins.ps1' -Raw | Invoke-Expression;
	};
);

&amp; {
  [float] $complete = 0;
  [float] $increment = 100 / $scripts.Count;
  foreach( $script in $scripts ) {
    Write-Progress -Activity 'Running scripts to customize your Windows installation. Do not close this window.' -PercentComplete $complete;
    '*** Will now execute command &#xAB;{0}&#xBB;.' -f $(
      $str = $script.ToString().Trim() -replace '\s+', ' ';
      $max = 100;
      if( $str.Length -le $max ) {
        $str;
      } else {
        $str.Substring( 0, $max - 1 ) + '&#x2026;';
      }
    );
    $start = [datetime]::Now;
    &amp; $script;
    '*** Finished executing command after {0:0} ms.' -f [datetime]::Now.Subtract( $start ).TotalMilliseconds;
    "`r`n" * 3;
    $complete += $increment;
  }
} *&gt;&amp;1 &gt;&gt; "C:\Windows\Setup\Scripts\Specialize.log";
		</File>
		<File path="C:\Windows\Setup\Scripts\UserOnce.ps1">
$scripts = @(
	{
		Get-AppxPackage -Name 'Microsoft.Windows.Ai.Copilot.Provider' | Remove-AppxPackage;
	};
	{
		[System.Diagnostics.EventLog]::WriteEntry( 'UnattendGenerator', "User '$env:USERNAME' has requested to unlock the Start menu layout.", [System.Diagnostics.EventLogEntryType]::Information, 1 );
	};
);

&amp; {
  [float] $complete = 0;
  [float] $increment = 100 / $scripts.Count;
  foreach( $script in $scripts ) {
    Write-Progress -Activity 'Running scripts to configure this user account. Do not close this window.' -PercentComplete $complete;
    '*** Will now execute command &#xAB;{0}&#xBB;.' -f $(
      $str = $script.ToString().Trim() -replace '\s+', ' ';
      $max = 100;
      if( $str.Length -le $max ) {
        $str;
      } else {
        $str.Substring( 0, $max - 1 ) + '&#x2026;';
      }
    );
    $start = [datetime]::Now;
    &amp; $script;
    '*** Finished executing command after {0:0} ms.' -f [datetime]::Now.Subtract( $start ).TotalMilliseconds;
    "`r`n" * 3;
    $complete += $increment;
  }
} *&gt;&amp;1 &gt;&gt; "$env:TEMP\UserOnce.log";
		</File>
		<File path="C:\Windows\Setup\Scripts\DefaultUser.ps1">
$scripts = @(
	{
		reg.exe add "HKU\DefaultUser\Software\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f;
	};
	{
		reg.exe add "HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v AppCaptureEnabled /t REG_DWORD /d 0 /f;
	};
	{
		reg.exe add "HKU\DefaultUser\Software\Policies\Microsoft\Windows\Explorer" /v "StartLayoutFile" /t REG_SZ /d "C:\Windows\Setup\Scripts\TaskbarLayoutModification.xml" /f;
		reg.exe add "HKU\DefaultUser\Software\Policies\Microsoft\Windows\Explorer" /v "LockedStartLayout" /t REG_DWORD /d 1 /f;
	};
	{
		reg.exe add "HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v "UnattendedSetup" /t REG_SZ /d "powershell.exe -WindowStyle Normal -NoProfile -Command \""Get-Content -LiteralPath 'C:\Windows\Setup\Scripts\UserOnce.ps1' -Raw | Invoke-Expression;\""" /f;
	};
);

&amp; {
  [float] $complete = 0;
  [float] $increment = 100 / $scripts.Count;
  foreach( $script in $scripts ) {
    Write-Progress -Activity 'Running scripts to modify the default user&#x2019;&#x2019;s registry hive. Do not close this window.' -PercentComplete $complete;
    '*** Will now execute command &#xAB;{0}&#xBB;.' -f $(
      $str = $script.ToString().Trim() -replace '\s+', ' ';
      $max = 100;
      if( $str.Length -le $max ) {
        $str;
      } else {
        $str.Substring( 0, $max - 1 ) + '&#x2026;';
      }
    );
    $start = [datetime]::Now;
    &amp; $script;
    '*** Finished executing command after {0:0} ms.' -f [datetime]::Now.Subtract( $start ).TotalMilliseconds;
    "`r`n" * 3;
    $complete += $increment;
  }
} *&gt;&amp;1 &gt;&gt; "C:\Windows\Setup\Scripts\DefaultUser.log";
		</File>
	</Extensions>
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
