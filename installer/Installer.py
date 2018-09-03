import os
import sys, types
from PyQt5.QtGui import QIcon
from PyQt5.QtWidgets import QWizard, QApplication, QWizardPage, QFileDialog
from PyQt5.QtCore import pyqtSlot, Qt, QUrl
from PyQt5.QtMultimedia import QMediaPlayer, QMediaContent
from installermodule import InstallWizard
from installermodule.selections import *
from enum import IntEnum
import urllib.request
import urllib.error
import socket

sys.stdout = open(os.path.expanduser("~/dancing-mad-installer.log"), "w")
sys.stderr = sys.stdout
scalefactor = 1.0

validmirrors = []

previewPlayer = QMediaPlayer()

class Pages(IntEnum):
    welcome = 0
    license = 1
    readme = 2
    destination = 3
    installtype = 4
    custom = 5
    opera = 6
    download = 7
    final = 8


def previewSong(songnum, source):
    print("Previewing song " + str(songnum)+ " from source " + source)
    try:
        previewPlayer.stop()
        content = QMediaContent(QUrl.fromLocalFile("Samples/" + str(songnum) + "-" + str(source) + ".mp3"))
        previewPlayer.setMedia(content)
        previewPlayer.play()
    except:
        print("WARN: Song preview not successful, unknown error (add to less-generic exception):", repr(sys.exc_info()[0]))


def mirrorCheck():
    print("DEBUG: Checking mirrors.")
    global validmirrors
    validmirrors = []
    try:
        with open("mirrors.dat") as f:
            mlist = f.readlines()
            mlist = [x.strip() for x in mlist]
    except IOError:
        return None
    for m in mlist:
        print("DEBUG: Checking",m)
        errorstr = ""
        try: # Check to make sure mirror is reachable before adding it to our list.
            if (("cloudfront" in m) or ("s3" in m)): # AWS works a little differently, so we need to grab an actual file, not a listing.
                retcode = urllib.request.urlopen(m + "contrib/twue.ips",timeout=4).getcode()
            else:
                retcode = urllib.request.urlopen(m,timeout=4).getcode() # 4 seconds may be too fast, but I'm trying to avoid needing to thread this call.
        except urllib.error.URLError as e:
            retcode = -1
            errorstr = e.reason
        if retcode == 200:
            domain = m.split("/")[2]
            try:
                socket.gethostbyname(domain)
            except:
                print("Unable to find host " + domain)
                pass
            else:
                print("Found host " + domain)
                validmirrors.append(m)
    print("DEBUG",repr(validmirrors))

class InstallWizard(QWizard, InstallWizard.Ui_InstallWizard):
        def __init__(self):
                super().__init__()

                self.setupUi(self)

                # Register fields. Has to be done here because these are all at QWizard scope due to the way the UIC works. Thankfully, due to the way fields work, 
                # these can then be referenced from within the individual page .py files as fields.
                self.licensePage.registerField("licenseAccepted*", self.licenseAccepted)
                self.destinationPage.registerField("romPath*", self.romPath)
                self.destinationPage.registerField("destPath*", self.destPath)
                self.installtypePage.registerField("sidselectButton", self.sidselectButton)
                self.installtypePage.registerField("ostButton", self.ostButton)
                self.installtypePage.registerField("fftButton", self.fftButton)
                self.installtypePage.registerField("sschafButton", self.sschafButton)
                self.installtypePage.registerField("ocrButton", self.ocrButton)
                self.installtypePage.registerField("customButton", self.customButton)
                self.installtypePage.registerField("higanButton", self.higanButton)
                self.installtypePage.registerField("BSNESButton", self.BSNESButton)
                self.installtypePage.registerField("SD2SNESButton", self.SD2SNESButton)
                self.installtypePage.registerField("ocraltButton", self.ocraltButton)
                self.installtypePage.registerField("ffarButton", self.ffarButton)
                self.installtypePage.registerField("crcButton", self.crcButton)
                self.installtypePage.registerField("mplayerCheck", self.mplayerCheck)
                self.installtypePage.registerField("twueCheck", self.twueCheck)
                self.installtypePage.registerField("cutsongCheck", self.cutsongCheck)
                self.customselectionPage.registerField("songList", self.trackSelectionWidget, "SongList")
                self.customselectionPage.registerField("loadPreset", self.loadPreset)
                self.customselectionPage.registerField("recommendedPreset", self.recommendedPreset)
                self.customselectionPage.registerField("ostPreset", self.ostPreset)
                self.customselectionPage.registerField("fftPreset", self.fftPreset)
                self.customselectionPage.registerField("sscPreset", self.sscPreset)
                self.customselectionPage.registerField("ocrPreset", self.ocrPreset)
                self.customselectionPage.registerField("ocraltPreset", self.ocraltPreset)
                self.operaPage.registerField("operaMfButton", self.operaMfButton)
                self.operaPage.registerField("operaTbmButton", self.operaTbmButton)
                self.operaPage.registerField("operaGmcButton", self.operaGmcButton)
                self.operaPage.registerField("operaDwButton", self.operaDwButton)
                self.operaPage.registerField("operaOstButton", self.operaOstButton)
                # Giving the Page objects access to their own widgets where necessary! Yay for the magic of python.
                self.readmePage.readmeBrowser = self.readmeBrowser
                self.licensePage.licenseBrowser = self.licenseBrowser
                self.finalPage.finalBrowser = self.finalBrowser
                self.customselectionPage.trackSelectionWidget = self.trackSelectionWidget
                self.destinationPage.ROMDetected = self.ROMDetected
                self.downloadPage.currentLabel = self.currentLabel
                self.downloadPage.currentBar = self.currentBar
                self.downloadPage.totalLabel = self.totalLabel
                self.downloadPage.totalBar = self.totalBar
                self.downloadPage.validmirrors = validmirrors
                # Giving the download page access to various widgets to redraw, enabling status updates within a function.
                self.downloadPage.widgetsToRedraw = []
                self.downloadPage.widgetsToRedraw.append(self.currentLabel)
                self.downloadPage.widgetsToRedraw.append(self.currentBar)
                self.downloadPage.widgetsToRedraw.append(self.gridLayoutWidget_3)
                self.downloadPage.widgetsToRedraw.append(self.downloadPage)
                self.downloadPage.widgetsToRedraw.append(self)
                
                # Deal with high DPIs by increasing the size of the window.
                self.resize(585*scalefactor, 527*scalefactor)
                    
        def nextId(self):
                # After the installtype page, only show the "custom track selection" page if the user has selected custom tracks. Otherwise, show the download/install page.
                # If we're not on the installtype page, just do the default behavior by calling our base class's nextId.
                if self.currentId() == Pages.installtype:
                    if self.field("customButton") == True:
                        return Pages.custom
                    else:
                        return Pages.download
                else:
                    return super().nextId()
                    
        @pyqtSlot()
        def on_romPathBrowse_clicked(self):
            filebrowse, filter = QFileDialog.getOpenFileName(self, "Select a ROM to patch.", ".", "SNES ROMs (*.sfc);;SNES ROMs (*.smc);;SNES ROMs (*.fig);;All Files (*.*)")
            self.romPath.setText(filebrowse)
            
        @pyqtSlot()
        def on_destPathBrowse_clicked(self):     
            self.destPath.setText(QFileDialog.getExistingDirectory())
        
        @pyqtSlot()
        def on_loadPreset_clicked(self):
            if self.field("ostPreset") == True:
                self.trackSelectionWidget.reloadSources(selectionToNumbers("ost"))
            elif self.field("fftPreset") == True:
                self.trackSelectionWidget.reloadSources(selectionToNumbers("fft"))
            elif self.field("sscPreset") == True:
                self.trackSelectionWidget.reloadSources(selectionToNumbers("ssc"))
            elif self.field("ocrPreset") == True:
                self.trackSelectionWidget.reloadSources(selectionToNumbers("ocr"))
            elif self.field("ocraltPreset") == True:
                self.trackSelectionWidget.reloadSources(selectionToNumbers("ocr2"))
            elif self.field("recommendedPreset") == True:
                self.trackSelectionWidget.reloadSources(selectionToNumbers("sid"))

        @pyqtSlot()
        def on_operaGmcPreview_clicked(self):
            previewSong(31, "gmc")
        
        @pyqtSlot()
        def on_operaDwPreview_clicked(self):
            previewSong(31, "dw")
        
        @pyqtSlot()
        def on_operaMfPreview_clicked(self):
            previewSong(31, "mf")
        
        @pyqtSlot()
        def on_operaTbmPreview_clicked(self):
            previewSong(31, "tbm")
            
        @pyqtSlot()
        def on_operaOstPreview_clicked(self):
            previewSong(31, "ost")

#messagebox.showinfo("Checking mirrors...","The installer will now take a few seconds to check and see which of the mirrors for the .PCM files is currently up and functioning. Please press OK and be patient. The installer window will show up when this check is complete.")
mirrorCheck()

app = QApplication(sys.argv)
scalefactor = app.screens()[0].logicalDotsPerInch() / 96.0
if scalefactor > 1:
    print("DEBUG: Detected high DPI display. Scaling to %.4fx" % scalefactor)
window = InstallWizard()
window.show()
app.exec_()
