$iralias = get-alias ir -EA SilentlyContinue
if ($iralias -eq $null) {return}

$irbindir = split-path $iralias.Definition

function make-rubyfunction($cmd)
{
  $cmdpath = join-path $irbindir $cmd
  
  #if you're using Powershell v1, uncomment out the following
  #two lines and comment out the set-item function with the 
  #GetNewClosure call at the end
  
  #$p = "ir `"$cmdpath`" `$args"
  #set-item function:global:$cmd -Value $p

  set-item function:global:$cmd -Value { ir $cmdpath $args }.GetNewClosure()

  write-host "Added IronRuby $_ command"
}

("igem","iirb","irackup","irails","irake","irdoc","iri") | 
  %{make-rubyfunction $_} 