@echo off
python setup.py build
mkdir tmp
if "%arch%"=="win32" (xcopy /E /Y /Q build\exe.win32-3.6 tmp) else (xcopy /E /Y /Q build\exe.win-amd64-3.6 tmp)
rem Update IPS if a new one has been built but not copied into new dir.
fc /b ff3msu.ips ..\patch\ff3msu.ips
if errorlevel 1 copy /Y ..\patch\ff3msu.ips ff3msu.ips
copy /Y ff3msu.ips tmp
copy /Y ff3msu.msu tmp
copy /Y ff3msu.xml tmp
copy /Y *.html tmp 
copy /Y *.bml tmp
copy /Y *.dat tmp
copy /Y *.xml tmp
copy /Y *.ico tmp
copy /Y *.png tmp
copy /Y *.wav tmp
rem Remove pyqt5 bloat. Every DLL and such in the following dir that's *actually used* is copied into the root folder anyway.
rem Modified: We need the "plugins" dir now due to the kefka laugh effect :P
if exist tmp\PyQt5\Qt\bin\qt.conf copy tmp\PyQt5\Qt\bin\qt.conf tmp\qt.conf.nol
if exist tmp\lib\PyQt5\Qt\bin\qt.conf copy tmp\lib\PyQt5\Qt\bin\qt.conf tmp\qt.conf.l
rmdir /S /Q tmp\PyQt5\Qt\bin
if exist tmp\qt.conf.nol mkdir tmp\PyQt5\Qt\bin
if exist tmp\qt.conf.nol copy tmp\qt.conf.nol tmp\PyQt5\Qt\bin\qt.conf
if exist tmp\qt.conf.nol del tmp\qt.conf.nol
rmdir /S /Q tmp\lib\PyQt5\Qt\bin
if exist tmp\qt.conf.l mkdir tmp\lib\PyQt5\Qt\bin
if exist tmp\qt.conf.l copy tmp\qt.conf.l tmp\lib\PyQt5\Qt\bin\qt.conf
if exist tmp\qt.conf.l del tmp\qt.conf.l
rmdir /S /Q tmp\PyQt5\Qt\qml
rmdir /S /Q tmp\lib\PyQt5\Qt\qml
rmdir /S /Q tmp\PyQt5\Qt\resources
rmdir /S /Q tmp\lib\PyQt5\Qt\resources
rmdir /S /Q tmp\PyQt5\Qt\translations
rmdir /S /Q tmp\lib\PyQt5\Qt\translations
cd tmp
"C:\Program Files\7-Zip\7z.exe" a -mf=off -r DancingMadInstaller.7z *.*
move DancingMadInstaller.7z ..
cd ..
copy /b 7zS.sfx + config.txt + DancingMadInstaller.7z DancingMadInstaller.exe
..\utils\reshacker\ResourceHacker.exe -open DancingMadInstaller.exe -save DancingMadInstaller-tmp.exe -action addoverwrite -res kefka.ico -mask ICONGROUP,MAINICON,
move /Y DancingMadInstaller-tmp.exe DancingMadInstaller.exe
rmdir /S /Q tmp
rmdir /S /Q build
del DancingMadInstaller.7z
echo Assuming no errors, the installer exe should now be built.
