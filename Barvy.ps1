foreach ($i in 0..15) {
    $c = [ConsoleColor]$i
    $t = "$c".PadRight(14)
    Write-Host $t -NoNewline
    Write-Host $t -ForegroundColor $c -NoNewline
    Write-Host $t -BackgroundColor $c -NoNewline
    Write-Host ""
}