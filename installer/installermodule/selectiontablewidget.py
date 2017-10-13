# Customized Table Widget

from PyQt5 import QtCore, QtGui, QtWidgets
import csv
from installermodule.selections import *

sources = [ "OST", "FFT", "SST", "OCR", "OTH", "OCR2" ]

class selectionTableWidget(QtWidgets.QTableWidget):
        def __init__(self, parent):
                super().__init__(parent)

                self.setGeometry(QtCore.QRect(0, 10, 551, 401))
                self.setCornerButtonEnabled(False)
                self.setObjectName("tableWidget")
                
                # Grab number of rows/columns based on file entries, set up headers.
                with open("trackSources.csv") as f:
                    tmp = csv.reader(f)
                    colcount = len(next(tmp))
                self.setColumnCount(colcount)
                with open("trackTitles.dat") as f:
                    rowcount = sum((1 for _ in f))
                self.setRowCount(rowcount)
                for i in range(0, rowcount):
                    item = QtWidgets.QTableWidgetItem()
                    self.setVerticalHeaderItem(i, item)
                for i in range(0, colcount):
                    item = QtWidgets.QTableWidgetItem()
                    self.setHorizontalHeaderItem(i, item)
                self.horizontalHeader().setDefaultSectionSize(40)
                self.horizontalHeader().setMinimumSectionSize(10)
                self.horizontalHeader().setStretchLastSection(False)
                self.verticalHeader().setCascadingSectionResizes(False)
                self.verticalHeader().setDefaultSectionSize(20)
                self.verticalHeader().setMinimumSectionSize(10)
                self.verticalHeader().setStretchLastSection(False)
                for idx,source in enumerate(sources):
                    item = self.horizontalHeaderItem(idx)
                    print("DEBUG. Source header:", source)
                    item.setText(source)
                    item.setTextAlignment(QtCore.Qt.AlignCenter)

                # Initialize song list and fill with 0s.
                self.songList = SELECTION_OST

                # Read list of track titles and place as vertical header text.
                index = 0
                with open("trackTitles.dat") as f:
                        for idx, line in enumerate(f):
                            item = self.verticalHeaderItem(idx)
                            print("DEBUG: Song header:", line)
                            item.setText(line)
                            item.setTextAlignment(QtCore.Qt.AlignVCenter | QtCore.Qt.AlignLeft)
                               

                # Read valid sources csv and populate radio buttons based on this.
                self.myButtons = []
                with open("trackSources.csv") as csvfile:
                        csvreader = csv.reader(csvfile)
                        rowindex = 0
                        for song in csvreader:
                                self.myButtons.append([])
                                colindex = 0
                                radios = []
                                radioGroup = QtWidgets.QButtonGroup(self)
                                for source in song:
                                        if source == "1":
                                                radios.append(QtWidgets.QRadioButton())
                                                radios[-1].myRowCol = (rowindex, colindex) # Dirty, dirty hack. I feel unclean... And it is glorious. Thank you, Python Gods.
                                                radios[-1].clicked.connect(self.buttonClicked)
                                                if colindex == 0:
                                                      radios[-1].setChecked(True)
                                                self.setCellWidget(rowindex, colindex, radios[-1])
                                                radioGroup.addButton(radios[-1])
                                                self.myButtons[rowindex].append(radios[-1])
                                        else:
                                                item = QtWidgets.QTableWidgetItem()
                                                item.setFlags(QtCore.Qt.NoItemFlags)
                                                self.setItem(rowindex, colindex, item)
                                                self.myButtons[rowindex].append(None)
                                        colindex = colindex + 1
                                rowindex = rowindex + 1

        
        @QtCore.pyqtProperty(QtCore.QVariant)
        def SongList(self):
                return QtCore.QVariant(self.songList)

        def buttonClicked(self):
                button = self.sender()
                songNum = button.myRowCol[0]
                source = button.myRowCol[1]
                self.songList[songNum] = source
        
        def reloadSources(self, sources):
            self.songList = sources
            for song,source in enumerate(self.songList):
                try:
                    if self.myButtons[song][source] is not None:
                        self.myButtons[song][source].setChecked(True)
                    else:
                        self.myButtons[song][0].setChecked(True)
                        print("DEBUG: Asked to load a source that's not available. Defaulting to OST.")
                except TypeError as e:
                    print("DEBUG: TypeError:", song, source, str(e))