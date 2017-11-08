@echo off
python setup.py build
mkdir tmp
xcopy /E /Y /Q build\exe.win-amd64-3.6 tmp
rem Update IPS if a new one has been built but not copied into new dir.
fc /b ff3msu.ips ..\patch\ff3msu.ips
if errorlevel 1 copy /Y ..\patch\ff3msu.ips ff3msu.ips
copy /Y ff3msu.ips tmp
copy /Y ff3msu.msu tmp
copy /Y ff3msu.xml tmp
copy /Y *.html tmp 
copy /Y *.bml tmp
copy /Y *.dat tmp
copy /Y *.csv tmp
copy /Y *.ico tmp
copy /Y *.png tmp
copy /Y *.wav tmp
rem Remove pyqt5 bloat. Every DLL and such in the following dir that's *actually used* is copied into the root folder anyway.
rmdir /S /Q tmp\PyQt5\Qt
cd tmp
"C:\Program Files\7-Zip\7z.exe" a -r DancingMadInstaller.7z *.*
move DancingMadInstaller.7z ..
cd ..
copy /b 7zS.sfx + config.txt + DancingMadInstaller.7z DancingMadInstaller.exe
..\utils\reshacker\ResourceHacker.exe -open DancingMadInstaller.exe -save DancingMadInstaller-tmp.exe -action addoverwrite -res kefka.ico -mask ICONGROUP,MAINICON,
move /Y DancingMadInstaller-tmp.exe DancingMadInstaller.exe
rmdir /S /Q tmp
rmdir /S /Q build
del DancingMadInstaller.7z
echo Assuming no errors, the installer exe should now be built.
