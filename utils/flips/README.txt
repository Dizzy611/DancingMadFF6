LiteIPS
=======
LiteIPS is a command-line IPS (International Patching System) patcher for Windows, Linux and Mac. 

LiteIPS may be updated from time to time. You can always find the latest release on the following page: http://www.codeisle.com/liteips-command-line-ips-patcher

Features
========
* Patching to a file.

* Optional patching to a copy of a file (so that the original is not modified.)

* Patching using an IPS patch located online.

* If patching fails with an error, then no files will be modified.

* Single application that runs on all major operating systems.

* Small application file size.

Requirements
============
* Microsoft .NET Framework 3.5+ or Mono 2.10.9+.

Command-line usage
==================
	liteips.exe [options] patch source [output]

If using Mono:

	mono liteips.exe [options] patch source [output]

Explanation of the above: 
* [options]: the only option currently available is -f. Option -f forces patching to succeed, suppressing any warnings.
* patch: the IPS patch to apply. It can be a file on disk (e.g. "mypatch.ips") or a URL (e.g. "http://www.example.com/mypatch.ips").
* source: the file to patch (e.g. "mygame.bin"). 
* [output]: an optional output file. If this argument is specified, then source is copied to output before being patched.

Below is an example of patching a file ("mario.bin") with an IPS patch ("mario_extreme.ips") to a new output file ("mario_copy.bin") with forced patching (-f).
    
	liteips.exe -f "mario_extreme.ips" "mario.bin" "mario_copy.bin"

Support
=======
Post a question or get help on the following forum: http://www.codeisle.com/forum/product/liteips

Copyright
=========
LiteIPS Copyright (c) 2014 CodeIsle.com All Rights Reserved. LiteIPS is released under the CodeIsle.com Freeware EULA (see included file 'LICENSE.txt' for details).


