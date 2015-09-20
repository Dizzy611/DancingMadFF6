# Download Page

from PyQt5 import QtWidgets
from PyQt5.QtCore import pyqtSignal
import os
from downloader import Downloader
from decimal import Decimal

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
                          relist.append(_doSongMap(songSources[i], int(item))
                  else:
                      relist.append(_doSongMap(songSources[i], int(line))
                  i = i + 1
        print(retlist) # DEBUG
        return retlist



class downloadPage(QtWidgets.QWizardPage):
        def __init__(self):
              self.sidselection = [3]*21 + [0] + [3]*10 + [0] + [3]*5 + [0] + [3]*20 # Set to OCR selection for now, until sid selection is finalized.
              self.installstate = 1
              self.totalDownloads = 0
              self.checktimer = QTimer(self)
              self.checktimer.timeout.connect(self.timerEvent)
              self.checktimer.start(100)
              self.compChgSgnl = pyqtSignal()
              self.compChgSgnl.connect(self.completeChanged)
              self.compChgSgnl.emit()
              super().__init__()

        def timerEvent(self):
              if installstate == 1: # Initial state
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
                  else:
                      self.songSources = [0]*59 # Shouldn't get here, but ost as default anyway.
                  templist = mapSongs(self.songSources)
                  destination = "download"
                  urllist = ['http://www.somebodyelsesproblem.org/ff6data/{0}'.format(i) for i in templist]
                  self.totalDownloads = len(urllist)
                  urlqueue = Queue(maxsize=len(urllist))
                  for url in urllist:
                      urlqueue.put(url)
                  self.downloader = Downloader(urlqueue, destination)
                  installstate = 2
              elif installstate == 2:
                  if self.downloader.status == self.downloader.Downloading:
                      progress = Decimal(self.downloader.progress)
                      size = Decimal(self.downloader.size)
                      if size == 0:
                          percentage = 0
                          self.currentLabel.setText("Downloading (" + str(self.downloader.count() - self.totalDownloads) + "/" + str(self.totalDownloads) + ") ...")                  
                      else:
                          percentage = (progress / size) * 100
                          self.currentLabel.setText("Downloading (" + str(self.downloader.count() - self.totalDownloads) + "/" + str(self.totalDownloads) + ") (" + round(progress, 2) + "kb/" + round(size, 2) + "kb) ..."
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
                  elif self.downloader.status == self.downloader.Complete:
                      self.currentLabel.setText("Download Complete!")
                      self.currentBar.setValue(0)
                      installstate = 3
                  else:
                      pass
              elif installstate = 255:
                  self.compChgSgnl.emit()
              else:
                  pass

        def isComplete(self):
              if installstate = 255:
                  return True
              else:
                  return False

