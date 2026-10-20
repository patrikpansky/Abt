# Vytvoření aliasů
Set-Alias np notepad.exe
Set-Alias ct control.exe

# Záloha do JSON a XML
$a = Get-Alias np, ct | Select-Object Name, Definition
$a | ConvertTo-Json | Set-Content aliasy.json
$a | Export-Clixml aliasy.xml

# Smazání a obnova z JSON
Remove-Item Alias:np, Alias:ct
(Get-Content aliasy.json -Raw | ConvertFrom-Json) | ForEach-Object { New-Alias $_.Name $_.Definition }
Get-Alias np, ct

# Smazání a obnova z XML
Remove-Item Alias:np, Alias:ct
Import-Clixml aliasy.xml | ForEach-Object { New-Alias $_.Name $_.Definition }
Get-Alias np, ct
