
# some common aliases
# zip alias for 7za since powershell can't execute commands starting with digits
set-alias zip 7za
set-alias su elevate-process
Set-Alias vsrefs VSSolutionReferences
#set-alias ls 'ls -l'
#set-alias dir 'ls -G'

# Ipy / DySL helper aliases
#${env:IRONPYTHONPATH} = join-path $home 'projects\IronPython\Modules'

#find-to-set-alias 'c:\program files*\IronPython 2.0*' ipy.exe ipy 
#find-to-set-alias 'c:\program files*\IronPython 2.0*' ipy.exe ipy20 
#find-to-set-alias 'c:\program files*\IronPython 2.6*' ipy.exe ipy26 
#find-to-set-alias 'c:\program files*\IronPython 2.0*' ipyw.exe ipyw 
#find-to-set-alias 'c:\program files*\IronPython 2.0*' ipyw.exe ipyw20 
#find-to-set-alias 'c:\program files*\IronPython 2.6*' ipyw.exe ipyw26 

#find-to-set-alias 'c:\program files*\IronPython 2.0*' chiron.exe chiron 
#find-to-set-alias 'c:\program files*\IronPython 2.6*' chiron.exe chiron26 

#find-to-set-alias D:\HPierson.Files\Utilities\IPy_nightlybuild\Debug   ipy.exe ipymd 
#find-to-set-alias D:\HPierson.Files\Utilities\IPy_nightlybuild\Release ipy.exe ipym

#find-to-set-alias 'c:\Python25*' python.exe cpy 
#find-to-set-alias 'c:\Python25*' python.exe cpy25 
#find-to-set-alias 'c:\Python26*' python.exe cpy26 

find-to-set-alias 'c:\program files*\Microsoft Visual Studio 9.0\Common7\IDE' devenv.exe vs2008
find-to-set-alias 'c:\program files*\Microsoft Visual Studio 10.0\Common7\IDE' devenv.exe vs
#find-to-set-alias 'c:\program files*\Microsoft Visual Studio 9.0\Common7\IDE' tf.exe tf
find-to-set-alias 'C:\Windows\Microsoft.NET\Framework\v3.5' msbuild.exe msbuild35
find-to-set-alias 'C:\Windows\Microsoft.NET\Framework\v4.0.*' msbuild.exe msbuild40
find-to-set-alias 'C:\Windows\Microsoft.NET\Framework\v4.0.*' msbuild.exe msbuild

#find-to-set-alias 'c:\program files*\FSharp*' fsi.exe fsi 
#find-to-set-alias 'c:\program files*\FSharp*' fsc.exe fsc 
#find-to-set-alias 'c:\program files*\Microsoft Repository SDK*' ipad.exe ipad 
#find-to-set-alias 'c:\program files*\Microsoft Virtual PC*' 'Virtual pc.exe' vpc

find-to-set-alias 'C:\Program Files*\Notepad++' notepad++.exe npp
find-to-set-alias 'C:\Program Files*\Programmer''s Notepad' pn.exe pn
find-to-set-alias 'C:\Program Files*\*SQLite*' sqlite3.exe sqlite
#find-to-set-alias 'D:\Development\nant-0.90-bin\*' nant.exe nant
find-to-set-alias 'C:\Program Files*\PowerGUI' ScriptEditor.exe se