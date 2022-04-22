@echo off
set arch=win64
echo Packaging 64-bit Installer...
path C:\Windows\system32;C:\Windows\system32\wbem;C:\windows\system32\windowspowershell\v1.0\;%userprofile%\AppData\Local\Programs\Python\Python36\Scripts;%userprofile%\AppData\Local\Programs\Python\Python310
call packageinstaller.bat
move DancingMadInstaller.exe DancingMadInstaller-amd64.exe
pause
echo Packaging 32-bit Installer...
set arch=win32
path C:\Windows\system32;C:\Windows\system32\wbem;C:\windows\system32\windowspowershell\v1.0\;%userprofile%\AppData\Local\Programs\Python\Python36-32\Scripts;%userprofile%\AppData\Local\Programs\Python\Python310-32
call packageinstaller.bat
move DancingMadInstaller.exe DancingMadInstaller-i386.exe
pause