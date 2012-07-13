## If your PC doesn't have this set already, someone could tamper with this script...
## but at least now, they can't tamper with any of the scripts that I auto-load!
#Set-ExecutionPolicy AllSigned Process
## add powershell profile folder and utilities folder to the path

function Append-Title {
	param([String] $title); 
	$Host.Ui.RawUi.WindowTitle = $Host.Ui.RawUi.WindowTitle + '(' + $title + ')'
}

#set the screen color based on the user role
$Host.UI.RawUI.Foregroundcolor="White"
$Host.UI.RawUI.Backgroundcolor="Black"

$Local:WindowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$Local:WindowsPrincipal = New-Object 'System.Security.Principal.WindowsPrincipal' $Local:WindowsIdentity
if ($Local:WindowsPrincipal.IsInRole("Administrators") -eq 1) {
	$Host.UI.RawUI.Backgroundcolor="DarkRed"
	Append-Title "Administrator"
} else {
	Append-Title "User"
}
Clear-Host

$ProfilePath = Split-Path $Profile
Write-Host $ProfilePath
$ScriptPath = $ProfilePath + "\Scripts"
$ModulePath = $ProfilePath + "\Modules"

. $ProfilePath\Scripts\prepend-path.ps1 $ScriptPath
## The following line is necessary if the Modules path is not already a part of the profile path.
## If the line is un-commented, and the modules path has already been added (e.g. as a result of
## being in the profile path, if this folder is symlinked to %USERPROFILE%\Documents), then you 
## will see modules available twice.
#$ENV:PSModulePath = "$ModulePath;" + $ENV:PSModulePath

## Maybe import PSCX - these extensions seem to have really bad behavior around getting help (crashes my powershell)
#Import-Module Pscx -ArgumentList $ScriptPath\Pscx.UserPreferences.ps1
## I determine which modules to pre-load here (WAS - in this SIGNED script)
#$AutoModules = 'Autoload', 'posh-git', 'posh-hg', 'Strings', 'Authenticode', 'HttpRest', 'PoshCode', 'PowerTab', 'ResolveAliases', 'PSCX'
#$AutoModules = 'Autoload', 'posh-git', 'posh-hg', 'PoshCode', 'posh-flow'
$AutoModules = 'Autoload', 'posh-git', 'posh-hg', 'PoshCode'

###################################################################################################
## Preload all the modules in AutoModules, printing out their names in color based on status
## No errors while loading modules (I will save them and print them out later)
$ErrorActionPreference = "SilentlyContinue"
Write-Host "Loading Modules: " -ForegroundColor Cyan -NoNewLine
$AutoRunErrors = @()
foreach( $Module in $AutoModules ) {
	Import-Module $Module -ErrorAction SilentlyContinue -ErrorVariable +Script:AutoRunErrors
	if($?) { 
		Write-Host "$Module " -ForegroundColor Cyan -NoNewLine 
	} else {
		Write-Host "$Module " -ForegroundColor Red -NoNewLine
	}
}

Write-Host
$ErrorActionPreference = "Continue"
# Write out the error messages if we missed loading any modules
if($AutoRunErrors) { $AutoRunErrors | Out-String | Write-Host -Fore Red }
###################################################################################################

## Relax the code signing restriction so we can actually get work done
Set-ExecutionPolicy RemoteSigned process

# always set the location to the $home path
Set-Location $Home

# PS's version of cd.. (no space) and recursive directory search
# since I can't remember the real commands
function cd.. { cd .. }
function dir/s { dir -r -i $Args[0] }

# pull in the aliases script.
. aliases

## posh-git and posh-hg TabExpansion
if(-not (Test-Path Function:\DefaultTabExpansion)) {
	Rename-Item Function:\TabExpansion DefaultTabExpansion
}

# Set up tab expansion and include git expansion
function TabExpansion($line, $lastWord) {
	$lastBlock = [regex]::Split($line, '[|;]')[-1]

	switch -regex ($lastBlock) {
		# Execute git tab completion for all git-related commands
		'git (.*)' { GitTabExpansion($lastBlock) }
		# mercurial and tortoisehg tab expansion
		'(hg|thg) (.*)' { HgTabExpansion($lastBlock) }
		# Fall back on existing tab expansion
		default { DefaultTabExpansion $line $lastWord }
	}
}

# override Prompt with prompt.ps1
if (Test-Path function:\prompt) { 
	Remove-Item -force function:\prompt
}