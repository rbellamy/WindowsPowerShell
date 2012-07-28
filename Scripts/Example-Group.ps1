$Total = 0
$Path = "C:\Program Files\"
$Files = Get-ChildItem -recurse $Path -include *.jpg,*.gif,*.png,*.exe
$Files | Group-Object {$_.Extension.SubString(1)} | ForEach {
    $Total += $_.Count
    Write-Host "Number of $($_.Name): $($_.Count)"
}
Write-Host "Total: $Total"