# Download Page
import shutil
from PyQt5 import QtWidgets
from PyQt5.QtCore import pyqtSignal, QTimer
from PyQt5.QtMultimedia import QSound
import os, errno
from installermodule.downloader import Downloader
from installermodule import rom
from installermodule.selections import *
from installermodule import song 
from decimal import Decimal
from queue import Queue
import ips
import sys
import glob

mysonglist = song.parseSongXML("songs.xml")

# Should we use the /new directory in the mirrors. Use when testing new song selections, turn off on release.
NEW_PATH = False

def _doMirrors(pcmlist):
    try:
        with open("mirrors.dat") as f:
            mirrors = f.readlines()
            mirrors = [x.strip() for x in mirrors]
    except IOError:
        return None
    mirrorlist = []
    for m in mirrors:
        mirrorlist.append([m + i for i in pcmlist])
    args = tuple(mirrorlist)
    return list(zip(*args))
    
def _doSongMap(source, tracknum):
        if NEW_PATH == False:
            sourcestr = ""
        else:
            sourcestr = "new/"
        if mysonglist.sources[source] != "spc":
            sourcestr = sourcestr + mysonglist.sources[source].upper()
        else:
            return ""
        retstr = sourcestr + "/ff3-" + str(tracknum) + ".pcm"
        return retstr


def mapSongs(songSources):
        retlist = []
        for idx,source in enumerate(songSources):
            for pcm in mysonglist.songs[idx].pcms:
                file = _doSongMap(source, pcm)
                if file != "":
                    retlist.append(file)
        return retlist



class downloadPage(QtWidgets.QWizardPage):
        compChgSgnl = pyqtSignal()
        installstate = 0
        def __init__(self):
              if not (len(sys.argv) >= 2 and sys.argv[1] == "-nosound"):
                try:
                  self.laughFile = QSound("kefkalaugh.wav")
                  self.soundOn = True
                  self.soundPlayed = False
                  print("Kefka laugh enabled")
                except:
                  self.laughFile = None
                  self.soundOn = False
                  self.soundPlayed = False
                  print("Kefka laugh disabled (exception)")
              else:
                self.laughFile = None
                self.soundOn = False
                self.soundPlayed = False
                print("Kefka laugh disabled (commandline)")
              self.installstate = 1
              self.totalDownloads = 0
              super().__init__()
              self.checktimer = QTimer(self)
              self.checktimer.timeout.connect(self.timerEvent)
              self.compChgSgnl.connect(self.completeChanged)
              self.compChgSgnl.emit()

        def initializePage(self):
              self.checktimer.start(100)

        def timerEvent(self):
              sys.stdout.flush() # Periodically flush log to disk.
              if self.installstate == 1:   # Initializing...
                  self.currentLabel.setText("Initializing downloader...")
                  if self.field("customButton") == True:
                      self.songSources = self.field("songList")
                  elif self.field("sidselectButton") == True:
                      self.songSources = selectionToNumbers("sid")
                  elif self.field("ostButton") == True:
                      self.songSources = selectionToNumbers("ost")
                  elif self.field("fftButton") == True:
                      self.songSources = selectionToNumbers("fft")
                  elif self.field("sschafButton") == True:
                      self.songSources = selectionToNumbers("ssc")
                  elif self.field("ocrButton") == True:
                      self.songSources = selectionToNumbers("ocr")
                  elif self.field("ocraltButton") == True:
                      self.songSources = selectionToNumbers("ocr2")
                  else:
                      self.songSources = selectionToNumbers("ost") # Shouldn't get here, but ost as default anyway.

                  # if self.songSources[31] == 0: # OST opera is now available. Commented this bit out. 
                      # self.songSources[31] = 6
                  if self.songSources[59] == mysonglist.sources.index("ost"): # No OST versions of sound effects.
                      self.songSources[59] = mysonglist.sources.index("spc")
                  
                  templist = mapSongs(self.songSources)
                  comblist = _doMirrors(templist)
                  destination = self.field("destPath")
                  self.totalDownloads = len(comblist)
                  urlqueue = Queue(maxsize=self.totalDownloads)
                  for urlpair in comblist:
                      urlqueue.put(urlpair)  
                  self.downloader = Downloader(urlqueue, destination)
                  if self.totalDownloads != 0:
                    self.installstate = 2
                  else:
                    self.installstate = 3
              elif self.installstate == 2:   # Downloading PCMs
                  if self.totalDownloads-self.downloader.count() > 0:
                    totalPercentage = ((self.totalDownloads-self.downloader.count()-1) / (self.totalDownloads+2)) * 100
                  else:
                    totalPercentage = 0
                  self.totalBar.setValue(totalPercentage)
                  if self.downloader.status == self.downloader.Downloading:
                      progress = Decimal(self.downloader.progress)
                      size = Decimal(self.downloader.size)
                      if size == 0:
                          percentage = 0
                          labelStr = "Downloading ({0}/{1}) 0% ...".format(self.totalDownloads-self.downloader.count(),self.totalDownloads)
                      else:
                          percentage = (progress / size) * 100
                          labelStr = "Downloading ({0}/{1}) ({2}/{3} kB) {4}% ...".format(self.totalDownloads-self.downloader.count(),self.totalDownloads,round(progress/1024,2),round(size/1024,2),round(percentage,2))
                      self.currentLabel.setText(labelStr)
                      self.currentBar.setValue(percentage)
                  elif self.downloader.status == self.downloader.Waiting:
                      self.currentLabel.setText("Connecting...")
                      self.currentBar.setValue(0)
                      self.downloader.start()
                  elif self.downloader.status == self.downloader.Initializing:
                      self.currentLabel.setText("Connecting...")
                      self.currentBar.setValue(0)
                      self.downloader.start()
                  elif self.downloader.status == self.downloader.Error:
                      self.currentLabel.setText("Error: " + self.downloader.errormessage)
                      self.currentBar.setValue(0)
                      self.installstate = 254
                  elif self.downloader.status == self.downloader.Complete:
                      self.currentLabel.setText("Download Complete!")
                      self.currentBar.setValue(0)
                      self.installstate = 3
                  else:
                      pass
              elif self.installstate == 3:   # Patching ROM
                  self.currentLabel.setText("Download finished. Patching ROM...")
                  self.currentBar.setValue(0)
                  totalPercentage = (self.totalDownloads / (self.totalDownloads + 2)) * 100
                  self.totalBar.setValue(totalPercentage)
                  try:
                    os.remove(os.path.join(self.field("destPath").replace("/","\\"), "ff3msu.sfc")) # Avoid a crash later on by removing any sfcs already present in the destination directory.
                    
                  except OSError as e:
                    if e.errno != errno.ENOENT:
                        raise
                  try:
                    os.remove(os.path.join(self.field("destPath").replace("/","\\"), "ff3.sfc")) # Ditto to above.
                  except OSError as e:
                    if e.errno != errno.ENOENT:
                        raise
                  patchPath = os.path.join(self.field("destPath"), "ff3msu.ips")
                  destromPath = os.path.join(self.field("destPath"), "ff3msu.sfc")
                  try:
                    self.currentLabel.setText("Patching: Copying ROM to destination path...")
                    shutil.copy2(self.field("romPath"), destromPath)
                    self.currentBar.setValue(25)
                    self.currentLabel.setText("Patching: Copying Patch to destination path...")
                    shutil.copy2("ff3msu.ips", self.field("destPath"))
                    self.currentBar.setValue(50)
                    self.currentLabel.setText("Patching: Checking for SMC header...")
                    myrom = rom.SNESRom(self.field("romPath"))
                    myrom.parse()
                    if myrom.has_smc_header:
                        unheaderedPath = os.path.join(self.field("destPath"), "temp.sfc")
                        self.currentBar.setText("Patching: Found SMC header, removing...")
                        newfile = open(unheaderedPath, "wb")
                        romfile = open(destromPath, "rb")
                        _ = romfile.read(512) # Skip the header
                        newfile.write(romfile.read()) # Write everything else to the new file
                        newfile.close()
                        romfile.close()
                        os.remove(destromPath)
                        os.rename(unheaderedPath, destromPath)
                        self.currentBar.setText("Patching: Header removed.")
                    else:
                        self.currentLabel.setText("Patching: No SMC header found.")
                    self.currentBar.setValue(75)
                    self.currentLabel.setText("Patching: Applying patch...")
                    # TODO: Apply different patch with SD2SNES volume values if we're installing for SD2SNES
                    ips.apply(patchPath, destromPath)
                    os.remove(patchPath)
                    self.currentLabel.setText("Patching: Patch successful!")
                    self.currentBar.setValue(100)
                    totalPercentage = (self.totalDownloads+1 / (self.totalDownloads + 2)) * 100
                    self.totalBar.setValue(totalPercentage)
                    self.installstate = 4
                  except:
                    e = sys.exc_info()[0]
                    self.currentLabel.setText("Patching: ROM Patching Failed! Error:" + str(e))
                    self.installstate = 254
              elif self.installstate == 4:   # Final copying/renaming/etc.
                  self.currentLabel.setText("Finalizing: Copying Manifests and MSU file...")
                  self.currentBar.setValue(0)
                  if self.field("higanButton") == True:
                      shutil.copy2("ff3msu.msu", self.field("destPath"))
                      tmpRomSrc = os.path.join(self.field("destPath"), "ff3msu.sfc")
                      tmpRomDst = os.path.join(self.field("destPath"), "program.rom")
                      tmpMsuSrc = os.path.join(self.field("destPath"), "ff3msu.msu")
                      tmpMsuDst = os.path.join(self.field("destPath"), "msu1.rom")
                      shutil.move(tmpRomSrc, tmpRomDst)
                      shutil.move(tmpMsuSrc, tmpMsuDst)
                      self.currentBar.setValue(50)
                      self.currentLabel.setText("Finalizing: Higanifying track names...")
                      tmpOldCwd = os.getcwd()
                      os.chdir(self.field("destPath"))
                      pcmsList = glob.glob('ff3-*.pcm')
                      for thisfile in pcmsList:
                          newfilename = thisfile.replace("ff3", "track")
                          os.rename(thisfile, newfilename)
                      os.chdir(tmpOldCwd)
                  elif self.field("SD2SNESButton") == True:
                      shutil.copy2("ff3msu.msu", os.path.join(self.field("destPath"), "ff3.msu"))
                      if os.path.exists(os.path.join(self.field("destPath"), "ff3.sfc")):
                        os.remove(os.path.join(self.field("destPath"), "ff3.sfc"))
                      os.rename(os.path.join(self.field("destPath"), "ff3msu.sfc"), os.path.join(self.field("destPath"), "ff3.sfc"))
                  elif self.field("BSNESButton") == True:
                      shutil.copy2("ff3msu.msu", os.path.join(self.field("destPath"), "ff3.msu"))
                      shutil.copy2("ff3msu.xml", os.path.join(self.field("destPath"), "ff3.xml"))
                      if os.path.exists(os.path.join(self.field("destPath"), "ff3.sfc")):
                        os.remove(os.path.join(self.field("destPath"), "ff3.sfc"))
                      os.rename(os.path.join(self.field("destPath"), "ff3msu.sfc"), os.path.join(self.field("destPath"), "ff3.sfc"))
                  else:
                      pass
                  self.currentBar.setValue(100)
                  self.currentLabel.setText("Done!")
                  self.totalBar.setValue(100)
                  self.installstate = 255
              elif self.installstate == 254: # Error
                  pass
              elif self.installstate == 255: # Complete
                  if self.soundOn:
                    if self.soundPlayed == False:
                        try:
                            self.laughFile.play()
                        except:
                            print("Failed to play kefka laugh")
                        else:
                            print("Played kefka laugh")
                        self.soundPlayed = True
                  self.compChgSgnl.emit()
              else:
                  pass

        def isComplete(self):
              if self.installstate == 255:
                  return True
              else:
                  return False

