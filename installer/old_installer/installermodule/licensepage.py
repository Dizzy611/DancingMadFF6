# License Page
import os.path
from PyQt5 import QtCore
from PyQt5 import QtWidgets

class licensePage(QtWidgets.QWizardPage):
        def __init__(self):
                super().__init__()

        def initializePage(self):
             if os.path.isfile("license.html"):
                    licenseurl = QtCore.QUrl.fromLocalFile("license.html")
                    self.licenseBrowser.setSource(licenseurl)
