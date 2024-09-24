# Destination Page

from PyQt5 import QtWidgets
import os
from installermodule import rom

checksums = [24370, 41330, 35424]
us10checksum = 24370

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
                       if (myrom.title.decode("ASCII") == "Final Fantasy 3") or (myrom.title.decode("ASCII") == "Final Fantasy 6"):
                          print("DEBUG: ROM title correct.")
                          greenLights = greenLights + 1
                       if myrom.checksum in checksums:
                          print("DEBUG: ROM reported checksum correct.")
                          greenLights = greenLights + 1
                       else:
                          print("DEBUG: Internal checksum mismatch. Found " + str(myrom.checksum))
                       if computedchecksum in checksums:
                          print("DEBUG: ROM actual checksum correct.")
                          greenLights = greenLights + 1
                       else:
                          print("DEBUG: ROM checksum mismatch. Found " + str(computedchecksum))
                       romlabel += " " + myrom.title.decode("ASCII") + " (" + rom.decode_destcode(myrom.destcode) + ") (V1." + str(myrom.version) + ") "
                       if myrom.checksum == computedchecksum:
                          romlabel += "(Sum: OK) "
                       else:
                          romlabel += "(Sum: Fail) "
                          self.romValid = False
                       if greenLights >= 2:
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