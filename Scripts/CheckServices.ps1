Param ([string]$strFile)

$arrExclude = 
	"NT AUTHORITY\LocalService",
	"LocalSystem",
	".\ASPNET", 
	"NT AUTHORITY\NETWORK SERVICE", 
	"NT AUTHORITY\NetworkService"

$script:iAdmin = $script:iTot = $script:iCount = $script:iError = 0

function checkExclusions([string]$strval) {
	foreach ($val in $arrExclude) {
		if ($val.ToLower() -eq $strval)	{
			return $true
		}
	}
	return $false
}

function checkServicesOnComputer([string]$strComputer) {
	$iExcluded = $iIncluded = 0
	" "; "Checking computer $strComputer" 

	trap { "Error occurred"; $script:iError++; continue; }

	$results = gwmi win32_service -computer $strComputer -property name, startname, caption

	foreach ($result in $results) {
		$account = $result.StartName.ToLower()
		if (checkExclusions $account) {
			$iExcluded++;
		} else {
			$iIncluded++;
			$adminR = "\administrator";  ## admin-from-the-right
			if (($account.Length -ge $adminR.Length) -and
			($account.SubString($account.Length - $adminR.Length) -eq $adminR)) {
				$script:iAdmin++;
			}
			$adminL = "administrator@";  ## admin-from-the-left
			if (($account.Length -ge $adminL.Length) -and 
			($account.SubString(0, $adminL.Length) -eq $adminL)) {
				$script:iAdmin++;
			}
			"Account $account; Service " + $result.Name + "; Caption " + $result.Caption
		}
	}

	$script:iTot += $iIncluded;
}

function doProcess([string]$filename) {
	if($filename) {
		$computers = get-content $filename
		foreach ($computer in $computers) {
			if ($computer.SubString(0, 1) -eq "#") {
				$script:iComment++;
			} else {
				checkServicesOnComputer $computer;
				$script:iCount++;
			}
		}
	} else {
		foreach ($computer in $input) {
			checkServicesOnComputer $computer;
			$script:iCount++;
		}
	}
}

#
# Main
#

doProcess $strFile

" "
"Processing complete."
"Total computers processed: . . $script:iCount"
"Total Administrator services:  $script:iAdmin"
"Total special services:  . . . $script:iTot"
"Total comment lines: . . . . . $script:iComment"
"Total errors:  . . . . . . . . $script:iError"