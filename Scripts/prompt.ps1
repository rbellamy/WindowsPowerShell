function IsCurrentDirectoryARepository {
	Param([String] $type);
    if ((Test-Path $type) -eq $TRUE) {
        return $TRUE
    }

    # Test within parent dirs
    $CheckIn = (Get-Item .).Parent
    while ($CheckIn -ne $NULL) {
        $PathToTest = $CheckIn.FullName + '/' + $type;
        if ((Test-Path $PathToTest) -eq $TRUE) {
            return $TRUE
        } else {
            $CheckIn = $CheckIn.Parent
        }
    }
    return $FALSE
}

$gitEnabled = $false
$hgEnabled = $false

#remove 'Microsoft.PowerShell.Core\FileSystem::' from UNC names
$currentPath = (Get-Location).Path 
if ($currentPath.startswith('Microsoft.PowerShell.Core\FileSystem::'))
{
  $currentPath = $currentPath.Substring(38)
}

$currentDateTime = Get-Date

Write-Host $currentDateTime.ToString('yyyy-MM-dd HH:mm:ss') -ForegroundColor Cyan
Write-Host $currentPath -foregroundcolor  Cyan

if (Test-Path Function:Enable-GitColors) {
	$gitEnabled = $true
	Enable-GitColors
	$GitPromptSettings.BeforeText = "git["
}

if (Test-Path Variable:script:$HgPromptSettings) {
	$hgEnabled = $true
	$HgPromptSettings.BeforeText = "hg["
}

# Reset color, which can be messed up by Enable-GitColors
#Write-Host $GitPromptSettings
#$Host.UI.RawUI.ForegroundColor = $GitPromptSettings.DefaultForegroundColor

if ((Get-Location -stack).Count -gt 0) { 
	Write-Host ("+" * ((Get-Location -stack).Count) + " ") -NoNewLine -ForegroundColor Yellow 
}

if ($gitEnabled -and (IsCurrentDirectoryARepository ".git" -eq $true)) {
    # Git Prompt
    $Global:GitStatus = Get-GitStatus
    Write-GitStatus $GitStatus
} elseif ($hgEnabled -and (IsCurrentDirectoryARepository ".hg" -eq $true)) {
    # Mercurial Prompt
    $Global:HgStatus = Get-HgStatus
    Write-HgStatus $HgStatus
}

Write-Host ("»") -NoNewLine -ForegroundColor Green

return " "
