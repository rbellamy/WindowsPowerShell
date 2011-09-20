param([string]$path='.',$port=8080,$vpath='/',[switch]$browser)

function TryLocateWebDevServer($EnvVar, $SubPath) 
{
	$e = 'env:' + $EnvVar
	if (Test-Path $e) {
		$wdpath = Join-Path (Get-Content $e) (Join-Path $SubPath 'WebDev.WebServer.EXE')
		if (Test-Path $wdpath) {
			return $wdpath
		}
	}
	return $FALSE
}

if (-not $path -or -not (Test-Path $path)) {
	Throw "Invalid Path specified!"
}

$locations =
	('CommonProgramFiles(x86)', 'Microsoft Shared\DevServer\9.0'),
	('CommonProgramFiles', 'Microsoft Shared\DevServer\9.0'),
	('SystemRoot', 'Microsoft.NET\Framework\v2.0.50727')

foreach ($l in $locations) {
	$wdpath = TryLocateWebDevServer $l[0] $l[1]
	if ($wdpath) {
		break;
	}
}

if (-not $wdpath) {
	Throw 'Cannot locate WebDev.WebServer.EXE!'
}

$rpath = Resolve-Path $Path

Write-Host "http://localhost:$port"

Write-Host "Starting WebDev.WebServer located at:"
Write-Host " $wdpath"
Write-Host " Parameters: ""/path:$rpath"" ""/port:$Port"" ""/vpath:$VPath"""

& $wdpath "/path:$rpath" "/port:$Port" "/vpath:$VPath"

if ($browser)
{
  [System.Diagnostics.Process]::Start("http://localhost:$port")
}
