# Dancing Mad FF6 MSU-1 Music Replacer #

Welcome to the repository for Dancing Mad. Please submit any issues using the Issues tab on the left. 

### Summary ###

* Dancing Mad is an FF6 rom hack or mod using the MSU-1 to replace the built-in music with CD quality streaming music from a number of sources.
* Dancing Mad contains an easy installer to allow you to download the music you want, patch your ROM, and be ready to go.
* Dancing Mad is currently in open beta. The open beta version is available under Downloads, and is also in the "beta" branch. My current work in progress version is in the "master" branch. I will not be providing installers for the "master" branch, though I may eventually provide an updater. If a new IPS file is released in the master branch, you should apply to your unmodified original FF3 ROM yourself with your IPS patcher of choice.

### Setup ###

* To set up Dancing Mad, run the installer and follow the instructions contained therein. Please use a ROM of FF3 US v1.0.

* If you wish to test the "master" branch, patch an unheadered, untouched ROM of FF3 US v1.0 with the IPS contained in the patch directory of that branch. Do not patch over a previously patched version of Dancing Mad as if the IPS patch grows or shrinks you could end up with undefined results. If there is demand, I may provide an incremental IPS patch which is diffed against the current beta.

* If you wish to assemble the current experimental or master patches yourself, you need copies of GNU Make, wla-dx and flips IPS patcher. The latter two are provided in the utils directory. Check the Makefile and make sure the paths for your assembler and copy of flips are correct (the first set are for windows, the second are for other platforms). Then stick your FF3 rom, renamed ff3.sfc, in the same directory as the Makefile and the ASM and link files, and run GNU Make. You should get as output ff3msu.sfc (the patched ROM) and ff3msu.ips (the new IPS patch.) This is my exact workflow, so if you are doing your own changes to the ASM please follow the same workflow to prevent errors.

* If you wish to use the installer on Linux or a Mac you will need to extract the tar.xz version of the installer and run it on a system that has Python 3.4, PyQt5, PyCurl, and python-ips installed. There may be other dependencies I've forgotten. PyCurl and python-ips can be install via `pip install python-ips` or `pip install pycurl`. PyQt5 should be installed via a package manager or from the instructions on its website.

### Contribution guidelines ###

* I have given specific people (testers from the closed alpha and such) write access, but please do *not* commit your own changes to the repository's master or experimental branches. If you wish to create your own changes, please create your own branch against whatever you're using as your base code.

* Please submit bugs using the Issues tracker. Please state clearly whether you're using the closed alpha I provided you, the experimental branch, or your own code. 


* If you are using your own code and have not made a branch for it, please submit either a relevant code snippet or the ASM file in your issue submission.



### Contact ###

* Contact insidious@gmail.com via email for help, or if you want a more live conversation approach me on the #qhimm.com IRC on irc.esper.net. I much prefer IRC to any other line of communication for this project. If necessary I also have a Skype, Insidious615.



### A final note ###

* Due to personal issues outside my control, I may take unscheduled hiatuses from this project for months at a time. Please continue to report issues during this time.