@echo off
set arch=win64
echo Packaging 64-bit Installer...
path C:\Windows\system32;C:\Windows\system32\wbem;C:\windows\system32\windowspowershell\v1.0\;C:\Program Files\Python310\Scripts;C:\Program Files\Python310
call packageinstaller.bat
move DancingMadInstaller.exe DancingMadInstaller-amd64.exe
pause
echo Packaging 32-bit Installer...
set arch=win32
path C:\Windows\system32;C:\Windows\system32\wbem;C:\windows\system32\windowspowershell\v1.0\;C:\Program Files (x86)\Python310-32\Scripts;C:\Program Files (x86)\Python310-32
call packageinstaller.bat
move DancingMadInstaller.exe DancingMadInstaller-i386.exe
pause