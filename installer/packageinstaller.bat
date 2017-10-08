@echo off
python setup.py build
mkdir temp
xcopy /E /Y /Q build\exe.win-amd64-3.5 temp
copy /Y ff3msu.ips temp
copy /Y ff3msu.msu temp
copy /Y ff3msu.xml temp
copy /Y *.html temp 
copy /Y *.bml temp
copy /Y *.dat temp
copy /Y *.csv temp
copy /Y *.ico temp
copy /Y *.png temp
rem Remove pyqt5 bloat. Every DLL and such in the following dir that's *actually used* is copied into the root folder anyway.
rmdir /S /Q temp\PyQt5\Qt
cd temp
"C:\Program Files\7-Zip\7z.exe" a -r DancingMadInstaller.7z *.*
move DancingMadInstaller.7z ..
cd ..
copy /b 7zS.sfx + config.txt + DancingMadInstaller.7z DancingMadInstaller.exe
..\utils\reshacker\ResourceHacker.exe -open DancingMadInstaller.exe -save DancingMadInstaller-temp.exe -action addoverwrite -res kefka.ico -mask ICONGROUP,MAINICON,
move /Y DancingMadInstaller-temp.exe DancingMadInstaller.exe
rmdir /S /Q temp
del DancingMadInstaller.7z
echo Assuming no errors, the installer exe should now be built. Remember when moving to Python 3.6 to adjust the build directory.
