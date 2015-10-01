@echo off
echo Avengers, assemble!
echo. 
echo.
del *.ips
path C:\Users\dmorrison.LOCAL\Documents\BitBucket\DancingMadNew\utils;C:\Users\dmorrison.LOCAL\Documents\BitBucket\DancingMadNew\utils\wla-dx-9.5-win32-bin-2013-SVN-rev8-WJ;%PATH%
wla-65816 -vo ff3msu.asm ff3msu.obj
echo [objects] > ff3msu.link
echo ff3msu.obj >> ff3msu.link
wlalink -vr ff3msu.link ff3msu.sfc
flips --create --ips ff3.sfc ff3msu.sfc ff3msu.ips
del *.obj
del *.link
echo.
echo.
echo Patch is ready.