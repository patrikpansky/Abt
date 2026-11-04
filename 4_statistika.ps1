param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Text
)

$pocetZnaku = $Text.Length
$pocetBezMezer = ($Text -replace ' ', '').Length
$pocetSamohlasek = [regex]::Matches(
    $Text.ToLowerInvariant(),
    '[aeiouyáéěíóúůý]'
).Count
$pocetSlov = [regex]::Matches($Text, '\S+').Count

Write-Output "Počet znaků s mezerami: $pocetZnaku"
Write-Output "Počet znaků bez mezer: $pocetBezMezer"
Write-Output "Počet samohlásek: $pocetSamohlasek"
Write-Output "Počet slov: $pocetSlov"