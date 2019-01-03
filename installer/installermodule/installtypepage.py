# Install Type Page

from installermodule import rom
from PyQt5 import QtWidgets

us10checksum = 24370

class installtypePage(QtWidgets.QWizardPage):
        def __init__(self):
              super().__init__()
              self.setCommitPage(True)
        def initializePage(self):
              myrom = rom.SNESRom(self.field("romPath"))
              myrom.parse()
              if myrom.checksum == us10checksum:
                  print("DEBUG: Found USV1.0 ROM.")
                  self.twueCheck.setEnabled(True)
                  self.twueCheck.setToolTip("")
                  self.mplayerCheck.setEnabled(True)
                  self.mplayerCheck.setToolTip("")
                  self.cutsongCheck.setEnabled(True)
                  self.cutsongCheck.setToolTip("")
              else:
                  self.twueCheck.setEnabled(False)
                  self.twueCheck.setToolTip("Disabled due to non US1.0 ROM")
                  self.mplayerCheck.setEnabled(False)
                  self.mplayerCheck.setToolTip("Disabled due to non US1.0 ROM")
                  self.cutsongCheck.setEnabled(False)
                  self.cutsongCheck.setToolTip("Disabled due to non US1.0 ROM")