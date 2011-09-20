  $psi = new-object System.Diagnostics.ProcessStartInfo
  $psi.Verb = "runas";

  $ext = [system.io.path]::GetExtension($args[0]).ToLower()

  if ($args.length -eq 0) #if we pass no parameters, then launch PowerShell in the current location
  {
    $psi.FileName = 'powershell'
    $psi.Arguments = "-NoExit -Command &{set-location '" + (get-location).Path + "'}"
  }  
  elseif (($args.Length -eq 1) -and (test-path $args[0] -pathType Container)) #if we pass in a folder location, then launch powershell in that location
  {
    $psi.FileName = 'powershell'
    $psi.Arguments = "-NoExit -Command &{set-location '" + (resolve-path $args[0]) + "'}"
  }  
  elseif ($ext -eq ".cmd" -or $ext -eq ".bat") #if we pass in a batch file, launch cmd in the current location and run the batch
  {
    $psi.FileName = "cmd"
    $psi.Arguments = "/c ""cd /d " + (resolve-path .).Path + " && " + [string]::Join(' ', $args) + """"
    echo $psi.Arguments
  }  
  else #otherwise, launch the application specified in the arguments
  {
    $psi.WorkingDirectory = resolve-path .
    $psi.Arguments = [string]::Join(' ', $args[1..$args.length])

    if (test-path $args[0])
    {
      $psi.FileName = resolve-path $args[0]
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
  
  [System.Diagnostics.Process]::Start($psi) | out-null
