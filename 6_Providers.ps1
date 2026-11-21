#requires -Version 5.1
#requires -RunAsAdministrator
[CmdletBinding()]
param([ValidateSet('Vse','Software','NumLock')][string]$Uloha = 'Vse')

$ErrorActionPreference = 'Stop'

function Set-LogonNumLock {
    $path = 'Registry::HKEY_USERS\.DEFAULT\Control Panel\Keyboard'
    $name = 'InitialKeyboardIndicators'
    $raw = (Get-Item -LiteralPath $path).GetValue($name)
    [uint32]$bits = 0
    if ($null -ne $raw -and -not [uint32]::TryParse([string]$raw, [ref]$bits)) {
        throw "Neznámá hodnota $name '$raw'. Zkontrolujte ji v registru."
    }
    if (($bits -band 2) -ne 0) {
        Write-Host "NumLock je pro přihlašovací obrazovku již zapnutý ($bits)."
        return
    }
    $newValue = [string]($bits -bor 2)
    New-ItemProperty -LiteralPath $path -Name $name -PropertyType String -Value $newValue -Force | Out-Null
    if ((Get-Item -LiteralPath $path).GetValue($name) -ne $newValue) {
        throw 'Ověření zápisu NumLocku selhalo.'
    }
    Write-Host "NumLock pro přihlašovací obrazovku zapnut. Původní hodnota '$raw', nová '$newValue'."
}

function Get-RegistrySoftware {
    $roots = @('HKLM:')
    $roots += Get-ChildItem 'Registry::HKEY_USERS' | Where-Object {
        $_.PSChildName -match '^S-1-(5-21|12-1)-[\d-]+$'
    } | ForEach-Object { $_.PSPath }
    $branches = @('SOFTWARE')
    if ([Environment]::Is64BitOperatingSystem) { $branches += 'SOFTWARE\WOW6432Node' }
    foreach ($root in $roots) {
        foreach ($branch in $branches) {
            $path = "$root\$branch\Microsoft\Windows\CurrentVersion\Uninstall"
            if (-not (Test-Path -LiteralPath $path)) { continue }
            foreach ($key in Get-ChildItem -LiteralPath $path -ErrorAction Continue) {
                $p = Get-ItemProperty -LiteralPath $key.PSPath -ErrorAction Continue
                if (-not $p.DisplayName) { continue }
                $id = $key.PSChildName
                $guid = [guid]::Empty
                if ($p.WindowsInstaller -eq 1 -and [guid]::TryParse($id,[ref]$guid)) {
                    $identity = "MSI|$($guid.ToString('B'))"
                } else {
                    $identity = "ARP|$id|$($p.DisplayName)|$($p.Publisher)|$branch"
                }
                [pscustomobject]@{
                    Identita=$identity; Nazev=$p.DisplayName; Verze=$p.DisplayVersion
                    Vydavatel=$p.Publisher; Umisteni=$p.InstallLocation; Datum=$p.InstallDate
                    Rozsah=($root -replace '^.*HKEY_USERS\\','' -replace '^HKLM:$','Počítač')
                    Evidence=$key.Name; Architektura=$null; Zdroj='Registr Uninstall'
                }
            }
        }
    }
}

function Get-MsiSoftware {
    $installer = New-Object -ComObject WindowsInstaller.Installer
    # S-1-1-0 = všichni uživatelé, 7 = všechny instalační kontexty.
    foreach ($product in $installer.ProductsEx('', 'S-1-1-0', 7)) {
        try {
            if ($product.InstallProperty('State') -ne '5') { continue }
            $code = $product.ProductCode
            $scope = if ($product.Context -eq 4) { 'Počítač' } else { $product.UserSid }
            [pscustomobject]@{
                Identita="MSI|$code"; Nazev=$product.InstallProperty('InstalledProductName')
                Verze=$product.InstallProperty('VersionString'); Vydavatel=$product.InstallProperty('Publisher')
                Umisteni=$product.InstallProperty('InstallLocation'); Datum=$product.InstallProperty('InstallDate')
                Rozsah=$scope; Evidence=$code; Architektura=$null; Zdroj='Windows Installer'
            }
        } catch { Write-Warning "MSI $($product.ProductCode): $_" }
    }
}

function Get-AppxSoftware {
    foreach ($p in Get-AppxPackage -AllUsers -PackageTypeFilter Main,Framework,Bundle,Resource) {
        $users = @($p.PackageUserInformation | Where-Object { $_.InstallState -eq 'Installed' })
        if (-not $users.Count) { continue }
        [pscustomobject]@{
            Identita="AppX|$($p.PackageFullName)"; Nazev=$p.Name; Verze=[string]$p.Version
            Vydavatel=$p.Publisher; Umisteni=$p.InstallLocation; Datum=$null
            Rozsah=($users.UserSecurityId -join ', '); Evidence=$p.PackageFullName
            Architektura=$p.Architecture; Zdroj='AppX/MSIX'
        }
    }
}

if ($Uloha -ne 'Software') { Set-LogonNumLock }
if ($Uloha -eq 'NumLock') { return }
if ([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess) {
    throw 'Pro inventuru spusťte 64bitový Windows PowerShell.'
}

$rows = foreach ($reader in 'Get-RegistrySoftware','Get-MsiSoftware','Get-AppxSoftware') {
    try { & $reader } catch { Write-Warning "Neúplný výpis ze zdroje $reader. $_" }
}

# Stejný MSI ProductCode a verze se sloučí i při rozdílném názvu v registru.
# Při sloučení zachováme všechny různé neprázdné hodnoty každého sloupce.
$result = foreach ($group in ($rows | Group-Object Identita,Verze)) {
    $row = [ordered]@{}
    foreach ($field in 'Nazev','Verze','Vydavatel','Umisteni','Rozsah','Zdroj','Identita','Architektura','Datum','Evidence') {
        $values = foreach ($item in $group.Group) {
            $value = [string]$item.$field
            if (-not [string]::IsNullOrWhiteSpace($value)) { $value.Trim() }
        }
        $row[$field] = ($values | Sort-Object -Unique) -join ' | '
    }
    [pscustomobject]$row
}
$result | Sort-Object Nazev,Verze,Identita
