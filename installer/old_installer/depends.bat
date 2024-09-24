@echo off
echo Preparing 64-bit environment...
path C:\Windows\system32;C:\Windows\system32\wbem;C:\windows\system32\windowspowershell\v1.0\;%userprofile%\AppData\Local\Programs\Python\Python36\Scripts;%userprofile%\AppData\Local\Programs\Python\Python36
python -m pip install --upgrade pip
pip install pyqt5 python-ips certifi pycurl cx-freeze
echo Preparing 32-bit environment...
path C:\Windows\system32;C:\Windows\system32\wbem;C:\windows\system32\windowspowershell\v1.0\;%userprofile%\AppData\Local\Programs\Python\Python36-32\Scripts;%userprofile%\AppData\Local\Programs\Python\Python36-32
python -m pip install --upgrade pip
pip install pyqt5 python-ips certifi pycurl cx-freeze
