#remove 'Microsoft.PowerShell.Core\FileSystem::' from UNC names
$currentPath = (get-location).Path 
if ($currentPath.startswith('Microsoft.PowerShell.Core\FileSystem::'))
{
  $currentPath = $currentPath.Substring(38)
}

$currentDateTime = Get-Date

Write-Host $currentDateTime.ToString('yyyy-MM-dd HH:mm:ss') -ForegroundColor Cyan
Write-Host $currentPath -foregroundcolor  Cyan

Enable-GitColors

$GitPromptSettings.BeforeText = "git["
$HgPromptSettings.BeforeText = "hg["

# Reset color, which can be messed up by Enable-GitColors
#Write-Host $GitPromptSettings
#$Host.UI.RawUI.ForegroundColor = $GitPromptSettings.DefaultForegroundColor

if ((get-location -stack).Count -gt 0) { 
	write-host ("+" * ((get-location -stack).Count) + " ") -NoNewLine -ForegroundColor Yellow 
}

if (isCurrentDirectoryARepository(".git")) {
    # Git Prompt
    $Global:GitStatus = Get-GitStatus
    Write-GitStatus $GitStatus
} elseif (isCurrentDirectoryARepository(".hg")) {
    # Mercurial Prompt
    $Global:HgStatus = Get-HgStatus
    Write-HgStatus $HgStatus
}

write-host ("»") -NoNewLine -ForegroundColor Green

return " "
