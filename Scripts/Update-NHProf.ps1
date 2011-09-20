if (Test-Path "env:ProgramFiles(x86)"){
    $outputdirectoryArg ="-oC:\Program Files (x86)\Nhibernate.Profiler"
}else{
    $outputdirectoryArg ="-oC:\Program Files\Nhibernate.Profiler"
}

if (@(get-process | where {$_.ProcessName -eq "nhprof"}).Count -gt 0){
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    [System.Windows.Forms.MessageBox]::Show("Please stop nhprof before updating it")
}else{
    $zip = "C:\Program Files\7-Zip\7z.exe"
    $latestNHibernate = @(Get-ChildItem C:\Users\rbellamy\Downloads\NHibernate* | sort-object -Property CreationTime -Descending )[0]

    &$zip x $latestNHibernate $outputdirectoryArg -Y
}