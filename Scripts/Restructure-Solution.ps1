#requires -version 2.0
[CmdletBinding()]
param (
    [parameter(Mandatory=$true)]
    [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
    [string]
    $Path,

    [Parameter()]
    [switch]
    $Modify,

    [Parameter()]
    [switch]
    $PassThru
)

$ErrorActionPreference = 'Stop'
#Set-StrictMode -Version Latest

$Path = ($Path | Resolve-Path).ProviderPath

$solutionRoot = $Path | Split-Path

$solutionProjectPattern = @"
(?x)
^ Project \( " \{ (FAE04EC0-301F-11D3-BF4B-00C04F79EFBC|F184B08F-C81C-45F6-A57F-5ABD9991F28F) \} " \)
\s* = \s*
" (?<name> [^"]* ) " , \s+
" (?<path> [^"]* ) " , \s+
"@

Get-Content -Path $Path |
    % {
        if ($_ -match $solutionProjectPattern) {

            $projectNames = @()
            $projectReferences = @()
            $projectWebReferences = @()
            $projectCompileIncludes = @()
            $projectEmbeddedResources = @()
            $projectNoneIncludes = @()
            $projectContentIncludes = @()
        
			if([System.IO.Path]::IsPathRooted($Matches["path"])) {
            	$projectPath = $Matches['path']
			} else {
            	$projectPath = $solutionRoot | Join-Path -ChildPath $Matches['path']
			}

            $projectName = $Matches["name"]
            $projectNames += $projectName

			if(![System.IO.File]::Exists($projectPath)) {
				New-Object -TypeName PSObject -Property @{
					ProjectPath = $projectPath
					AssemblyName = "[PROJECT MISSING]"
				}
				return
			}
			$projectPath = ($projectPath | Resolve-Path).ProviderPath
            $projectRoot = $projectPath | Split-Path

            [xml]$project = Get-Content -Path $projectPath 
            $nm = New-Object -TypeName System.Xml.XmlNamespaceManager -ArgumentList $project.NameTable
            $nm.AddNamespace('x', 'http://schemas.microsoft.com/developer/msbuild/2003')
            
            ## references
            $projectReference = $project.SelectNodes('/x:Project/x:ItemGroup/x:Reference', $nm) |
            % {
                $refPath = $null
                $relPath = $null

				if($_.PSObject.Properties["HintPath"]) {
					$refPath = $projectRoot | Join-Path -ChildPath $_.HintPath
                    $relPath = $_.HintPath
				}

                % {
					if($_.PSObject.Properties["SpecificVersion"]) {
						New-Object -TypeName PSObject -Property @{
                            DependencyType = "Reference"
                            ProjectName = $projectName
							ProjectPath = $projectPath
							AssemblyName = New-Object -TypeName Reflection.AssemblyName -ArgumentList $_.Include
							Path = $refPath
                            RelativePath = $relPath
							SpecificVersion = [Convert]::ToBoolean($_.SpecificVersion)
						}
					} else {
						New-Object -TypeName PSObject -Property @{
                            DependencyType = "Reference"
                            ProjectName = $projectName
							ProjectPath = $projectPath
							AssemblyName = New-Object -TypeName Reflection.AssemblyName -ArgumentList $_.Include
							Path = $refPath
                            RelativePath = $relPath
						}
					}
				} |
                Add-Member -Name Name -MemberType ScriptProperty -Value {
                    $this.AssemblyName.Name
                } -PassThru |
                Add-Member -Name Exists -MemberType ScriptMethod -Value {
                    try {
                        if ($this.Path) {
                            Test-Path -Path $this.Path -PathType Leaf
                        } else {
                            $true
                        }
                    } catch {
                        $false
                    }
                } -PassThru 
            };

            if ($projectReference) {
                $projectReferences += $projectReference
            }
            
            ## web references
			$projectWebReference = $project.SelectNodes('/x:Project/x:ItemGroup/x:WebReferenceUrl', $nm) |
            % {
                $refPath = $projectRoot | Join-Path -ChildPath $_.RelPath
				
                % {
					New-Object -TypeName PSObject -Property @{
                        DependencyType = "WebReference"
                        ProjectName = $projectName
						ProjectPath = $projectPath
						Url = New-Object -TypeName Uri -ArgumentList $_.Include
						Path = $refPath
                        RelativePath = $_.RelPath
					}
				} |
                Add-Member -Name Name -MemberType ScriptProperty -Value {
                    $this.Path | Split-Path -Leaf
                } -PassThru |
                Add-Member -Name Exists -MemberType ScriptMethod -Value {
                    try {
                        #if ($(Test-Url $this.Path).ErrorMatrix -eq "000") {
                        #    $true
                        #} else {
                        #    $false
                        #}
                        $null
                    } catch {
                        $false
                    }
                } -PassThru 
            };

            if ($projectWebReference) {
                $projectWebReferences += $projectWebReference
            }

            ## embedded resources
			$projectEmbeddedResource = $project.SelectNodes('/x:Project/x:ItemGroup/x:EmbeddedResource', $nm) |
            % {
                $refPath = $projectRoot | Join-Path -ChildPath $_.Include

                % {
					New-Object -TypeName PSObject -Property @{
                        DependencyType = "EmbeddedResource"
                        ProjectName = $projectName
						ProjectPath = $projectPath
						Path = $refPath
                        RelativePath = $_.Include
				    }
				} |
                Add-Member -Name Name -MemberType ScriptProperty -Value {
                    $this.Path | Split-Path -Leaf
                } -PassThru |
                Add-Member -Name Exists -MemberType ScriptMethod -Value {
                    try {
                        Test-Path -Path $this.Path -PathType Leaf
                    } catch {
                        $false
                    }
                } -PassThru 
            };

            if ($projectEmbeddedResource) {
                $projectEmbeddedResources += $projectEmbeddedResource
            }
                        
            ## code
			$projectCompileInclude = $project.SelectNodes('/x:Project/x:ItemGroup/x:Compile', $nm) |
            % {
                $refPath = $projectRoot | Join-Path -ChildPath $_.Include

                % {
					New-Object -TypeName PSObject -Property @{
                        DependencyType = "Source"
                        ProjectName = $projectName
						ProjectPath = $projectPath
						Path = $refPath
                        RelativePath = $_.Include
				    }
				} |
                Add-Member -Name Name -MemberType ScriptProperty -Value {
                    $this.Path | Split-Path -Leaf
                } -PassThru |
                Add-Member -Name Exists -MemberType ScriptMethod -Value {
                    try {
                        Test-Path -Path $this.Path -PathType Leaf
                    } catch {
                        $false
                    }
                } -PassThru 
            };

            if ($projectCompileInclude) {
                $projectCompileIncludes += $projectCompileInclude
            }
            
            ## none includes
			$projectNoneInclude = $project.SelectNodes('/x:Project/x:ItemGroup/x:None', $nm) |
            % {
                $refPath = $projectRoot | Join-Path -ChildPath $_.Include

                % {
					New-Object -TypeName PSObject -Property @{
                        DependencyType = "None"
                        ProjectName = $projectName
						ProjectPath = $projectPath
						Path = $refPath
                        RelativePath = $_.Include
				    }
				} |
                Add-Member -Name Name -MemberType ScriptProperty -Value {
                    $this.Path | Split-Path -Leaf
                } -PassThru |
                Add-Member -Name Exists -MemberType ScriptMethod -Value {
                    try {
                        Test-Path -Path $this.Path -PathType Leaf
                    } catch {
                        $false
                    }
                } -PassThru 
            };

            if ($projectNoneInclude) {
                $projectNoneIncludes += $projectNoneInclude
            }
            
            ## content includes
			$projectContentInclude = $project.SelectNodes('/x:Project/x:ItemGroup/x:Content', $nm) |
            % {
                $refPath = $projectRoot | Join-Path -ChildPath $_.Include

                % {
					New-Object -TypeName PSObject -Property @{
                        DependencyType = "None"
                        ProjectName = $projectName
						ProjectPath = $projectPath
						Path = $refPath
                        RelativePath = $_.Include
				    }
				} |
                Add-Member -Name Name -MemberType ScriptProperty -Value {
                    $this.Path | Split-Path -Leaf
                } -PassThru |
                Add-Member -Name Exists -MemberType ScriptMethod -Value {
                    try {
                        Test-Path -Path $this.Path -PathType Leaf
                    } catch {
                        $false
                    }
                } -PassThru 
            };

            if ($projectContentInclude) {
                $projectContentIncludes += $projectContentInclude
            }

            # passthru
            if ($PassThru) {
                $projectReferences
                $projectWebReferences
                $projectCompileIncludes
                $projectEmbeddedResources
                $projectNoneIncludes
                $projectContentIncludes
            }

            # modify            
            if ($Modify) {
            
                $workingDirectory = (Get-Location -PSProvider FileSystem).ProviderPath                
                [Environment]::CurrentDirectory = $workingDirectory

                New-Item "$workingDirectory\lib","$workingDirectory\src" -Type Directory -Force -Verbose                

                # create dirs
                foreach ($projName in $projectNames) {
                    $projPath = "$workingDirectory\src" | Join-Path -ChildPath $projName

                    if (-not (Test-Path $projPath -PathType Container)) {
                        New-Item -Force $projPath -Type Directory -Verbose
                    }
                }

                # copy
                ## references
                foreach ($projectRef in $projectReferences) {
                    if (Test-Path "$workingDirectory\$($projectRef.ProjectName)" -PathType Container) {
                        Set-Location "$workingDirectory\$($projectRef.ProjectName)"
                    }

                    if ($projectRef.RelativePath -and (Test-Path "$($projectRef.RelativePath)" -PathType Leaf)) {
                        Copy-Item "$($projectRef.RelativePath)" -Destination "$workingDirectory\lib" -Force -Verbose
                    }

                    Set-Location $workingDirectory
                }
    
                ## web references
                foreach ($projectWebRef in $projectWebReferences) {
                    $projPath = "$workingDirectory\src" | Join-Path -ChildPath $projectWebRef.ProjectName

                    if (Test-Path "$workingDirectory\$($projectWebRef.ProjectName)" -PathType Container) {
                        Set-Location "$workingDirectory\$($projectWebRef.ProjectName)"
                    }

                    if (Test-Path "$($projectWebRef.RelativePath)" -PathType Container) {
                        Copy-Item "$($projectWebRef.RelativePath)" -Destination "$projPath\$($projectWebRef.RelativePath)" -Recurse -Force -Verbose
                    }

                    Set-Location $workingDirectory
                }

                ## embedded resources
                foreach ($projectResource in $projectEmbeddedResources) {
                    $projPath = "$workingDirectory\src" | Join-Path -ChildPath $projectResource.ProjectName

                    if (Test-Path "$workingDirectory\$($projectResource.ProjectName)" -PathType Container) {
                        Set-Location "$workingDirectory\$($projectResource.ProjectName)"
                    }

                    if (Test-Path "$($projectResource.RelativePath)" -PathType Leaf) {
                        New-Item -ItemType File -Path "$projPath\$($projectResource.RelativePath)" -Force -Verbose
                        Copy-Item "$($projectResource.RelativePath)" -Destination "$projPath\$($projectResource.RelativePath)" -Force -Verbose
                    }

                    Set-Location $workingDirectory
                }
                
                ## code
                foreach ($projectCode in $projectCompileIncludes) {
                    $projPath = "$workingDirectory\src" | Join-Path -ChildPath $projectCode.ProjectName

                    if (Test-Path "$workingDirectory\$($projectCode.ProjectName)" -PathType Container) {
                        Set-Location "$workingDirectory\$($projectCode.ProjectName)"
                    }

                    if (Test-Path "$($projectCode.RelativePath)" -PathType Leaf) {
                        New-Item -ItemType File -Path "$projPath\$($projectCode.RelativePath)" -Force -Verbose
                        Copy-Item "$($projectCode.RelativePath)" -Destination "$projPath\$($projectCode.RelativePath)" -Force -Verbose
                    }

                    # resx
                    $resxName = "$($projectCode.RelativePath -replace "vb","resx")"
                    if (Test-Path $resxName -PathType Leaf) {
                        Copy-Item $resxName -Destination "$projPath\$resxName" -Force -Verbose
                    }
                    
                    # designer
                    $designerName = "$($projectCode.RelativePath -replace "vb","Designer.vb")"
                    if (Test-Path $designerName -PathType Leaf) {
                        Copy-Item $designerName -Destination "$projPath\$designerName" -Force -Verbose
                    }

                    Set-Location $workingDirectory
                }
                
                ## none includes
                foreach ($projectNone in $projectNoneIncludes) {
                    $projPath = "$workingDirectory\src" | Join-Path -ChildPath $projectNone.ProjectName

                    if (Test-Path "$workingDirectory\$($projectNone.ProjectName)" -PathType Container) {
                        Set-Location "$workingDirectory\$($projectNone.ProjectName)"
                    }

                    if (Test-Path $projectNone.RelativePath -PathType Leaf) {
                        New-Item -ItemType File -Path "$projPath\$($projectNone.RelativePath)" -Force -Verbose
                        Copy-Item $projectNone.RelativePath -Destination "$projPath\$($projectNone.RelativePath)" -Force -Verbose
                    }

                    Set-Location $workingDirectory
                }
                
                ## content includes
                foreach ($projectContent in $projectContentIncludes) {
                    $projPath = "$workingDirectory\src" | Join-Path -ChildPath $projectContent.ProjectName

                    if (Test-Path "$workingDirectory\$($projectContent.ProjectName)" -PathType Container) {
                        Set-Location "$workingDirectory\$($projectContent.ProjectName)"
                    }

                    if (Test-Path "$($projectContent.RelativePath)" -PathType Leaf) {
                        New-Item -ItemType File -Path "$projPath\$($projectContent.RelativePath)" -Force -Verbose
                        Copy-Item "$($projectContent.RelativePath)" -Destination "$projPath\$($projectContent.RelativePath)" -Force -Verbose
                    }

                    Set-Location $workingDirectory
                }
    
                # remove old
                ## references
                foreach ($projectRef in $projectReferences) {
    
                    if (Test-Path "$workingDirectory\$($projectRef.ProjectName)" -PathType Container) {
                        Set-Location "$workingDirectory\$($projectRef.ProjectName)"
                    }

                    if ($projectRef.RelativePath -and (Test-Path "$($projectRef.RelativePath)" -PathType Leaf)) {
                        Remove-Item "$($projectRef.RelativePath)" -Force -Verbose
                    }

                    Set-Location $workingDirectory
                }
    
                ## web references
                foreach ($projectWebRef in $projectWebReferences) {
    
                    if (Test-Path "$workingDirectory\$($projectWebRef.ProjectName)" -PathType Container) {
                        Set-Location "$workingDirectory\$($projectWebRef.ProjectName)"
                    }
                    
                    if (Test-Path "$($projectWebRef.RelativePath)" -PathType Leaf) {
                        Remove-Item "$($projectWebRef.RelativePath)"  -Recurse -Force -Verbose
                    }

                    Set-Location $workingDirectory
                }
                
                ## code
                foreach ($projectCode in $projectCompileIncludes) {    
    
                    if (Test-Path "$workingDirectory\$($projectCode.ProjectName)" -PathType Container) {
                        Set-Location "$workingDirectory\$($projectCode.ProjectName)"
                    }

                    if (Test-Path "$($projectCode.RelativePath)" -PathType Leaf) {
                        Remove-Item "$($projectCode.RelativePath)" -Force -Verbose
                        
                        #resx
                        $resxName = "$($projectCode.RelativePath -replace "vb","resx")"
                        if (Test-Path $resxName -PathType Leaf) {
                            Remove-Item $resxName  -Force -Verbose
                        }
                        
                        #designer
                        $designerName = "$($projectCode.RelativePath -replace "vb","Designer.vb")"
                        if (Test-Path $designerName -PathType Leaf) {
                            Remove-Item $designerName  -Force -Verbose
                        }
                    }

                    Set-Location $workingDirectory
                }

                ## embedded resources
                foreach ($projectResource in $projectEmbeddedResources) {    
    
                    if (Test-Path "$workingDirectory\$($projectResource.ProjectName)" -PathType Container) {
                        Set-Location "$workingDirectory\$($projectResource.ProjectName)"
                    }

                    if (Test-Path "$($projectResource.RelativePath)" -PathType Leaf) {
                        Remove-Item "$($projectResource.RelativePath)" -Force -Verbose
                    }

                    Set-Location $workingDirectory
                }

                ## none include
                foreach ($projectNone in $projectNoneIncludes) {    
    
                    if (Test-Path "$workingDirectory\$($projectNone.ProjectName)" -PathType Container) {
                        Set-Location "$workingDirectory\$($projectNone.ProjectName)"
                    }

                    if (Test-Path "$($projectNone.RelativePath)" -PathType Leaf) {
                        Remove-Item "$($projectNone.RelativePath)" -Force -Verbose
                    }

                    Set-Location $workingDirectory
                }

                ## content include
                foreach ($projectContent in $projectContentIncludes) {    
    
                    if (Test-Path "$workingDirectory\$($projectContent.ProjectName)" -PathType Container) {
                        Set-Location "$workingDirectory\$($projectContent.ProjectName)"
                    }

                    if (Test-Path "$($projectContent.RelativePath)" -PathType Leaf) {
                        Remove-Item "$($projectContent.RelativePath)" -Force -Verbose
                    }

                    Set-Location $workingDirectory
                }

                # move project files and delete project dir if exists
                foreach ($projectName in $projectNames) {
                    
                    if (Test-Path "$workingDirectory\$projectName" -PathType Container) {
                        Set-Location "$workingDirectory\$projectName"
                    }

                    if (Test-Path "$projectName.*proj") {
                        Copy-Item "$projectName.*proj" -Destination "$workingDirectory\src\$projectName" -Force -Verbose
                        Remove-Item "$projectName.*proj" -Force -Verbose
                    }

                    Set-Location $workingDirectory
                }
            }
        }
    }
