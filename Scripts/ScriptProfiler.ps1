################################################################################ 
param($logFilePath = $(throw "Please specify a path to the transcript log file.")) 

function Main 
{ 
    $uniqueLines = @{} 
    $samples = GetSamples $uniqueLines 
     
    "Breakdown by line:" 
    "----------------------------" 

    $counts = @{} 
    $totalSamples = 0; 
    foreach($item in $samples.Keys)  
    {  
       $counts[$samples[$item]] = $item  
       $totalSamples += $samples[$item] 
    } 

    foreach($count in ($counts.Keys | Sort-Object -Descending)) 
    { 
       $line = $counts[$count] 
       $percentage = "{0:#0}" -f ($count * 100 / $totalSamples) 
       "{0,3}%: Line {1,4} -{2}" -f $percentage,$line, 
          $uniqueLines[$line] 
    } 

    "" 
    "Breakdown by marked regions:" 
    "----------------------------" 
    $functionMembers = GenerateFunctionMembers 
     
    foreach($key in $functionMembers.Keys) 
    { 
        $totalTime = 0 
        foreach($line in $functionMembers[$key]) 
        { 
            $totalTime += ($samples[$line] * 100 / $totalSamples) 
        } 
         
        $percentage = "{0:#0}" -f $totalTime 
        "{0,3}%: {1}" -f $percentage,$key 
    } 
} 

function GetSamples($uniqueLines) 
{ 
    $logStream = [System.IO.File]::Open($logFilePath, "Open", "Read", "ReadWrite") 
    $logReader = New-Object System.IO.StreamReader $logStream 

    $random = New-Object Random 
    $samples = @{} 

    $lastCounted = $null 

    while(-not $host.UI.RawUI.KeyAvailable) 
    { 
       $sleepTime = [int] ($random.NextDouble() * 100.0) 
       Start-Sleep -Milliseconds $sleepTime 

       $rest = $logReader.ReadToEnd() 
       $lastEntryIndex = $rest.LastIndexOf("DEBUG: ") 

       if($lastEntryIndex -lt 0)  
       {  
          if($lastCounted) { $samples[$lastCounted] ++ } 
          continue;  
       } 
        
       $lastEntryFinish = $rest.IndexOf("\n", $lastEntryIndex) 
       if($lastEntryFinish -eq -1) { $lastEntryFinish = $rest.length } 

       $scriptLine = $rest.Substring(
            $lastEntryIndex, ($lastEntryFinish - $lastEntryIndex)).Trim() 
       if($scriptLine -match 'DEBUG:[ \t]*([0-9]*)\+(.*)') 
       { 
           $last = $matches[1] 
           
           $lastCounted = $last 
           $samples[$last] ++ 
            
           $uniqueLines[$last] = $matches[2] 
       } 

       $logReader.DiscardBufferedData() 
    } 

    $logStream.Close() 
    $logReader.Close() 
     
    $samples 
} 

function GenerateFunctionMembers 
{ 
    $callstack = New-Object System.Collections.Stack 
    $currentFunction = "Unmarked" 
    $callstack.Push($currentFunction) 

    $functionMembers = @{} 

    foreach($line in (Get-Content $logFilePath)) 
    { 
        if($line -match 'write-debug "ENTER (.*)"') 
        { 
            $currentFunction = $matches[1] 
            $callstack.Push($currentFunction) 
        } 
        elseif($line -match 'write-debug "EXIT"') 
        { 
            [void] $callstack.Pop() 
            $currentFunction = $callstack.Peek() 
        } 
        else 
        { 
            if($line -match 'DEBUG:[ \t]*([0-9]*)\+') 
            { 
                if(-not $functionMembers[$currentFunction]) 
                { 
                    $functionMembers[$currentFunction] = 
                        New-Object System.Collections.ArrayList 
                } 
                 
                if(-not $functionMembers[$currentFunction].Contains($matches[1])) 
                { 
                    [void] $functionMembers[$currentFunction].Add($matches[1]) 
                } 
            } 
        } 
    } 
     
    $functionMembers 
} 

. Main
