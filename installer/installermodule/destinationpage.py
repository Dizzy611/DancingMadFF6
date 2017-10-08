# Destination Page

from PyQt5 import QtWidgets
import os
from installermodule import rom

FF3_US_V1_CHECKSUM = 24370
DM_CURR_CHECKSUM = 12763

class destinationPage(QtWidgets.QWizardPage):
        lastRomPath = ""
        romValid = False
        def __init__(self):
                super().__init__()

                
        def isComplete(self):
                romlabel = "Detected ROM Version:"
                greenLights = 0
                # Very basic path validation, along with ROM type validation.
                if self.field("romPath") == "":
                   return False
                elif os.path.exists(self.field("romPath")):
                   if (self.lastRomPath == self.field("romPath")) and (self.romValid == True): 
                      greenLights = 5
                   else:
                       self.lastRomPath = self.field("romPath")
                       self.romValid = False
                       try: 
                          myrom = rom.SNESRom(self.field("romPath"))
                          myrom.parse()
                       except rom.InvalidRomFileException:
                          self.ROMDetected.setText("Detected ROM Version: Invalid SNES ROM Detected.")
                          return False
                       computedchecksum = rom.compute_snes_checksum(self.field("romPath"))
                       if myrom.title.decode("ASCII") == "Final Fantasy 3":
                          print("DEBUG: ROM title correct.")
                          greenLights = greenLights + 1
                       if myrom.destcode == 1:
                          print("DEBUG: ROM region correct.")
                          greenLights = greenLights + 1
                       if myrom.version == 0:
                          print("DEBUG: ROM version correct.")
                          greenLights = greenLights + 1
                       if myrom.checksum == FF3_US_V1_CHECKSUM:
                          print("DEBUG: ROM reported checksum correct.")
                          greenLights = greenLights + 1
                       if computedchecksum == FF3_US_V1_CHECKSUM:
                          print("DEBUG: ROM actual checksum correct.")
                          greenLights = greenLights + 1
                       else:
                          print("DEBUG: ROM checksum mismatch. Found " + str(computedchecksum) + " wanted " + str(FF3_US_V1_CHECKSUM))
                       romlabel += " " + myrom.title.decode("ASCII") + " (" + rom.decode_destcode(myrom.destcode) + ") (V1." + str(myrom.version) + ") "
                       if myrom.checksum == computedchecksum:
                          romlabel += "(Sum: OK) "
                       else:
                          romlabel += "(Sum: Fail) "
                       if computedchecksum == DM_CURR_CHECKSUM:
                          romlabel += "(OK?: NO! Already Patched)"
                          self.romValid = False
                       elif greenLights == 5:
                          romlabel += "(OK?: Yes!)"
                          self.romValid = True
                       else:
                          romlabel += "(OK?: No :( )"
                          self.romValid = False
                       if myrom.has_smc_header == True:
                          romlabel += " (Header: Yes)"
                       else:
                          romlabel += " (Header: No)"
                       self.ROMDetected.setText(romlabel)
                if self.field("destPath") == "":
                   return False
                if not os.path.exists(self.field("destPath")):
                   return False                
                return greenLights == 5