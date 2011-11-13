$Local:Command_Usage =
"usage: prepend-path path-to-be-added
"

if ($args.Length -lt 1) { return ($Command_Usage) }

$Local:oldPath = get-content Env:\Path
$Local:newPath = $args[0].ToString() + ";" + $local:oldPath
Set-Content Env:\Path $Local:newPath