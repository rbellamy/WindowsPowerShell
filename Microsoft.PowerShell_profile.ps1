
# General variables
$computer = get-content env:computername
switch ($computer)
{
    “WORKCOMPUTER_NAME” {
        ReadyEnvironment “E:” “dlongnecker” $computer ; break }
    “HOMECOMPUTER_NAME” {
        ReadyEnvironment “D:” “david” $computer ; break }
    default {
        break; }
}

Push-Location (Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)

# Load posh-git module from current directory
# Import-Module .\posh-git

# If module is installed in a default location ($env:PSModulePath),
# use this instead (see about_Modules for more information):
Import-Module posh-git
# Import-Module Pscx


# Set up a simple prompt, adding the git prompt parts inside git repos
function prompt {
    Write-Host($pwd) -nonewline
        
    # Git Prompt
    $Global:GitStatus = Get-GitStatus
    Write-GitStatus $GitStatus
      
    return "> "
}

if(-not (Test-Path Function:\DefaultTabExpansion)) {
    Rename-Item Function:\TabExpansion DefaultTabExpansion
}

# Set up tab expansion and include git expansion
function TabExpansion($line, $lastWord) {
    $lastBlock = [regex]::Split($line, '[|;]')[-1]
    
    switch -regex ($lastBlock) {
        # Execute git tab completion for all git-related commands
        'git (.*)' { GitTabExpansion $lastBlock }
        # Fall back on existing tab expansion
        default { DefaultTabExpansion $line $lastWord }
    }
}

Enable-GitColors

Pop-Location

function ReadyEnvironment (
            [string]$sharedDrive,
            [string]$userName,
            [string]$computerName)
{
    set-variable tools “$sharedDrive\shared_tools” -scope 1
    set-variable scripts “$sharedDrive\shared_scripts” -scope 1
    set-variable rdpDirectory “$sharedDrive\shared_tools\RDP” -scope 1
    set-variable desktop “C:\Users\$userName\DESKTOP” -scope 1
    Write-Host “Setting environment for $computerName” -foregroundcolor cyan
}
New-Alias -name sudo "${env:HOMEDRIVE}${env:HOMEPATH}\Documents\WindowsPowerShell\sudo.ps1"

function aia {
    get-childitem | ?{ $_.extension -eq “.dll” } | %{ ai $_ }
}