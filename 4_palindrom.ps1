param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Text
)

# Rozloží znaky s diakritikou na písmena a diakritická znaménka.
$upraveny = $Text.ToLowerInvariant().Normalize(
    [System.Text.NormalizationForm]::FormD
)

# Odstraní diakritická znaménka a vše kromě písmen a číslic.
$upraveny = $upraveny -replace '\p{Mn}', ''
$upraveny = $upraveny -replace '[^\p{L}\p{Nd}]', ''

# Obrátí pořadí znaků.
$znaky = $upraveny.ToCharArray()
[Array]::Reverse($znaky)
$obraceny = -join $znaky

if ($upraveny.Length -eq 0) {
    Write-Output "Text neobsahuje žádná písmena ani číslice."
}
elseif ($upraveny -eq $obraceny) {
    Write-Output "Text je palindrom."
}
else {
    Write-Output "Text není palindrom."
}