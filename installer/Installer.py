import os
import sys, types
from PyQt5.QtGui import QIcon
from PyQt5.QtWidgets import QWizard, QApplication, QWizardPage, QFileDialog
from PyQt5.QtCore import pyqtSlot, Qt
from installermodule import InstallWizard
from installermodule.selections import *
from enum import IntEnum


sys.stdout = open(os.path.expanduser("~/dancing-mad-installer.log"), "w")
sys.stderr = sys.stdout

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
    print("TODO: Actually play preview.")


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
                # Giving the download page access to various widgets to redraw, enabling status updates within a function.
                self.downloadPage.widgetsToRedraw = []
                self.downloadPage.widgetsToRedraw.append(self.currentLabel)
                self.downloadPage.widgetsToRedraw.append(self.currentBar)
                self.downloadPage.widgetsToRedraw.append(self.gridLayoutWidget_3)
                self.downloadPage.widgetsToRedraw.append(self.downloadPage)
                self.downloadPage.widgetsToRedraw.append(self)
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

app = QApplication(sys.argv)
app.setAttribute(Qt.AA_DisableHighDpiScaling, True)

window = InstallWizard()
window.show()
app.exec_()
