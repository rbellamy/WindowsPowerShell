param($filter = $(throw "filename required"))

$env:path.Split(';') | %{dir -path $_ -filter $filter -ErrorAction SilentlyContinue } | %{$_.FullName}