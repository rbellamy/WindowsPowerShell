#requires -version 2.0
[CmdletBinding()]
param (
    [parameter(Mandatory=$true)]
    [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
    [string]
    $Path
)

$ErrorActionPreference = 'Stop'
#Set-StrictMode -Version Latest

$Path = ($Path | Resolve-Path).ProviderPath

$SolutionRoot = $Path | Split-Path

$SolutionProjectPattern = @"
(?x)
^ Project \( " \{ FAE04EC0-301F-11D3-BF4B-00C04F79EFBC \} " \)
\s* = \s*
" (?<name> [^"]* ) " , \s+
" (?<path> [^"]* ) " , \s+
"@

Get-Content -Path $Path |
    ForEach-Object {
        if ($_ -match $SolutionProjectPattern) {
			if([System.IO.Path]::IsPathRooted($Matches["path"])) {
            	$ProjectPath = $Matches['path']
			} else {
            	$ProjectPath = $SolutionRoot | Join-Path -ChildPath $Matches['path']
			}
			if(![System.IO.File]::Exists($ProjectPath)) {
				New-Object -TypeName PSObject -Property @{
					ProjectPath = $ProjectPath
					AssemblyName = "[PROJECT MISSING]"
				}
				return
			}
			$ProjectPath = ($ProjectPath | Resolve-Path).ProviderPath
            $ProjectRoot = $ProjectPath | Split-Path

            [xml]$Project = Get-Content -Path $ProjectPath 
            $nm = New-Object -TypeName System.Xml.XmlNamespaceManager -ArgumentList $Project.NameTable
            $nm.AddNamespace('x', 'http://schemas.microsoft.com/developer/msbuild/2003')

            $Project.SelectNodes('/x:Project/x:ItemGroup/x:Reference', $nm) |
            ForEach-Object {
                $RefPath = $null

				if($_.PSObject.Properties["HintPath"]) {
					$RefPath = $ProjectRoot | Join-Path -ChildPath $_.HintPath
				}

                % {
					if($_.PSObject.Properties["SpecificVersion"]) {
						New-Object -TypeName PSObject -Property @{
							ProjectPath = $ProjectPath
							AssemblyName = New-Object -TypeName Reflection.AssemblyName -ArgumentList $_.Include
							Path = $RefPath
							SpecificVersion = [Convert]::ToBoolean($_.SpecificVersion)
						}
					} else {
						New-Object -TypeName PSObject -Property @{
							ProjectPath = $ProjectPath
							AssemblyName = New-Object -TypeName Reflection.AssemblyName -ArgumentList $_.Include
							Path = $RefPath
						}
					}
				} |
                Add-Member -Name Name -MemberType ScriptProperty -Value {
                    $this.AssemblyName.Name
                } -PassThru |
                Add-Member -Name Exists -MemberType ScriptMethod -Value {
                    try {
                        return Test-Path -Path $this.Path -PathType Leaf
                    } catch {
                        return $false
                    }
                } -PassThru 
            }
			$Project.SelectNodes('/x:Project/x:ItemGroup/x:WebReferenceUrl', $nm) |
            ForEach-Object {
                $RefPath = $ProjectRoot | Join-Path -ChildPath $_.RelPath
				
                % {
					New-Object -TypeName PSObject -Property @{
						ProjectPath = $ProjectPath
						Url = New-Object -TypeName Uri -ArgumentList $_.Include
						Path = $RefPath
					}
				} |
                Add-Member -Name Name -MemberType ScriptProperty -Value {
                    $this.Path | Split-Path -Leaf
                } -PassThru |
                Add-Member -Name Exists -MemberType ScriptMethod -Value {
                    try {
                        #return Test-Url -Path $this.Path -PathType Leaf
						return $true
                    } catch {
                        return $false
                    }
                } -PassThru 
            }
        }
    }