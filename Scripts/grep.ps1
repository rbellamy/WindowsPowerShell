param([string]$searchstr=$(throw "search string required"),[string]$searchdir=".\")

$searchdir = resolve-path($searchdir)

get-childitem $searchdir -recurse | 
  select-string -pattern $searchstr | 
  %{ Add-Member noteproperty "Relative Path" -InputObject $_ ($_.RelativePath($searchdir)); $_ } |
  Format-Table -property "Relative Path", LineNumber, Line -Autosize