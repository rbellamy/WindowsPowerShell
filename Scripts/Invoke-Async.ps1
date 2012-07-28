<#
.Synopsis
   A means of running multiple instances of a cmdlet/function/scriptblock
.DESCRIPTION
   This function allows you to provide a cmdlet, function or script block with a set of data to allow multithreading.
.EXAMPLE
   $sb = [scriptblock] {param($system) gwmi win32_operatingsystem -ComputerName $system | select csname,caption}
   $servers = Get-Content servers.txt
   $rtn = Invoke-Async -Set $server -SetParam system  -ScriptBlock $sb
.EXAMPLE
   $servers = Get-Content servers.txt
   $rtn = Invoke-Async -Set $servers -SetParam computername -Params @{count=1} -Cmdlet Test-Connection -ThreadCount 50 
.INPUTS
   
.OUTPUTS
   Determined by the provided cmdlet, function or scriptblock.
.NOTES
    This can often times eat up a lot of memory due in part to how some cmdlets work. Test-Connection is a good example of this. 
    Although it is not a good idea to manually run the garbage collector it might be needed in some cases and can be run like so:
    [gc]::Collect()
#>

function Invoke-Async{
param(
#The data group to process, such as server names.
[parameter(Mandatory=$true)]
[object[]]$Set,
#The parameter name that the set belongs to, such as Computername.
[parameter(Mandatory=$true)]
[string] $SetParam,
#The Cmdlet for Function you'd like to process with.
[parameter(Mandatory=$true, ParameterSetName='cmdlet')]
[string]$Cmdlet,
#The ScriptBlock you'd like to process with
[parameter(Mandatory=$true, ParameterSetName='ScriptBlock')]
[scriptblock]$ScriptBlock,
#any aditional parameters to be forwarded to the cmdlet/function/scriptblock
[hashtable]$Params,
#number of jobs to spin up, default being 10.
[int]$ThreadCount=10
)
Begin
{

    $Threads = @()
    $Length = $JobsLeft = $Set.Length
    $Count = 0
    if($Length -lt $ThreadCount){$ThreadCount=$Length}
    $Jobs = 1..$ThreadCount  | ForEach-Object{$null}
    
    If($PSCmdlet.ParameterSetName -eq 'cmdlet')
    {
        $CmdType = (Get-Command $Cmdlet).CommandType
         If($CmdType -eq "Function")
        {
            $ScriptBlock = (Get-Item Function:\$Cmdlet).ScriptBlock
            1..$ThreadCount | ForEach-Object{ $Threads += [powershell]::Create().AddScript($ScriptBlock)}
        }
        ElseIf($CmdType -eq "Cmdlet")
        {
            1..$ThreadCount  | ForEach-Object{ $Threads += [powershell]::Create().AddCommand($Cmdlet)}
        }
    
    }
    Else
    {
        1..$ThreadCount | ForEach-Object{ $Threads += [powershell]::Create().AddScript($ScriptBlock)}
    }

    If($Params){$Threads | ForEach-Object{$_.AddParameters($Params) | Out-Null}}

}
Process
{
    while($JobsLeft)
    {
        for($idx = 0; $idx -lt $ThreadCount ; $idx++)
        {
            If($Jobs[$idx].IsCompleted) #job ran ok, clear it out
            {
                $Threads[$idx].EndInvoke($Jobs[$idx])
                $Jobs[$idx] = $null
                $JobsLeft-- #one less left
                write-verbose "Completed: $($Threads[$idx].Commands.Commands[0].Parameters | Where-Object {$_.Name -eq $SetParam} | Select-Object -ExpandProperty Value)"
            }
            If(($Count -lt $Length) -and ($Jobs[$idx] -eq $null)) #add job if there is more to process
            {
                write-verbose "starting: $($Set[$Count])"
                $Threads[$idx].Commands.Commands[0].Parameters.Remove(($Threads[$idx].Commands.Commands[0].Parameters | Where-Object{$_.Name -eq $SetParam})) | Out-Null #check for success?
                $Threads[$idx].AddParameter($SetParam,$Set[$Count]) | Out-Null
                $Jobs[$idx] = $Threads[$idx].BeginInvoke()
                $Count++
            }
        }

    }
}
End
{
    $Threads | ForEach-Object{$_.Runspace.Clos(); $_.Dispose();}
}
}