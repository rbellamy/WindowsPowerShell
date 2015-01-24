function Invoke-SqlDiag {
	
	[CmdletBinding()]
	param (
		
		[Parameter(Position = 0, Mandatory = $true)]
		[ValidateScript({ Test-Path $_ -PathType Container })]
		[String]
		$SupportFolderPath,
        
        [Parameter(Position = 1)]
        [ValidateRange(1, 1440)]
        [int]
        $RunMinutes,
		
		[Parameter()]
		[ValidateScript({ Test-Path $_ -PathType Leaf })]
		[String]
		$SqlDiagPath = "C:\Program Files\Microsoft SQL Server\100\Tools\Binn\SQLdiag.exe"
	)
	
	begin {
    
        $todayString = Get-Date -Format yyyyMMdd
        $stopTime = (Get-Date).AddMinutes($RunMinutes)
        $stopTimeString = "{0:yyyyMMdd_HH:mm:ss}" -f $stopTime
        
        $outputFolder = "$SupportFolderPath/Output/$todayString"
		
		$sqlDiagArgumentList = @()
		$sqlDiagArgumentList += "/O $outputFolder"
        $sqlDiagArgumentList += "/I pssdiag.xml"
		$sqlDiagArgumentList += "/P $SupportFolderPath"
		$sqlDiagArgumentList += "/E $stopTimeString"
		$sqlDiagArgumentList += "/N2"
		
        #$sqlDiagArgumentList
		Start-Process $SqlDiagPath $sqlDiagArgumentList -Wait -NoNewWindow
	}
}

function Remove-OldestDirectories {
	
	[CmdletBinding()]
	param (
		
		[Parameter(Position = 0, Mandatory = $true)]
		[ValidateScript({ Test-Path $_ -PathType Container })]
		[String]
		$Path,
		
		[Parameter(Position = 1)]
		[int]
		$DirectoriesToKeep = 2
	)
	
	begin {
		
		Write-Host "Removing oldest directories from $Path" -ForeGroundColor Red
		
		$directories = Get-ChildItem -Path $Path | Where-Object { $_.PSIsContainer } | Sort-Object LastWriteTime -Descending
		
		$directoryCount = $directories.Count
		
		if ($directoryCount -gt $DirectoriesToKeep) {
			for ($x = $DirectoriesToKeep; $x -lt $directoryCount; $x++) {
                Write-Host "Deleting " $directories[$x] -ForeGroundColor Red
				$directories[$x] | Remove-Item -Recurse -Force -Confirm:$false
			}
		}
        
        Write-Host "Done removing oldest directories from $Path" -ForeGroundColor Green
	}
}

function Move-Directories {
    [CmdletBinding()]
    param (
        
        [Parameter(Position = 0, Mandatory = $true)]
		[ValidateScript({ Test-Path $_ -PathType Container })]
        [String]
        $SourcePath,
        
        [Parameter(Position = 1, Mandatory = $true)]
		[ValidateScript({ Test-Path $_ -PathType Container })]
        [String]
        $DestinationPath
    )
    
    begin {
    
        Write-Host "Using RoboCopy to move folders from $SourcePath to $DestinationPath" -ForeGroundColor Red
        
        robocopy "$SourcePath" "$DestinationPath" /E /ZB /R:1 /W:10 /MOV
        
        if ($?) {
            Write-Host "Successfully used RoboCopy to move folders from $SourcePath to $DestinationPath" -ForeGroundColor Green        
        } else {
            Write-Warning "RoboCopy returned an error moving from $SourcePath to $DestinationPath"
        }
        
    }
}

$remoteServer = "SERVER1"
$supportFolderPath = "C:\Analysis"
$outputFolderPath = "$supportFolderPath\Output"
$remoteFolderPath = "\\$remoteServer\AnalysisData\SQLDiag\"

New-Item $outputFolderPath -Force -Type Container

Remove-OldestDirectories "$supportFolderPath\Output"

Invoke-SqlDiag $supportFolderPath 90

Move-Directories "$outputFolderPath" "$remoteFolderPath"