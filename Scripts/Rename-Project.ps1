#requires -version 2.0
[CmdletBinding()]
param (
    [parameter(Mandatory=$true)]
    [ValidateScript({ Test-Path -Path $_ })]
    [string]
    $Path,
	[parameter(Mandatory=$true)]
	[string]
	$OldText,
	[parameter(Mandatory=$true)]
	[string]
	$NewText,
	[parameter(Mandatory=$false)]
	[string[]]
	$Extension = ('.cs', '.csproj', '.sln', '.xml', '.config')
)

$ErrorActionPreference = 'Continue'
#Set-StrictMode -Version Latest

$Path = ($Path | Resolve-Path).ProviderPath

Get-ChildItem $Path -Recurse | %{$_.FullName} |
	Sort-Object -Property Length -Descending |
	% {
		Write-Host $_
		$Item = Get-Item $_
		$PathRoot = $Item.FullName | Split-Path
		$OldName = $Item.FullName | Split-Path -Leaf
		$NewName = $OldName -replace $OldText, $NewText
		$NewPath = $PathRoot | Join-Path -ChildPath $NewName
		if (!$Item.PSIsContainer -and $Extension -contains $Item.Extension) {
			(Get-Content $Item) | % {
				#Write-Host $_
				$_ -replace $OldText, $NewText
			} | Set-Content $Item
		}
		if ($OldName.Contains($OldText)) {
			Rename-Item -Path $Item.FullName -NewName $NewPath
		}

	}