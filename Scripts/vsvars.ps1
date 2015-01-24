function Get-Batchfile ($file) {
  $cmd = "`"$file`" & set"
  cmd /c "$cmd" | Foreach-Object {
    $p, $v = $_.split('=')
    Set-Item -path env:$p -value $v
  }
}

function VsVars32([int]$version = 10) {
  $versionKey = $version.ToString("00.0")
  
  $batFilename = "vsvars32.bat" 
  
  if($version -eq 11) {
    $batfilename = "vsdevcmd.bat"
  }
  
  $key = "HKLM:SOFTWARE\Microsoft\VisualStudio\" + $versionKey
  $VsKey = Get-ItemProperty $key
  $VsInstallPath = [System.IO.Path]::GetDirectoryName($VsKey.InstallDir)
  $VsToolsDir = [System.IO.Path]::GetDirectoryName($VsInstallPath)
  $VsToolsDir = [System.IO.Path]::Combine($VsToolsDir, "Tools")
  $batchPath = Join-Path $VsToolsDir $batFilename
  Get-Batchfile $batchPath
  [System.Console]::Title = "Visual Studio " + $versionKey + " Windows Powershell"
}