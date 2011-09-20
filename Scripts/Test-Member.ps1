function Test-Member { 
	<# 
	.ForwardHelpTargetName Get-Member 
	.ForwardHelpCategory Cmdlet 
	#> 
	[CmdletBinding()] 
	param( 
		[Parameter(ValueFromPipeline=$true)] 
		[System.Management.Automation.PSObject] 
		${InputObject}, 

		[Parameter(Position=0)] 
		[ValidateNotNullOrEmpty()] 
		[System.String[]] 
		${Name}, 

		[Alias('Type')] 
		[System.Management.Automation.PSMemberTypes] 
		${MemberType}, 

		[System.Management.Automation.PSMemberViewTypes] 
		${View}, 

		[Switch] 
		${Static}, 

		[Switch] 
		${Force} 
	) 
	begin { 
		try { 
			$outBuffer = $null 
			if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) { 
				$PSBoundParameters['OutBuffer'] = 1 
			} 
			$wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Get-Member', [System.Management.Automation.CommandTypes]::Cmdlet) 
			$scriptCmd = {& $wrappedCmd @PSBoundParameters | ForEach-Object -Begin {$members = @()} -Process {$members += $_} -End {$members.Count -ne 0}} 
			$steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin) 
			$steppablePipeline.Begin($PSCmdlet) 
		} 
		catch { 
			throw 
		} 
		} 
		process { 
		try { 
			$steppablePipeline.Process($_) 
		} 
		catch { 
			throw 
		} 
	} 
	end { 
		try { 
			$steppablePipeline.End() 
		} 
		catch { 
			throw 
		} 
	} 
}