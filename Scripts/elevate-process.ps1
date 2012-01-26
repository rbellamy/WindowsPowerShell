$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.Verb = "RunAs";

$ext = [System.IO.Path]::GetExtension($args[0]).ToLower()

# Find our powershell full path
$powershell = (Get-Command powershell).Definition;

if ($args.Length -eq 0) {
 	#if we pass no parameters, then launch PowerShell in the current location
	
    # Create a powershell process
    $psi.FileName = $powershell;
	
	$psi.Arguments = "-NoExit -Command &{Set-Location '" + (Get-Location).Path + "'}"
	
} elseif (($args.Length -eq 1) -and (test-path $args[0] -pathType Container)) {
	#if we pass in a folder location, then launch powershell in that location
	
	# Create a powershell process
    $psi.FileName = $powershell;
	
	$psi.Arguments = "-NoExit -Command &{set-location '" + (resolve-path $args[0]) + "'}"
	
} elseif ($ext -eq ".cmd" -or $ext -eq ".bat") {
 	#if we pass in a batch file, launch cmd in the current location and run the batch
	
	$psi.FileName = "cmd"
	
	$psi.Arguments = "/c ""cd /d " + (resolve-path .).Path + " && " + [string]::Join(' ', $args) + """"
	echo $psi.Arguments
}  
else #otherwise, launch the application specified in the arguments
{
	$psi.WorkingDirectory = Resolve-Path .
	$psi.Arguments = [String]::Join(' ', $args[1..$args.Length])

	if (Test-Path $args[0])
	{
		$psi.FileName = Resolve-Path $args[0]
	}
	elseif (find-in-path $args[0])
	{
		$psi.FileName = @(find-in-path $args[0])[0]
	}
	elseif (find-in-path ($args[0] + "*"))
	{
		$psi.FileName = @(find-in-path ($args[0] + "*"))[0]
	}
	else
	{
	  write-warning ("Can't find " + $args[0])
	  exit
	}
}

[System.Diagnostics.Process]::Start($psi)
