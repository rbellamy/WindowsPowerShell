param ([string]$addPath = "")

$curPathObj = Get-ItemProperty hkcu:\Environment path
$newPath = $curPathObj.Path + ";" + $addPath	
setx PATH $newPath