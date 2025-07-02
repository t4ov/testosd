$scriptPath = "C:\Windows\Scripts\RenamePC.ps1"

@'
try {
    $serialNumber = (Get-CimInstance -ClassName Win32_BIOS).SerialNumber.Trim()
    if ([string]::IsNullOrWhiteSpace($serialNumber)) { throw "Serial number empty" }
    $newHostname = "O-FR-$serialNumber"
    Rename-Computer -NewName $newHostname -Force -ErrorAction Stop
    Restart-Computer -Force
} catch {
    # Log error if needed
}
'@ | Out-File -FilePath $scriptPath -Encoding ASCII
