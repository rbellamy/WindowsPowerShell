#remove 'Microsoft.PowerShell.Core\FileSystem::' from UNC names
$currentPath = (get-location).Path 
if ($currentPath.startswith('Microsoft.PowerShell.Core\FileSystem::'))
{
  $currentPath = $currentPath.Substring(38)
}

Write-Host $currentPath -foregroundcolor  Cyan

# Mercurial Prompt
$Global:HgStatus = Get-HgStatus
Write-HgStatus $HgStatus

if ((get-location -stack).Count -gt 0) { write-host ("+" * ((get-location -stack).Count) + " ") -NoNewLine -ForegroundColor Yellow }

write-host ("»") -NoNewLine -ForegroundColor Green

return " "