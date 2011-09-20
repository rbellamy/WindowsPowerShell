#---------------------------------------------------------------
# CalculateSystemUpTimeFromEventLog.ps1
# ed wilson, msft, 9/6/2008
# 
# Creates a system.TimeSpan object to subtract date values
# Uses a .NET Framework class, system.collections.sortedlist to sort the events from eventlog.
#
#---------------------------------------------------------------
#Requires -version 2.0
Param($NumberOfDays = 30, [switch]$debug)

if($debug) { $DebugPreference = " continue" }

[timespan]$uptime = New-TimeSpan -start 0 -end 0
$currentTime = get-Date
$startUpID = 6005
$shutDownID = 6006
$minutesInPeriod = (24*60)*$NumberOfDays
$startingDate = (Get-Date -Hour 00 -Minute 00 -Second 00).adddays(-$numberOfDays)

Write-debug "'$uptime $uptime" ; start-sleep -s 1
write-debug "'$currentTime $currentTime" ; start-sleep -s 1
write-debug "'$startingDate $startingDate" ; start-sleep -s 1

$events = Get-EventLog -LogName system | 
Where-Object { $_.eventID -eq  $startUpID -OR $_.eventID -eq $shutDownID `
  -and $_.TimeGenerated -ge $startingDate } 

write-debug "'$events $($events)" ; start-sleep -s 1

$sortedList = New-object system.collections.sortedlist

ForEach($event in $events)
{
 $sortedList.Add( $event.timeGenerated, $event.eventID )
} #end foreach event
$uptime = $currentTime - $sortedList.keys[$($sortedList.Keys.Count-1)]
Write-Debug "Current uptime $uptime"

For($item = $sortedList.Count-2 ; $item -ge 0 ; $item -- )
{ 
 Write-Debug "$item `t `t $($sortedList.GetByIndex($item)) `t `
   $($sortedList.Keys[$item])" 
 if($sortedList.GetByIndex($item) -eq $startUpID)
 {
  $uptime += ($sortedList.Keys[$item+1] - $sortedList.Keys[$item])
  Write-Debug "adding uptime. `t uptime is now: $uptime"
 } #end if  
} #end for item 

"Total up time on $env:computername since $startingDate is " + "{0:n2}" -f `
  $uptime.TotalMinutes + " minutes."
$UpTimeMinutes = $Uptime.TotalMinutes
$percentDownTime = "{0:n2}" -f (100 - ($UpTimeMinutes/$minutesInPeriod)*100)
$percentUpTime = 100 - $percentDowntime

"$percentDowntime% downtime and $percentUpTime% uptime."