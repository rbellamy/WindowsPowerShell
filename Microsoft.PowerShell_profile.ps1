# 
# Set the $HOME variable for our use 
# and make powershell recognize ~\ as $HOME 
# in paths 
# 
set-variable -name HOME -value "D:\Development" -force 
(get-psprovider FileSystem).Home = $HOME 
set-variable -name Profile -Value "$Home\WindowsPowerShell\_profile.ps1"

. $profile