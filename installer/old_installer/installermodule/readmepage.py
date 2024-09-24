# Readme Page
from PyQt5 import QtCore
from PyQt5 import QtWidgets
import os.path

class readmePage(QtWidgets.QWizardPage):
        def __init__(self):
              super().__init__()
	
        def initializePage(self):
              if os.path.isfile("readme.html"):
                    readmeurl = QtCore.QUrl.fromLocalFile("readme.html")
                    self.readmeBrowser.setSource(readmeurl)

