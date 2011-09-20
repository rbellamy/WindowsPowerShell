#remove 'Microsoft.PowerShell.Core\FileSystem::' from UNC names
$currentPath = (get-location).Path 
if ($currentPath.startswith('Microsoft.PowerShell.Core\FileSystem::'))
{
  $currentPath = $currentPath.Substring(38)
}

Write-Host $currentPath -foregroundcolor  Cyan
    
# Git Prompt
$Global:GitStatus = Get-GitStatus
Write-GitStatus $GitStatus

if ((get-location -stack).Count -gt 0) { write-host ("+" * ((get-location -stack).Count) + " ") -NoNewLine -ForegroundColor Yellow }

Write-Host ("»") -NoNewLine -ForegroundColor Green

return " "