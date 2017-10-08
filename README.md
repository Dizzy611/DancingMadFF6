# Dancing Mad FF6 MSU-1 Music Replacer #

Welcome to the repository for Dancing Mad. Please submit any issues using the Issues tab on the left. 

### Summary ###

* Dancing Mad is an FF6 rom hack or mod using the MSU-1 to replace the built-in music with CD quality streaming music from a number of sources.
* Dancing Mad contains an easy installer to allow you to download the music you want, patch your ROM, and be ready to go.
* Dancing Mad is currently in open beta. The open beta version is available under Downloads. My current work in progress version is in the "master" branch, with more experimental code in their own branches. I will not be providing installers for active branches until the code has reached a stable point, though I may eventually provide an updater to update to new IPS versions without a reinstall. If a new IPS file is released in the master branch and you wish to test it, you should apply to your unmodified original FF3 ROM yourself with your IPS patcher of choice.

### Setup ###

* To set up Dancing Mad, run the installer and follow the instructions contained therein. Please use a ROM of FF3 US v1.0.

* If you wish to test the "master" branch, patch an unheadered, untouched ROM of FF3 US v1.0 with the IPS contained in the patch directory of that branch. Do not patch over a previously patched version of Dancing Mad as if the IPS patch grows or shrinks you could end up with undefined results. If there is demand, I may provide an incremental IPS patch which is diffed against the current beta.

* If you wish to assemble patches yourself, you need copies of GNU Make, wla-dx and flips IPS patcher. Check the Makefile and make sure the paths for your assembler and copy of flips are correct (the first set are for windows, the second are for other platforms). Then stick your FF3 rom, renamed ff3.sfc, in the same directory as the Makefile and the ASM and link files, and run GNU Make. You should get as output ff3msu.sfc (the patched ROM) and ff3msu.ips (the new IPS patch.) This is my exact workflow, so if you are doing your own changes to the ASM please follow the same workflow to prevent errors.

* If you wish to use the installer on Linux or a Mac you will need to extract the tar.xz version of the installer and run it on a system that has Python 3.4 or newer, PyQt5, PyCurl, and python-ips installed. There may be other dependencies I've forgotten. PyCurl and python-ips can be install via `pip install python-ips` or `pip install pycurl`. PyQt5 should be installed via a package manager or from the instructions on its website, though with recent releases of pyqt5 `pip install PyQt5` will also work. 

### Contribution guidelines ###

* Feel free to fork and submit pull requests. This is the preferred method of submitting fixes to the code/contributions. 

* Please submit bugs using the Issues tracker. Please state clearly whether you're using the beta provided, my code that hasn't been released as a new beta, or your own code. 



### Contact ###

* Contact dylanjmorrison611@gmail.com via email or [this forum thread](http://forums.qhimm.com/index.php?topic=16077) for help, or if you want a more live conversation approach me on the project's official Discord using this [invite](https://discord.gg/ynZkNnK). I don't use IRC or Skype much anymore. 



### A final note ###

* Due to personal issues outside my control, I may take unscheduled hiatuses from this project for months at a time. Please continue to report issues during this time.
