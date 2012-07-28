function Test-SystemOrRootDirectory {

	param (
		[Parameter(Position = 0, Mandatory = $true)]
		[String]
		$Directory
	)
	
	$systemDirectories = [System.Enum]::GetValues([System.Environment+SpecialFolder]) | % { [System.Environment]::GetFolderPath($_); } | Where-Object { $_.Length -ne 0; };
		
	# check if it is an invalid directory path,
	# or just a bad string
	if (-not (Test-Path -Path $Directory)) {
		return $true;
	}

	$directoryInfo = New-Object System.IO.DirectoryInfo -ArgumentList $Directory

	# is it a root (disk drive)? 
	if ($directoryInfo.Parent -eq $null) {
		return $true;
	}

	$result = $false;
	$systemDirectories | % { $result = ($result -or $directoryInfo.FullName.Contains($_)); }
	$result;
}

Test-SystemOrRootDirectory D:\ExportTest