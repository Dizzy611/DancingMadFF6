# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file 'InstallWizard.ui'
#
# Created by: PyQt5 UI code generator 5.9
#
# WARNING! All changes made in this file will be lost!

from PyQt5 import QtCore, QtGui, QtWidgets

class Ui_InstallWizard(object):
    def setupUi(self, InstallWizard):
        InstallWizard.setObjectName("InstallWizard")
        InstallWizard.resize(575, 527)
        icon = QtGui.QIcon()
        icon.addPixmap(QtGui.QPixmap("kefka-16x16.png"), QtGui.QIcon.Normal, QtGui.QIcon.Off)
        InstallWizard.setWindowIcon(icon)
        InstallWizard.setWizardStyle(QtWidgets.QWizard.ModernStyle)
        InstallWizard.setTitleFormat(QtCore.Qt.AutoText)
        self.welcomePage = QtWidgets.QWizardPage()
        self.welcomePage.setObjectName("welcomePage")
        self.welcomeLabel = QtWidgets.QLabel(self.welcomePage)
        self.welcomeLabel.setGeometry(QtCore.QRect(20, 0, 531, 421))
        self.welcomeLabel.setWordWrap(True)
        self.welcomeLabel.setObjectName("welcomeLabel")
        InstallWizard.addPage(self.welcomePage)
        self.licensePage = licensePage()
        self.licensePage.setObjectName("licensePage")
        self.licenseBrowser = QtWidgets.QTextBrowser(self.licensePage)
        self.licenseBrowser.setGeometry(QtCore.QRect(0, 20, 551, 371))
        self.licenseBrowser.setObjectName("licenseBrowser")
        self.licenseLabel = QtWidgets.QLabel(self.licensePage)
        self.licenseLabel.setGeometry(QtCore.QRect(0, 0, 551, 16))
        self.licenseLabel.setObjectName("licenseLabel")
        self.licenseAccepted = QtWidgets.QCheckBox(self.licensePage)
        self.licenseAccepted.setGeometry(QtCore.QRect(10, 390, 531, 31))
        self.licenseAccepted.setObjectName("licenseAccepted")
        InstallWizard.addPage(self.licensePage)
        self.readmePage = readmePage()
        self.readmePage.setObjectName("readmePage")
        self.readmeBrowser = QtWidgets.QTextBrowser(self.readmePage)
        self.readmeBrowser.setGeometry(QtCore.QRect(0, 40, 551, 381))
        self.readmeBrowser.setObjectName("readmeBrowser")
        self.readmeLabel = QtWidgets.QLabel(self.readmePage)
        self.readmeLabel.setGeometry(QtCore.QRect(0, 0, 551, 31))
        self.readmeLabel.setWordWrap(True)
        self.readmeLabel.setObjectName("readmeLabel")
        InstallWizard.addPage(self.readmePage)
        self.destinationPage = destinationPage()
        self.destinationPage.setObjectName("destinationPage")
        self.romPath = QtWidgets.QLineEdit(self.destinationPage)
        self.romPath.setGeometry(QtCore.QRect(30, 70, 301, 20))
        self.romPath.setObjectName("romPath")
        self.romPathLabel = QtWidgets.QLabel(self.destinationPage)
        self.romPathLabel.setGeometry(QtCore.QRect(30, 50, 531, 16))
        self.romPathLabel.setObjectName("romPathLabel")
        self.romPathBrowse = QtWidgets.QPushButton(self.destinationPage)
        self.romPathBrowse.setGeometry(QtCore.QRect(340, 70, 75, 21))
        self.romPathBrowse.setObjectName("romPathBrowse")
        self.destPath = QtWidgets.QLineEdit(self.destinationPage)
        self.destPath.setGeometry(QtCore.QRect(30, 180, 301, 21))
        self.destPath.setObjectName("destPath")
        self.destPathBrowse = QtWidgets.QPushButton(self.destinationPage)
        self.destPathBrowse.setGeometry(QtCore.QRect(340, 180, 75, 21))
        self.destPathBrowse.setObjectName("destPathBrowse")
        self.destPathLabel = QtWidgets.QLabel(self.destinationPage)
        self.destPathLabel.setGeometry(QtCore.QRect(30, 160, 521, 16))
        self.destPathLabel.setObjectName("destPathLabel")
        self.higanNotice = QtWidgets.QLabel(self.destinationPage)
        self.higanNotice.setGeometry(QtCore.QRect(30, 310, 521, 91))
        self.higanNotice.setWordWrap(True)
        self.higanNotice.setObjectName("higanNotice")
        self.ROMDetected = QtWidgets.QLabel(self.destinationPage)
        self.ROMDetected.setGeometry(QtCore.QRect(30, 90, 521, 16))
        self.ROMDetected.setObjectName("ROMDetected")
        InstallWizard.addPage(self.destinationPage)
        self.installtypePage = installtypePage()
        self.installtypePage.setObjectName("installtypePage")
        self.verticalLayoutWidget = QtWidgets.QWidget(self.installtypePage)
        self.verticalLayoutWidget.setGeometry(QtCore.QRect(20, 140, 531, 222))
        self.verticalLayoutWidget.setObjectName("verticalLayoutWidget")
        self.soundtrackLayout = QtWidgets.QVBoxLayout(self.verticalLayoutWidget)
        self.soundtrackLayout.setContentsMargins(0, 0, 0, 0)
        self.soundtrackLayout.setObjectName("soundtrackLayout")
        self.soundtrackLabel = QtWidgets.QLabel(self.verticalLayoutWidget)
        self.soundtrackLabel.setObjectName("soundtrackLabel")
        self.soundtrackLayout.addWidget(self.soundtrackLabel)
        self.sidselectButton = QtWidgets.QRadioButton(self.verticalLayoutWidget)
        self.sidselectButton.setChecked(True)
        self.sidselectButton.setObjectName("sidselectButton")
        self.soundtrackLayout.addWidget(self.sidselectButton)
        self.ostButton = QtWidgets.QRadioButton(self.verticalLayoutWidget)
        self.ostButton.setObjectName("ostButton")
        self.soundtrackLayout.addWidget(self.ostButton)
        self.fftButton = QtWidgets.QRadioButton(self.verticalLayoutWidget)
        self.fftButton.setObjectName("fftButton")
        self.soundtrackLayout.addWidget(self.fftButton)
        self.sschafButton = QtWidgets.QRadioButton(self.verticalLayoutWidget)
        self.sschafButton.setObjectName("sschafButton")
        self.soundtrackLayout.addWidget(self.sschafButton)
        self.ocrButton = QtWidgets.QRadioButton(self.verticalLayoutWidget)
        self.ocrButton.setObjectName("ocrButton")
        self.soundtrackLayout.addWidget(self.ocrButton)
        self.ocraltButton = QtWidgets.QRadioButton(self.verticalLayoutWidget)
        self.ocraltButton.setObjectName("ocraltButton")
        self.soundtrackLayout.addWidget(self.ocraltButton)
        self.ffarButton = QtWidgets.QRadioButton(self.verticalLayoutWidget)
        self.ffarButton.setObjectName("ffarButton")
        self.soundtrackLayout.addWidget(self.ffarButton)
        self.crcButton = QtWidgets.QRadioButton(self.verticalLayoutWidget)
        self.crcButton.setObjectName("crcButton")
        self.soundtrackLayout.addWidget(self.crcButton)
        self.customButton = QtWidgets.QRadioButton(self.verticalLayoutWidget)
        self.customButton.setObjectName("customButton")
        self.soundtrackLayout.addWidget(self.customButton)
        self.verticalLayoutWidget_2 = QtWidgets.QWidget(self.installtypePage)
        self.verticalLayoutWidget_2.setGeometry(QtCore.QRect(20, 40, 531, 94))
        self.verticalLayoutWidget_2.setObjectName("verticalLayoutWidget_2")
        self.emulatorLayout = QtWidgets.QVBoxLayout(self.verticalLayoutWidget_2)
        self.emulatorLayout.setContentsMargins(0, 0, 0, 0)
        self.emulatorLayout.setObjectName("emulatorLayout")
        self.emulatorLabel = QtWidgets.QLabel(self.verticalLayoutWidget_2)
        self.emulatorLabel.setObjectName("emulatorLabel")
        self.emulatorLayout.addWidget(self.emulatorLabel)
        self.higanButton = QtWidgets.QRadioButton(self.verticalLayoutWidget_2)
        self.higanButton.setChecked(True)
        self.higanButton.setObjectName("higanButton")
        self.emulatorLayout.addWidget(self.higanButton)
        self.BSNESButton = QtWidgets.QRadioButton(self.verticalLayoutWidget_2)
        self.BSNESButton.setObjectName("BSNESButton")
        self.emulatorLayout.addWidget(self.BSNESButton)
        self.SD2SNESButton = QtWidgets.QRadioButton(self.verticalLayoutWidget_2)
        self.SD2SNESButton.setObjectName("SD2SNESButton")
        self.emulatorLayout.addWidget(self.SD2SNESButton)
        self.gridLayoutWidget = QtWidgets.QWidget(self.installtypePage)
        self.gridLayoutWidget.setGeometry(QtCore.QRect(20, 370, 531, 41))
        self.gridLayoutWidget.setObjectName("gridLayoutWidget")
        self.gridLayout = QtWidgets.QGridLayout(self.gridLayoutWidget)
        self.gridLayout.setContentsMargins(0, 0, 0, 0)
        self.gridLayout.setObjectName("gridLayout")
        self.mplayerCheck = QtWidgets.QCheckBox(self.gridLayoutWidget)
        self.mplayerCheck.setObjectName("mplayerCheck")
        self.gridLayout.addWidget(self.mplayerCheck, 1, 1, 1, 1)
        self.twueCheck = QtWidgets.QCheckBox(self.gridLayoutWidget)
        self.twueCheck.setObjectName("twueCheck")
        self.gridLayout.addWidget(self.twueCheck, 1, 0, 1, 1)
        self.label = QtWidgets.QLabel(self.gridLayoutWidget)
        self.label.setObjectName("label")
        self.gridLayout.addWidget(self.label, 0, 0, 1, 1)
        self.cutsongCheck = QtWidgets.QCheckBox(self.gridLayoutWidget)
        self.cutsongCheck.setObjectName("cutsongCheck")
        self.gridLayout.addWidget(self.cutsongCheck, 1, 2, 1, 1)
        InstallWizard.addPage(self.installtypePage)
        self.customselectionPage = customselectionPage()
        self.customselectionPage.setObjectName("customselectionPage")
        self.trackSelectionWidget = selectionTableWidget(self.customselectionPage)
        self.trackSelectionWidget.setGeometry(QtCore.QRect(0, 40, 551, 371))
        self.trackSelectionWidget.setObjectName("trackSelectionWidget")
        self.horizontalLayoutWidget = QtWidgets.QWidget(self.customselectionPage)
        self.horizontalLayoutWidget.setGeometry(QtCore.QRect(0, 10, 555, 31))
        self.horizontalLayoutWidget.setObjectName("horizontalLayoutWidget")
        self.horizontalLayout = QtWidgets.QHBoxLayout(self.horizontalLayoutWidget)
        self.horizontalLayout.setContentsMargins(0, 0, 0, 0)
        self.horizontalLayout.setObjectName("horizontalLayout")
        self.presetLabel = QtWidgets.QLabel(self.horizontalLayoutWidget)
        self.presetLabel.setObjectName("presetLabel")
        self.horizontalLayout.addWidget(self.presetLabel)
        self.recommendedPreset = QtWidgets.QRadioButton(self.horizontalLayoutWidget)
        self.recommendedPreset.setObjectName("recommendedPreset")
        self.horizontalLayout.addWidget(self.recommendedPreset)
        self.ostPreset = QtWidgets.QRadioButton(self.horizontalLayoutWidget)
        self.ostPreset.setChecked(True)
        self.ostPreset.setObjectName("ostPreset")
        self.horizontalLayout.addWidget(self.ostPreset)
        self.fftPreset = QtWidgets.QRadioButton(self.horizontalLayoutWidget)
        self.fftPreset.setObjectName("fftPreset")
        self.horizontalLayout.addWidget(self.fftPreset)
        self.sscPreset = QtWidgets.QRadioButton(self.horizontalLayoutWidget)
        self.sscPreset.setObjectName("sscPreset")
        self.horizontalLayout.addWidget(self.sscPreset)
        self.ocrPreset = QtWidgets.QRadioButton(self.horizontalLayoutWidget)
        self.ocrPreset.setObjectName("ocrPreset")
        self.horizontalLayout.addWidget(self.ocrPreset)
        self.ocraltPreset = QtWidgets.QRadioButton(self.horizontalLayoutWidget)
        self.ocraltPreset.setObjectName("ocraltPreset")
        self.horizontalLayout.addWidget(self.ocraltPreset)
        self.loadPreset = QtWidgets.QPushButton(self.horizontalLayoutWidget)
        self.loadPreset.setObjectName("loadPreset")
        self.horizontalLayout.addWidget(self.loadPreset)
        InstallWizard.addPage(self.customselectionPage)
        self.downloadPage = downloadPage()
        self.downloadPage.setObjectName("downloadPage")
        self.gridLayoutWidget_2 = QtWidgets.QWidget(self.downloadPage)
        self.gridLayoutWidget_2.setGeometry(QtCore.QRect(30, 230, 501, 51))
        self.gridLayoutWidget_2.setObjectName("gridLayoutWidget_2")
        self.totalLayout = QtWidgets.QGridLayout(self.gridLayoutWidget_2)
        self.totalLayout.setContentsMargins(0, 0, 0, 0)
        self.totalLayout.setObjectName("totalLayout")
        self.totalBar = QtWidgets.QProgressBar(self.gridLayoutWidget_2)
        self.totalBar.setProperty("value", 0)
        self.totalBar.setObjectName("totalBar")
        self.totalLayout.addWidget(self.totalBar, 1, 0, 1, 1)
        self.totalLabel = QtWidgets.QLabel(self.gridLayoutWidget_2)
        self.totalLabel.setLayoutDirection(QtCore.Qt.LeftToRight)
        self.totalLabel.setObjectName("totalLabel")
        self.totalLayout.addWidget(self.totalLabel, 0, 0, 1, 1, QtCore.Qt.AlignHCenter)
        self.gridLayoutWidget_3 = QtWidgets.QWidget(self.downloadPage)
        self.gridLayoutWidget_3.setGeometry(QtCore.QRect(30, 120, 501, 51))
        self.gridLayoutWidget_3.setObjectName("gridLayoutWidget_3")
        self.currentLayout = QtWidgets.QGridLayout(self.gridLayoutWidget_3)
        self.currentLayout.setContentsMargins(0, 0, 0, 0)
        self.currentLayout.setObjectName("currentLayout")
        self.currentBar = QtWidgets.QProgressBar(self.gridLayoutWidget_3)
        self.currentBar.setProperty("value", 0)
        self.currentBar.setObjectName("currentBar")
        self.currentLayout.addWidget(self.currentBar, 1, 0, 1, 1)
        self.currentLabel = QtWidgets.QLabel(self.gridLayoutWidget_3)
        self.currentLabel.setObjectName("currentLabel")
        self.currentLayout.addWidget(self.currentLabel, 0, 0, 1, 1, QtCore.Qt.AlignHCenter)
        InstallWizard.addPage(self.downloadPage)
        self.finalPage = finalPage()
        self.finalPage.setObjectName("finalPage")
        self.finalLabel = QtWidgets.QLabel(self.finalPage)
        self.finalLabel.setGeometry(QtCore.QRect(0, 0, 551, 41))
        self.finalLabel.setWordWrap(True)
        self.finalLabel.setObjectName("finalLabel")
        self.finalBrowser = QtWidgets.QTextBrowser(self.finalPage)
        self.finalBrowser.setGeometry(QtCore.QRect(0, 50, 551, 371))
        self.finalBrowser.setObjectName("finalBrowser")
        InstallWizard.addPage(self.finalPage)

        self.retranslateUi(InstallWizard)
        QtCore.QMetaObject.connectSlotsByName(InstallWizard)

    def retranslateUi(self, InstallWizard):
        _translate = QtCore.QCoreApplication.translate
        InstallWizard.setWindowTitle(_translate("InstallWizard", "Dancing Mad Installer"))
        self.welcomePage.setTitle(_translate("InstallWizard", "Dancing Mad Beta Installer"))
        self.welcomePage.setSubTitle(_translate("InstallWizard", "Welcome"))
        self.welcomeLabel.setText(_translate("InstallWizard", """<html>
                                                                 <head/>
                                                                 <body>
                                                                 <p align="center">Welcome to the installer for <span style=" font-weight:600;">Dancing Mad</span>, the music replacement mod for Final Fantasy VI!</p>
                                                                 <p>
                                                                 <br/>
                                                                 </p>
                                                                 <p>
                                                                 <br/>
                                                                 </p>
                                                                 <p>
                                                                 <br/>
                                                                 </p>
                                                                 <p>
                                                                 <br/>
                                                                 This installer will walk you through the steps of selecting and downloading your replacement soundtrack, patching your game, and setting the mod up to run in your
                                                                 preferred emulator(s) and/or flashcart. <br/>
                                                                 <br/>
                                                                 Currently, <span style=" font-weight:600;">Dancing Mad</span> has been tested on the <span style=" font-weight:600;">Higan v097</span>, 
                                                                 <span style=" font-weight:600;">Snes9x-msu v1.55</span>, and <span style=" font-weight:600;">bsnes-plus v073+2</span> emulators, and is supported in all three,
                                                                 with some caveats for BSNES as outlined in the readme, which you can view later on in the install. It has also been tested on the
                                                                 <span style=" font-weight:600;">SD2SNES</span> flash cart, and an installation option is provided for it. However, the developers do not have one so testing
                                                                 is slow as of the time this was written.<br/></p><p><br/></p><p><br/></p><p></p><p>Press &quot;Next&quot; to begin.</p></body></html>"""))
        self.licensePage.setTitle(_translate("InstallWizard", "Dancing Mad Beta Installer"))
        self.licensePage.setSubTitle(_translate("InstallWizard", "License Agreement"))
        self.licenseBrowser.setHtml(_translate("InstallWizard", "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0//EN\" \"http://www.w3.org/TR/REC-html40/strict.dtd\">\n"
"<html><head><meta name=\"qrichtext\" content=\"1\" /><style type=\"text/css\">\n"
"p, li { white-space: pre-wrap; }\n"
"</style></head><body style=\" font-family:\'Sans Serif\'; font-size:9pt; font-weight:400; font-style:normal;\">\n"
"<p style=\" margin-top:12px; margin-bottom:12px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;\">ERROR: Could not load LICENSE file.</p></body></html>"))
        self.licenseLabel.setText(_translate("InstallWizard", "<html><head/><body><p>Please read the below licensing agreement.</p></body></html>"))
        self.licenseAccepted.setText(_translate("InstallWizard", "Check here if you have read and accept the terms.\n"
"Acceptance is necessary to complete installation."))
        self.readmePage.setTitle(_translate("InstallWizard", "Dancing Mad Beta Installer"))
        self.readmePage.setSubTitle(_translate("InstallWizard", "Readme"))
        self.readmeBrowser.setHtml(_translate("InstallWizard", "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0//EN\" \"http://www.w3.org/TR/REC-html40/strict.dtd\">\n"
"<html><head><meta name=\"qrichtext\" content=\"1\" /><style type=\"text/css\">\n"
"p, li { white-space: pre-wrap; }\n"
"</style></head><body style=\" font-family:\'Sans Serif\'; font-size:9pt; font-weight:400; font-style:normal;\">\n"
"<p style=\" margin-top:12px; margin-bottom:12px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;\"><span style=\" font-family:\'Sans Serif\'; font-size:8.25pt;\">ERROR: Could not load README file</span></p></body></html>"))
        self.readmeLabel.setText(_translate("InstallWizard", "<html><head/><body><p>Below you will find detailed documentation for both the install process and the mod in general. Please read thoroughly before proceeding.</p></body></html>"))
        self.destinationPage.setTitle(_translate("InstallWizard", "Dancing Mad Beta Installer"))
        self.destinationPage.setSubTitle(_translate("InstallWizard", "Select Destination Directory..."))
        self.romPathLabel.setText(_translate("InstallWizard", "Final Fantasy VI SNES/SFC ROM to be patched:"))
        self.romPathBrowse.setText(_translate("InstallWizard", "Browse..."))
        self.destPathBrowse.setText(_translate("InstallWizard", "Browse..."))
        self.destPathLabel.setText(_translate("InstallWizard", "Destination Directory*:"))
        self.higanNotice.setText(_translate("InstallWizard", "*Higan users, you will have to manually import the patched ROM and then copy your files from this directory into Higan\'s directory structure after install, so treat this as a temporary directory. Everyone else, this is where the modded ROM will reside."))
        self.ROMDetected.setText(_translate("InstallWizard", "Detected ROM Version: Not Yet Selected"))
        self.installtypePage.setTitle(_translate("InstallWizard", "Dancing Mad Beta Installer"))
        self.installtypePage.setSubTitle(_translate("InstallWizard", "Select Install Type"))
        self.soundtrackLabel.setText(_translate("InstallWizard", "Choose which soundtrack to use, or pick \"Custom\" to select individual tracks:"))
        self.sidselectButton.setText(_translate("InstallWizard", "Developer\'s Recommendation"))
        self.ostButton.setText(_translate("InstallWizard", "Final Fantasy VI OST Only"))
        self.fftButton.setText(_translate("InstallWizard", "FinalFanTim\'s Remastered Tracks"))
        self.sschafButton.setText(_translate("InstallWizard", "Sean Schafianski\'s Final Fantasy VI Remastered Disc One"))
        self.ocrButton.setText(_translate("InstallWizard", "OCRemix Balance and Ruin"))
        self.ocraltButton.setText(_translate("InstallWizard", "OCRemix Balance and Ruin (Alternate loops by Qwertymodo)"))
        self.ffarButton.setText(_translate("InstallWizard", "Final Fantasy Acoustic Rendition"))
        self.crcButton.setText(_translate("InstallWizard", "ChrystalChameleon\'s FF6 Orchestrated"))
        self.customButton.setText(_translate("InstallWizard", "Custom"))
        self.emulatorLabel.setText(_translate("InstallWizard", "Choose what you will be running the mod on:"))
        self.higanButton.setText(_translate("InstallWizard", "Higan"))
        self.BSNESButton.setText(_translate("InstallWizard", "BSNES"))
        self.SD2SNESButton.setText(_translate("InstallWizard", "SD2SNES/Snes9x-msu"))
        self.mplayerCheck.setText(_translate("InstallWizard", "Madsiur\'s Music Player"))
        self.twueCheck.setText(_translate("InstallWizard", "Ted Woolsey Uncensored Edition 2.00"))
        self.label.setText(_translate("InstallWizard", "Choose Optional Patches (see Readme):"))
        self.cutsongCheck.setText(_translate("InstallWizard", "edale2\'s Cut Songs Restoration"))
        self.customselectionPage.setTitle(_translate("InstallWizard", "Dancing Mad Beta Installer"))
        self.customselectionPage.setSubTitle(_translate("InstallWizard", "Custom Track Selection"))
        self.presetLabel.setText(_translate("InstallWizard", "Preset:"))
        self.recommendedPreset.setText(_translate("InstallWizard", "Recommended"))
        self.ostPreset.setText(_translate("InstallWizard", "OST"))
        self.fftPreset.setText(_translate("InstallWizard", "FinalFanTim"))
        self.sscPreset.setText(_translate("InstallWizard", "SSChaf"))
        self.ocrPreset.setText(_translate("InstallWizard", "OCRemix"))
        self.ocraltPreset.setText(_translate("InstallWizard", "Alt OCR"))
        self.loadPreset.setText(_translate("InstallWizard", "Load"))
        self.downloadPage.setTitle(_translate("InstallWizard", "Dancing Mad Beta Installer"))
        self.downloadPage.setSubTitle(_translate("InstallWizard", "Downloading, Patching, and Installing..."))
        self.totalLabel.setText(_translate("InstallWizard", "Total"))
        self.currentLabel.setText(_translate("InstallWizard", "Connecting..."))
        self.finalPage.setTitle(_translate("InstallWizard", "Dancing Mad Beta Installer"))
        self.finalPage.setSubTitle(_translate("InstallWizard", "Final Notes..."))
        self.finalLabel.setText(_translate("InstallWizard", "<html><head/><body><p>Install successful! Below you will find some final notes for your particular install. These will generally be things already covered in the documentation, but they\'re here for your convenience.</p></body></html>"))
        self.finalBrowser.setHtml(_translate("InstallWizard", "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0//EN\" \"http://www.w3.org/TR/REC-html40/strict.dtd\">\n"
"<html><head><meta name=\"qrichtext\" content=\"1\" /><style type=\"text/css\">\n"
"p, li { white-space: pre-wrap; }\n"
"</style></head><body style=\" font-family:\'Sans Serif\'; font-size:9pt; font-weight:400; font-style:normal;\">\n"
"<p style=\" margin-top:12px; margin-bottom:12px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;\"><span style=\" font-family:\'Sans Serif\'; font-size:8.25pt;\">TO BE FILLED IN</span></p></body></html>"))


from installermodule.customselectionpage import customselectionPage
from installermodule.readmepage import readmePage
from installermodule.finalpage import finalPage
from installermodule.downloadpage import downloadPage
from installermodule.licensepage import licensePage
from installermodule.selectiontablewidget import selectionTableWidget
from installermodule.installtypepage import installtypePage
from installermodule.destinationpage import destinationPage
