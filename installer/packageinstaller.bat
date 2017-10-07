@echo off
python setup.py build
mkdir temp
xcopy /E build\exe.win-amd64-3.5 temp
copy ff3msu.ips temp
copy ff3msu.msu temp
copy ff3msu.xml temp
copy *.html temp 
copy *.bml temp
copy *.dat temp
copy *.csv temp
cd temp
"C:\Program Files\7-Zip\7z.exe" a -r DancingMadInstaller.7z *.*
move DancingMadInstaller.7z ..
cd ..
copy /b 7zS.sfx + config.txt + DancingMadInstaller.7z DancingMadInstaller.exe
echo Assuming no errors, the installer exe should now be built. Remember when moving to Python 3.6 to adjust the build directory.