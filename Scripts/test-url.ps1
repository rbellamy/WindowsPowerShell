#requires –Version 2

param (
      # URL to be checked.
      [Parameter(ValueFromPipeline=$true)]
      [Alias('Link')]
      [String]$Url,
     
      # String contained in the successfull response html.
      # tags and wildcards can be used.
      # Default value: "*"
      [string]$OK_String = "*",
     
      # Encode url string as [System.Uri]
      # Default value: $False
      [switch] [boolean] $Encode = $False,
     
      # Html download timeout in MilliSeconds.
      # Not compatible with -Async:$False
      # Default value: 30000
      [int32]$TimeOutms = 30000,
     
      # TimeOut checking frequency in MilliSeconds.
      # Not compatible with -Async:$False
      # Default value: 20
      [int32]$ChkFreqms = 20,
     
      # Synchronous\Asynchronous download.
      # Synchronous mode ignores -TimeOut,-ChkFreq parameters.
      # Default value: $True
      [switch] [boolean] $Async = $True,
     
      # Number of MilliSeconds to wait until next try.
      # Default value: 10000
      [int32] $NextTryms = 10000,
     
      # The maximum number of download attempts.
      # Default value: 2
      [int32] $MaxTryNum = 2,
     
      # Captures the specified number of characters before and after the string with the match.
      # This allows you to view the match in context.
      # If you enter one number as the value of this parameter, that number determines the number of chars captured before and after the match.
      # If you enter two numbers as the value, the first number determines the number of chars before the match and the second number determines the number of lines after the match.
      # Default values: 256,256
      [int32[]] $ContextChars = (256,256),
     
      # Directory of Error Logs. Not compatible with -PassThru.
      # Default value: Disabled
      [string] $LogErrDir = "Disabled",
     
      # Delete logfiles older than this. [days]
      # Not compatible with -PassThru and -LogErrDir:$Disabled
      [int32] $DelOldDay = 100,
     
      # Returns PsObject as output.
      # Default value: $False
      [switch] [boolean] $PassThru = $False,
     
      # Get-Help Test-Url.ps1 -Full
      # Can be used with other parameters, but they will be ignored.
      # Default value: $False
      [switch] [boolean] $Help = $False
)

$ScriptInvoc = $MyInvocation

function Handle-XMLHttpRequest
{ #v20100130
      param (
            # method: CONNECT, DELETE, GET, HEAD, OPTIONS, POST, PUT, TRACE, or TRACK
            [string] $Method_fn             = "GET",
            [string] $Url_fn               = "http://www.w3.org/TR/XMLHttpRequest",
            # Asynchronous mode ignores -TimeOut,-ChkFreq parameters.
            [boolean] $Async_fn            = $true,
            # After the specified MilliSeconds ReadyState will not be DONE=4.
            [int32] $TimeOut_fn             = 30000,
            # Timeout checking frequency in MilliSeconds
            [int32] $ChkFreq_fn             = 25
      )
      $xHTTP = new-object -com:msxml2.xmlhttp;
      $xHTTP | add-member noteproperty StartTime (Get-Date) -Force
      $ResponseTime = [int32] (
            Measure-Command {
                  # open(method, url, async, user, password)
                  $xHTTP.open("$Method_fn",$Url_fn,$Async_fn);
                  if ( $Async_fn )
                  {
                        Write-Verbose "-Async:$Async specified."
                        $xHTTP.send();
                        while ( ($xHTTP.ReadyState -ne 4) -and (((Get-Date)-$xHTTP.StartTime).TotalMilliSeconds -lt $TimeOut_fn) )
                        {
                              # ReadyState: UNSENT=0 OPENED=1 HEADERS_RECEIVED=2 LOADING=3 DONE=4
                              Start-Sleep -MilliSeconds:$ChkFreq_fn
                              if ( $DebugPreference -ne "SilentlyContinue" )
                              {
                                    Write-Host $("DEBUG: ReadyState:$($xHTTP.ReadyState)   $([int]((Get-Date)-$xHTTP.StartTime).TotalMilliSeconds)[ms]"+" HTTP:$($xHTTP.status):$($xHTTP.statusText)") -ForegroundColor:Yellow -BackgroundColor:Black
                              }
                        }
                  }
                  else
                  {
                        Write-Verbose "-Async:$Async specified. -TimeOut,-ChkFreq arguments are ignored. Waiting for response..."
                        $xHTTP.send();
                  }
            }
      ).TotalMilliSeconds
      if ( $xHTTP.ReadyState -ne 4 )
      {
            $xHTTP | add-member noteproperty IsTimedOut 1
      }
      else
      {
            $xHTTP | add-member noteproperty IsTimedOut 0
      }
      $xHTTP | add-member noteproperty EndTime (Get-Date)
      if ( $ResponseTime -gt $ChkFreq_fn )
      {
            $xHTTP | add-member noteproperty ResponseTime ( $ResponseTime - ($ChkFreq_fn/2) )
      }
      else
      {
            $xHTTP | add-member noteproperty ResponseTime $ResponseTime
      }
      $xHTTP | add-member noteproperty fn_Method $Method_fn
      $xHTTP | add-member noteproperty fn_Url $Url_fn
      $xHTTP | add-member noteproperty fn_Async $Async_fn
      $xHTTP | add-member noteproperty fn_TimeOut $TimeOut_fn
      $xHTTP | add-member noteproperty fn_ChkFreq $ChkFreq_fn
      return $xHTTP
}

if ( $Help -or !$Url )
{
      Write-Verbose "-Help or no value for -Url specified."
      if ( Get-Item  $ScriptInvoc.MyCommand.Name -ErrorAction:SilentlyContinue )
      {
            Get-Help ".\$($ScriptInvoc.MyCommand.Name)" -Full
      }
      else
      {
            Get-Help $ScriptInvoc.MyCommand.Name -Full
      }
      Exit 0;
}

if ( $Url )
{
      Write-Verbose "-Url:$Url"
      if ( $Url -notmatch "://" )
      {
            $Url = "http://" + $Url
      }
      if ( $Encode )
      {
            $Url = [System.Uri]$Url
            if ( $Url.AbsoluteUri )
            {
                  $returnHtml | add-member noteproperty EncodedUrl $Url.AbsoluteUri
            }
      }
}

# Main action: Downloading
$TryNr_ = 0
while ( $TryNr_ -lt $MaxTryNum )
{
      $TryNr_++
      try
      {
            $returnHtml = Handle-XMLHttpRequest -Url_fn:$Url -Async_fn:$Async -TimeOut_fn:$TimeOutms -ChkFreq_fn:$ChkFreqms
      }
      catch
      {
            if ( $DebugPreference -ne "SilentlyContinue" ) { Write-Host "$($_.InvocationInfo.PositionMessage)" -ForegroundColor:Red }
            return $_.Exception.Message
      }
      if ( $returnHtml.responseText -like $OK_String )
      {
            $IsResponseTextDiff = $False
            break;
      }
      else
      {
            $IsResponseTextDiff = $True
            $outMsg_tmp= 'OK_String_not_found_'+'#'+"$TryNr_\$MaxTryNum "; $outMsg += $outMsg_tmp
            Write-Warning $outMsg_tmp
            if ( $TryNr_ -lt $MaxTryNum )
            {
                  $outMsg_tmp= "Waiting_"+"$NextTryms"+"ms."
                  $outMsg += $outMsg_tmp
                  Write-Warning $outMsg_tmp
                  $outMsg += "`r`n"
                  Start-Sleep -MilliSeconds:$NextTryms
            }
      }
} # while ( $TryNr_ -lt $MaxTryNum )

# Additional returnobject properties:
$returnHtml | add-member noteproperty ConsoleMsg "$outMsg"
$returnHtml | add-member noteproperty IsHtmlDiff ( [int32] $IsResponseTextDiff )
$returnHtml | add-member noteproperty CallerCmd $ScriptInvoc.Line
$returnHtml | add-member noteproperty OK_String $OK_String.Trim()
# Zoom to OK_String Context:
if ( $returnHtml.responseText.Length -gt 0 )
{
      $OK_Part2Find = $OK_String.Split('*') | Sort-Object -Property Length | Select-Object -Last:1
      $ContextCenter = $returnHtml.responseText.IndexOf($OK_Part2Find)
      $ContextLeft  = $ContextChars[0]
      if ( $ContextChars[1] -gt 0 )
      {
            $ContextRight = $ContextChars[1]
      }
      else
      {
            $ContextRight = $ContextChars[0]
      }
      Write-Verbose "$ContextCenter,$ContextLeft,$ContextRight=`t `$ContextCenter,`$ContextLeft,`$ContextRight"
      $ContextLength = $ContextLeft + $ContextRight + $OK_Part2Find.Length
      if ( $ContextCenter -gt 0 )
      {
            # $OK_String found in responseText
            if ( $ContextCenter -gt $ContextLeft )
            {
                  $SubStart = $ContextCenter - $ContextLeft
            }
            else
            {
                  $SubStart = 0
            }
            if ( $ContextCenter+$ContextRight -lt $returnHtml.responseText.Length-1 )
            {
                  $SubEnd = $ContextCenter+$ContextRight
            }
            else
            {
                  $SubEnd = $returnHtml.responseText.Length
            }
            $returnHtml | add-member noteproperty HtmlPreview $returnHtml.responseText.Substring($SubStart,$SubEnd-$SubStart)
            Write-Verbose "$SubStart,$SubEnd=`t`$SubStart,`$SubEnd"
      }
      else
      {
            # $OK_String NOT found (-1)
            if ( $returnHtml.responseText.Length -gt $ContextLength )
            {
                  $returnHtml | add-member noteproperty HtmlPreview $returnHtml.responseText.Remove($ContextLength)
            }
            else
            {
                  $returnHtml | add-member noteproperty HtmlPreview $returnHtml.responseText
            }
      }
      Write-Verbose "$($returnHtml.responseText.Length),$ContextLength,$OK_Part2Find=`t .responseLength,`$ContextLength,`$OK_Part2Find"
}
$returnHtml | add-member noteproperty ErrorMatrix $( $returnHtml.IsHtmlDiff.ToString() + ([int] ($returnHtml.status -ne 200)).ToString() + $returnHtml.IsTimedOut.ToString() )
     
if ( $PassThru )
{
      Write-Verbose "-PassThru:$PassThru"
      return $returnHtml
}
else
{
      # Standard Output Messages:
      $returnHtml | Format-List -Property StartTime,ErrorMatrix,IsHtmlDiff,IsTimedOut,status,ResponseTime,statusText,CallerCmd,EncodedUrl,OK_String,@{Label="HtmlPreview";Expression={ $_.HtmlPreview.Trim() }},ConsoleMsg
      # Checking response content and Set ExitCodes for caller process
      if ( $IsResponseTextDiff -or $Error )
      {    
            # Archiving :
            if ( $LogErrDir -ne "Disabled" )
            {
                  Write-Verbose "-LogErrDir:$LogErrDir"
                  if ( !$(Test-Path $LogErrDir) )
                  {
                        New-Item -ItemType:Container -Path:$LogErrDir
                  }
                  $LogFile     = "$LogErrDir\$(Get-Date -Format 'yyyyMMdd')" + ".log.txt"
                  Write-Verbose "`$LogFile=$LogFile"
                  Out-File -FilePath:"$LogFile" -InputObject:"$(Get-Date)  Started as $env:UserDomain\$env:UserName on $env:ComputerName $(Split-Path $ScriptInvoc.MyCommand.Path)" -Encoding:ASCII -Append #Log
                  Out-File -FilePath:"$LogFile" -InputObject:$returnHtml -Encoding:ASCII -Append
                  # Archiving $Error array:
                  if ( $Error )
                  {
                        $errStr = "`n" + 'Powershell $Error array:' + "`n"
                        foreach  ( $err_ in $Error )
                        {
                              $errStr = $errStr + "`r`n"
                              $errStr = $errStr + "$($err_.Exception.Message)"
                              $errStr = $errStr + "$($err_.InvocationInfo.PositionMessage)"
                        }
                        Out-File -FilePath:"$LogFile" -InputObject:$errStr -Encoding:ASCII -Append
                        Out-File -FilePath:"$LogFile" -InputObject:$("*" * 99) -Encoding:ASCII -Append
                  }
                  # Deleting old logfiles:
                  $oldFiles = Get-Item "$LogErrDir\*.*" | Where-Object { $_.LastWriteTime.AddDays($DelOldDay) -lt (Get-Date) }
                  if ( $oldFiles )
                  {
                        Write-Verbose "-DelOldDay:$DelOldDay"
                        foreach ( $oldFile_ in $oldFiles )
                        {
                              "Removing: $($oldFile_.FullName)  $($oldFile_.LastWriteTime)"
                              Remove-Item $oldFile_ -Force
                        }
                  }
            } # if ( $LogErrDir -ne "Disabled" )
            exit 1;
      }
      else
      {
            exit 0;
      } # if ( $IsResponseTextDiff )
} # if ( $PassThru )

<#
.SYNOPSIS
      Analyses whether an url is available.

.DESCRIPTION
      Returns the HTML page source and properties necessary for a detailed availability report.
      Supports integrated authentication.

.INPUTS
      You can pipe url input to this script.

.OUTPUTS
      Text representation table of ComObject:msxml2.xmlhttp with main properties. (without -PassThru)
      ComObject:msxml2.xmlhttp (with -PassThru)
     
.EXAMPLE
      .\test-url www.google.hu
      StartTime    : 2010-01-07 15:27:44
      ErrorMatrix  : 000
      IsHtmlDiff   : 0
      IsTimedOut   : 0
      status       : 200
      ResponseTime : 334
      statusText   : OK
      CallerCmd    : .\test-url www.google.hu
      OK_String    : *
    HtmlPreview  :
                   "http://www.w3.org/TR/html4/loose.dtd">
    ConsoleMsg   :

      This is the most simple example with a 1st positioned mandatory parameter.
      .\ prefix must be used when the script file is in the current directory, except the current directory is listed in PATH environment variable.
      Explanation of ErrorMatrix:  [[IsHtmlDiff?] [NOT(status=200)?] [IsTimedOut?]]

.EXAMPLE
      .\Test-Url.ps1 -Url:'http://www.w3.org/TR/XMLHttpRequest' -Next:1000 -Max:3 -OK:"*XMLHttpRequest*"
        Test-Url.ps1 http://www.w3.org/TR/XMLHttpRequest *XMLHttpRequest* -Next:1000 -Max:3

.EXAMPLE
      $Result = Test-Url.ps1 -U:'http://badDns.com:80/subdir/doit.jsp?arg1=str1&arg2=2' -OK:'This string is not the same as response html.' -Next:500 -Max:2 -TimeOut:1000 -PassThru
      if ( $Result.ErrorMatrix -eq "000" ) { return $True } else { return $False }
      False
     
      This example shows usage of -PassThru switch resulting a boolean.

.EXAMPLE
      PowerShell Test-Url.ps1 -Url:"'http://www.w3.org/TR/XMLHttpRequest'" -Next:1000 -Max:3 -OK:"*XMLHttpRequest*"
      PowerShell "Test-Url.ps1 -Url:'http://www.w3.org/TR/XMLHttpRequest'" -Next:1000 -Max:3 -OK:'*XMLHttpRequest*'"
     
      These examples show the usage from cmd.exe or scheduled task commandline.
      Strings contains spaces or special characters must be "'doublequoted'".
      Explanation: Cmd.exe shell uses "double" quotes only, while PowerShell.exe able to use both.

.EXAMPLE
      "www.google.hu" | Test-Url
      Only -Url string parameter can be piped.

.EXAMPLE
      "www.google.hu","www.w3.org" | Foreach-Object { Test-Url $_ }
      foreach ( $url in "www.google.hu","www.w3.org" ) { Test-Url $url }
     
      String arrays can be piped into foreach scriptblock.

.EXAMPLE
      $resultObj = Test-Url http://www.w3.org/TR/XMLHttpRequest -PassThru
      $resultObj.responseText | Out-File PageSource.html
     
      This example shows how to get\save the html source of a page.

.LINK
      http://povvershell.blogspot.com/2010/01/test-url.html
.LINK
      http://www.w3.org/TR/XMLHttpRequest

.NOTES
      mailto : karaszmiklos@gmail.com
      Version: 20100130
#>