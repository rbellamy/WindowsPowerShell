﻿function Export-AclTreeCsv {
<# 
 .Synopsis
  Exports the ACL migration values to a text file.

 .Description
  Maps the SIDs associated with ACLs to the IdentityReferences of those ACLs, then uses that map
  to replace the SIDs in the SDDL for those ACLs. Saves the results in a text file for use in
  setting ACLs on restored directories.

 .Parameter Path
  The path.
  
 .Parameter Recurse
  Include all sub-directories.
  
 .Parameter Filename
  The file to output the AclMigration to.

 .Example
  # Get the AclMigration values and save them to AclMigration.csv.
  Get-SidMap -path . -filename AclMigration.csv
#>
PARAM($path, [switch]$recurse, $filename)
    if (Test-Path($path)) {
        $computername = $env:computername
        $sidInfo = @{}
        Get-Acl $path | Select -expand Access |% {
            [string]$identity = $_.IdentityReference
            if (($identity.Contains($computername) -or $identity.Contains("Administrator")) -and !($sidInfo.ContainsKey($identity))) {
                $sid = New-Object System.Security.Principal.NTAccount($_.IdentityReference).Translate([System.Security.Principal.SecurityIdentifier])
                $sidInfo += @{$identity = $sid}
            }
        }
        #$sidInfo
        $dirInfo = @()
        [string]$sddl = Get-Acl $path | Select Sddl
        $sddl = $sddl.Substring($sddl.IndexOf("D:"))
        $sddl = -join ("O:BAG:SY", $sddl)
        foreach ($id in $sidInfo.Keys) {
            $user = $id.Replace($computername, [string]::Empty)
            $sddl = $sddl.Replace($sidInfo[$id], -join ("<<", $user, ">>"))
        }
        $dirInfo += $path | Select @{e={$_};n='Dir'},
                                   @{e={$sddl};n='SDDL'}
        if ($recurse.IsPresent) {
            ls -Rec $path |? {$_.PsIsContainer} |% {
                Get-Acl $_.fullname | Select -expand Access |% {
                    [string]$identity = $_.IdentityReference
                    if (($identity.Contains($computername) -or $identity.Contains("Administrator")) -and !($sidInfo.ContainsKey($identity))) {
                        $sid = New-Object System.Security.Principal.NTAccount($_.IdentityReference).Translate([System.Security.Principal.SecurityIdentifier])
                        $sidInfo += @{$identity = $sid}
                    }
                }
                $sddl = Get-Acl $_.fullname | Select Sddl
                $sddl = $sddl.Substring($sddl.IndexOf("D:"))
                $sddl = -join ("O:BAG:SY", $sddl)                
                foreach ($id in $sidInfo.Keys) {
                    $user = $id.Replace($computername, [string]::Empty)
                    $sddl = $sddl.Replace($sidInfo[$id], -join ("<<", $user, ">>"))
                }
                $dirInfo += $_ | Select @{e={$_.fullname};n='Dir'},
                                           @{e={$sddl};n='SDDL'}
                        
            }
        }
        
        if ($filename) {
            Write-Host "Exporting to $filename"
            $dirInfo | Export-Csv $filename
        } else {
            $dirInfo
        }
    }
}

function Import-AclTreeCsv {
<# 
 .Synopsis
  Imports the ACL migration values from a text file.

 .Description
  Imports the ACL migration values from a text file. Used to restore the ACLs on directories.

 .Parameter Path
  The path.
  
 .Parameter Filename
  The file to get the AclMigration from.

 .Example
  # Import the AclMigration values from AclMigration.csv.
  Import-AclTreeCsv -filename AclMigration.csv
#>
PARAM($filename)
    $dirList = Import-Csv $filename
    $computername = $env:computername
    $dirList |% {
        Write-Host "Working on $($_.Dir)"
        $sddl = $_.Sddl
        $sddlTemp = $_.Sddl
        do {
            if ($sddlTemp.Contains("<<")) {
                $firstIndex = $sddlTemp.IndexOf("<<")
                $lastIndex = $sddlTemp.IndexOf(">>")
                $id = $sddlTemp.Substring($firstIndex, $lastIndex - $firstIndex + 2)
                $sddlTemp = $sddlTemp.Substring($lastIndex + 2)
                $identity = $id.Replace("<<", $computername).Replace(">>", [string].Empty)
                $identityReference = New-Object System.Security.Principal.NTAccount($identity)
                [string]$sid = $identityReference.Translate([System.Security.Principal.SecurityIdentifier])
                $sddl = $sddl.Replace($id, $sid)
            }
        } while ($sddlTemp.IndexOf("<<") -ne -1)
        Write-Host $sddl
        $acl = (Get-Acl $_.Dir)
        $acl.SetSecurityDescriptorSddlForm($sddl)
        Set-Acl $_.Dir $acl
    }
}
export-modulemember -function Export-AclTreeCsv, Import-AclTreeCsv