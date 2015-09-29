# Download Page
import shutil
from PyQt5 import QtWidgets
from PyQt5.QtCore import pyqtSignal, QTimer
import os
from installermodule.downloader import Downloader
from installermodule import rom
from decimal import Decimal
from queue import Queue
import ips
import sys

def _doSongMap(source, tracknum):
        sourcestr = ""
        if source == 0:
              sourcestr = "OST"
        elif source == 1:
              sourcestr = "FFT"
        elif source == 2:
              sourcestr = "SSC"
        elif source == 3:
              sourcestr = "OCR"
        elif source == 4:
              sourcestr = "OTH"
        elif source == 5:
              return ""
        else:
              sourcestr = "OST"
        retstr = sourcestr + "/ff3-" + str(tracknum) + ".pcm"
        return retstr

           
def mapSongs(songSources):
        retlist = list()
        i = 0
        with open("trackMapping.dat") as f:
              for line in f:
                  if line.count(",") != 0:
                      for item in line.split(","):
                        file = _doSongMap(songSources[i], int(item))
                        if file != "":
                            retlist.append(file)
                  else:
                      file = _doSongMap(songSources[i], int(line))
                      if file != "":
                          retlist.append(file)
                  i = i + 1
        return retlist



class downloadPage(QtWidgets.QWizardPage):
        compChgSgnl = pyqtSignal()
        installstate = 0
        def __init__(self):
              self.sidselection = [2]*2 + [1]*2 + [2]*6 + [3] + [1] + [2] + [1] + [3] + [2]*7 + [3]*6 + [0] + [3]*2 + [4]*2 + [0]*3 + [3]*2 + [0] + [3] + [0] + [3]*7 + [0]*3 + [3]*8 # Make an XML file for this and parse it, eventually, so we don't have this ugly thing.
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
              if self.installstate == 1:   # Initializing...
                  self.currentLabel.setText("Initializing downloader...")
                  if self.field("customButton") == True:
                      self.songSources = self.field("songList")
                  elif self.field("sidselectButton") == True:
                      self.songSources = self.sidselection
                  elif self.field("ostButton") == True:
                      self.songSources = [0]*59 # All OST
                  elif self.field("fftButton") == True:
                      self.songSources = [1]*16 + [0]*43 # 16 FFT tracks and 43 OST tracks
                  elif self.field("sschafButton") == True:
                      self.songSources = [2]*25 + [0]*34 # 25 SSC tracks and 34 OST tracks
                  elif self.field("ocrButton") == True:
                      self.songSources = [3]*21 + [0] + [3]*10 + [0] + [3]*5 + [0] + [3]*20 # 56 OCR tracks, with 3 OST tracks in various missing spots.
                      self.songSources[31] = [4] # Replace OCR opera/finale with OTH 
                      self.songSources[32] = [4]
                  else:
                      self.songSources = [0]*59 # Shouldn't get here, but ost as default anyway.
                  
                  # Opera track magic! To be revised later.
                  if self.songSources[31] != 4: 
                      self.songSources[31] = 5 # Dummy out the Opera tracks for now for non OTH versions.
                     
                  templist = mapSongs(self.songSources)
                  destination = self.field("destPath")
                  urllist = ['http://www.somebodyelsesproblem.org/ff6data/{0}'.format(i) for i in templist]
                  self.totalDownloads = len(urllist)
                  urlqueue = Queue(maxsize=len(urllist))
                  for url in urllist:
                      urlqueue.put(url)
                  self.downloader = Downloader(urlqueue, destination)
                  self.installstate = 2
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
                        self.currentBar.setText("Patching: No SMC header found.")
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
                    self.currentLabel.setText("Patching: ROM Patching Failed! Error:" + e)
                    self.installstate = 254
              elif self.installstate == 4:   # Final copying/renaming/etc.
                  self.currentLabel.setText("Finalizing: Copying Manifests...")
                  self.currentBar.setValue(0)
                  if self.field("higanButton") == True:
                      shutil.copy2("manifest.bml", self.field("destPath"))
                      shutil.copy2("ff3msu.msu", self.field("destPath"))
                  elif self.field("SD2SNESButton") == True:
                      shutil.copy2("ff3msu.msu", os.path.join(self.field("destPath"), "ff3.msu"))
                      os.rename(os.path.join(self.field("destPath"), "ff3msu.sfc"), os.path.join(self.field("destPath"), "ff3.sfc"))
                  elif self.field("BSNESButton") == True:
                      shutil.copy2("ff3msu.msu", os.path.join(self.field("destPath"), "ff3.msu"))
                      shutil.copy2("ff3msu.xml", os.path.join(self.field("destPath"), "ff3.xml"))
                      os.rename(os.path.join(self.field("destPath"), "ff3msu.sfc"), os.path.join(self.field("destPath"), "ff3.sfc"))
                  else:
                      pass
                  self.currentBar.setValue(50)
                  self.currentLabel.setText("Finalizing: Copying MSU file.")
                  
                  self.currentBar.setValue(100)
                  self.currentLabel.setText("Done!")
                  self.totalBar.setValue(100)
                  self.installstate = 255
              elif self.installstate == 254: # Error
                  pass
              elif self.installstate == 255: # Complete
                  self.compChgSgnl.emit()
              else:
                  pass

        def isComplete(self):
              if self.installstate == 255:
                  return True
              else:
                  return False

