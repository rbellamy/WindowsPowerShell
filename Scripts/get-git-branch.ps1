$branches = $null
 
trap [System.Management.Automation.CommandNotFoundException]
{
  return $null
}

git branch --no-color 2>&1 | 
  % {            
      if($_ -match "^\*\s(.*)")
      {                
        $branches += $matches[1]            
      }        
    }

return $branches