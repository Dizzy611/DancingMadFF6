# Final Page
import os
from PyQt5 import QtWidgets,QtCore

class finalPage(QtWidgets.QWizardPage):
        def __init__(self):
              super().__init__()

        def initializePage(self):
             if self.field("SD2SNESButton") == True:
                    htmlfile = "sd2snes-final.html"
             elif self.field("higanButton") == True:
                    htmlfile = "higan-final.html"
             else:
                    htmlfile = "bsnes-final.html"
             if os.path.isfile(htmlfile):
                    finalurl = QtCore.QUrl.fromLocalFile(htmlfile)
                    self.finalBrowser.setSource(finalurl)
                    
