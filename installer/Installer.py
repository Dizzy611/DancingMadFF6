import sys, types
from PyQt5.QtWidgets import QWizard, QApplication, QWizardPage, QFileDialog
from PyQt5.QtCore import pyqtSlot
from installermodule import InstallWizard
from enum import IntEnum
sys.stdout = open("installer.log", "w")
sys.stderr = sys.stdout

class Pages(IntEnum):
    welcome = 0
    license = 1
    readme = 2
    destination = 3
    installtype = 4
    custom = 5
    download = 6
    final = 7

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
                self.customselectionPage.registerField("songList", self.trackSelectionWidget, "SongList")


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
                
        def nextId(self):
                # After the installtype page, only show the "custom track selection" page if the user has selected custom tracks. Otherwise, show the download/install page.
                # If we're not on the installtype page, just do the default behavior by calling our base class's nextId.
                if self.currentId() == Pages.installtype:
                    if self.field("customButton") == True:
                        return Pages.custom
                    else:
                        return Pages.download
                else:
                    return super().nextId();
                    
        @pyqtSlot()
        def on_romPathBrowse_clicked(self):
            filebrowse, filter = QFileDialog.getOpenFileName(self, "Select a ROM to patch.", ".", "SNES ROMs (*.sfc);;SNES ROMs (*.smc);;SNES ROMs (*.fig);;All Files (*.*)")
            self.romPath.setText(filebrowse)
            
        @pyqtSlot()
        def on_destPathBrowse_clicked(self):     
            self.destPath.setText(QFileDialog.getExistingDirectory())

app = QApplication(sys.argv)
window = InstallWizard()
window.show()
app.exec_()
