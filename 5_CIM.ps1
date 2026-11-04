Write-Output "`n1. Vlastnosti tiskaren"
(Get-CimClass Win32_Printer).CimClassProperties |
    Select-Object Name, CimType | Format-Table

$fax = Get-CimInstance Win32_Printer -Filter "Name='Fax'"
if ($fax) {
    $fax | Set-CimInstance -Property @{Location="Mistnost 101"}
}
Get-CimInstance Win32_Printer |
    Select-Object Name, Location | Format-Table

Write-Output "`n2. Nazev disku C:"
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$disk | Select-Object DeviceID, VolumeName | Format-Table
if ($disk.VolumeName -cne "System") {
    $disk | Set-CimInstance -Property @{VolumeName="System"}
}
Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" |
    Select-Object DeviceID, VolumeName | Format-Table

$ucty = Get-CimInstance Win32_UserAccount -Filter "LocalAccount=TRUE"

Write-Output "`n3. Ucty s nulovym poctem prihlaseni - CIM"
Get-CimInstance Win32_NetworkLoginProfile |
    Where-Object { $_.SID -in $ucty.SID -and $_.NumberOfLogons -eq 0 } |
    Select-Object Name, NumberOfLogons | Format-Table

Write-Output "`nUzamcene ucty - CIM"
$ucty | Where-Object Lockout |
    Select-Object Name, Lockout | Format-Table

Write-Output "`nUcty bez evidovaneho prihlaseni - Get-LocalUser"
Get-LocalUser |
    Where-Object { $null -eq $_.LastLogon } |
    Select-Object Name, LastLogon | Format-Table