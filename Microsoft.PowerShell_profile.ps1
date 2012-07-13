# 
# Set the $HOME variable for our use 
# and make powershell recognize ~\ as $HOME 
# in paths 
# 
Set-Variable -Name HOME -Value "$Env:HOMEDRIVE$Env:HOMEPATH\Documents\Development" -Force 
(Get-PSProvider FileSystem).Home = $HOME 
Set-Variable -Name Profile -Value "$Home\WindowsPowerShell\_profile.ps1"

. $Profile