# Dancing Mad FF6 MSU-1 Music Replacer #

Welcome to the repository for Dancing Mad. Please submit any issues using the Issues tab on the left. 

### Summary ###

* Dancing Mad is an FF6 rom hack or mod using the MSU-1 to replace the built-in music with CD quality streaming music from a number of sources.
* Dancing Mad contains an easy installer to allow you to download the music you want, patch your ROM, and be ready to go.
* Dancing Mad is currently in open beta. The open beta version is available under Downloads. My current work in progress version is in the "master" branch, with more experimental code in their own branches. I will not be providing installers for active branches until the code has reached a stable point, though I may eventually provide an updater to update to new IPS versions without a reinstall. If a new IPS file is released in the master branch and you wish to test it, you should apply to your unmodified original FF3 ROM yourself with your IPS patcher of choice.

### Setup ###

* To set up Dancing Mad, run the installer and follow the instructions contained therein. Please use **any** ROM of FF6, provided the audio code has not been altered by a previous patch. Previously, I advised only patch **US V1.0**, but further investigation has shown that **Japanese** copies of the game should be 100% compatible. Please report any bugs you encounter running this with previously unsupported versions of the game! **US V1.1** was originally listed as being 100% compatible with the new version but has a few unexpected issues we are working through.

* If you wish to test the "master" branch, patch an unheadered, untouched ROM of FF6 with the IPS contained in the patch directory of that branch. Do not patch over a previously patched version of Dancing Mad as if the IPS patch grows or shrinks you could end up with undefined results. If there is demand, I may provide an incremental IPS patch which is diffed against the current beta.

* If you wish to assemble patches yourself, you need copies of GNU Make, wla-dx and flips IPS patcher. Check the Makefile and make sure the paths for your assembler and copy of flips are correct (the first set are for windows, the second are for other platforms). Then stick your FF3 rom, renamed ff3.sfc, in the same directory as the Makefile and the ASM and link files, and run GNU Make. You should get as output ff3msu.sfc (the patched ROM) and ff3msu.ips (the new IPS patch.) This is my exact workflow, so if you are doing your own changes to the ASM please follow the same workflow to prevent errors.

* If you wish to use the installer on Linux or a Mac you will need to extract the tar.xz version of the installer and run it (via `python Installer.py` or `python3 Installer.py` on some systems) on a system that has Python 3.4 or newer, PyQt5, PyCurl, certifi, and python-ips installed. These can be installed all at once with `pip3 install pycurl python-ips pyqt5 certifi`.

### Contribution guidelines ###

* Feel free to fork and submit pull requests. This is the preferred method of submitting fixes to the code/contributions. 

* Please submit bugs using the Issues tracker. Please state clearly whether you're using the beta provided, my code that hasn't been released as a new beta, or your own code. 



### Contact ###

* Contact dylanjmorrison611@gmail.com via email or [this forum thread](http://forums.qhimm.com/index.php?topic=16077) for help, or if you want a more live conversation approach me on the project's official Discord using this [invite](https://discord.gg/ynZkNnK). I don't use IRC or Skype much anymore. 

### Credits ###
## Musical Credits ##
* Nobuo Uematsu
* Sean Schafiaski (buy the album [here](http://https://seanschafianski.bandcamp.com/album/remastered-soundtrack-final-fantasy-vi- disc-1), support the artist who has kindly allowed us to use his work!)
* OCRemix Contributors
* FinalFanTim
* ChrystalChameleon
* The Black Mages
* Tokyo Symphony Orchestra
* The World Festival Symphony Orchestra
* The Royal Stockholm Philharmonic Orchestra
* Eiko Nichols
* edale2

## Editing Credits ##
* Covarr
* edale2
* qwertymodo

## Patch Credits (both for Dancing Mad itself and for optional patches bundled) ##
* Myself (Dylan Morrison)
* madsiur
* qwertymodo
* Rodimus Primal & the Ted Woolsey Uncensored Patch team
* mziab

## Installer Credits ##
* Myself

## Testing Credits ##
* Covarr
* Retro Dan
* ikari
* edale2
* Too many public beta testers to name. Thank you very much!

## Community Outreach Credits ##
* edale2

## Special Thanks ##
* Square Enix
* ikari
* Madsiur
* qwertymodo
* byuu
* Kawa
* DLPB
* Qhimm.com
* romhacking.net
* BitBucket
* GitHub
* My friends, family, and loved ones.
* Many others I have forgotten to name.
* You.

### A final note ###

* Due to personal issues outside my control, I may take unscheduled hiatuses from this project for months at a time. Please continue to report issues during this time.
