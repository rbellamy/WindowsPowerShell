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
if ($currentPath.StartsWith('Microsoft.PowerShell.Core\FileSystem::')) {
  $currentPath = $currentPath.Substring(38)
}

$currentDateTime = Get-Date

Write-Host $currentDateTime.ToString('yyyy-MM-dd HH:mm:ss') -ForegroundColor Cyan
Write-Host $currentPath -foregroundcolor  Cyan

if (Test-Path Function:Get-GitStatus) {

  $gitEnabled = $true
  Enable-GitColors
  $GitPromptSettings.BeforeText = "git["
}

if (Test-Path Function:Get-HgStatus) {

  $hgEnabled = $true
  $HgPromptSettings.BeforeText = "hg["
}

if (($gitEnabled -eq $true) -and (IsCurrentDirectoryARepository ".git" -eq $true)) {
    # Git Prompt
    $Global:GitStatus = Get-GitStatus
    Write-GitStatus $GitStatus
   Write-Host
}

if (($hgEnabled -eq $true) -and (IsCurrentDirectoryARepository ".hg" -eq $true)) {
  # Mercurial Prompt
  $Global:HgStatus = Get-HgStatus
  Write-VcsStatus $HgStatus
  Write-Host
}

Write-Host ("»") -NoNewLine -ForegroundColor Green

return " "