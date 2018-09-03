# Customized Table Widget

from PyQt5 import QtCore, QtGui, QtWidgets
import csv
from installermodule import song

class selectionTableWidget(QtWidgets.QTableWidget):
        def __init__(self, parent):
                self.spccol = 0
                super().__init__(parent)
                self.songlist = song.parseSongXML("songs.xml")
                
                self.setGeometry(QtCore.QRect(0, 10, 551, 401))
                self.setCornerButtonEnabled(False)
                self.setObjectName("tableWidget")
                i = 0
                for src in self.songlist.sources:
                    if src.startswith("x") == False:
                        i += 1
                colcount = i
                rowcount = len(self.songlist.songs)
                self.setColumnCount(colcount)
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
                for idx,source in enumerate(self.songlist.sources):
                    if source.startswith("x") == False:
                        item = self.horizontalHeaderItem(idx)
                        print("DEBUG. Source header:", source)
                        item.setText(source.upper())
                        item.setTextAlignment(QtCore.Qt.AlignCenter)
                    else:
                        print("DEBUG. Hidden source encountered:", source)

                # Initialize selection list and fill with 0s.
                self.selections = [0]*len(self.songlist.songs)

                for idx,sng in enumerate(self.songlist.songs):
                    item = self.verticalHeaderItem(idx)
                    print("DEBUG: Song header:", sng.name)
                    item.setText(sng.name)
                    item.setTextAlignment(QtCore.Qt.AlignVCenter | QtCore.Qt.AlignLeft)

                # Read valid sources csv and populate radio buttons based on this.
                self.myButtons = []
                for row,sng in enumerate(self.songlist.songs):
                    self.myButtons.append([])
                    radios = []
                    radioGroup = QtWidgets.QButtonGroup(self)
                    selectspc = not(sng.sourceCheck("ost"))
                    for col,source in enumerate(self.songlist.sources):
                        if source.startswith("x") == False:
                            if source == "spc":
                                self.spccol = col
                            if sng.sourceCheck(source) == True:
                                radios.append(QtWidgets.QRadioButton())
                                radios[-1].myRowCol = (row, col)
                                radios[-1].clicked.connect(self.buttonClicked)
                                if col == 0 or (source == "spc" and selectspc == True):
                                    radios[-1].setChecked(True)
                                self.setCellWidget(row, col, radios[-1])
                                radioGroup.addButton(radios[-1])
                                self.myButtons[row].append(radios[-1])
                            else:
                                item = QtWidgets.QTableWidgetItem()
                                item.setFlags(QtCore.Qt.NoItemFlags)
                                self.setItem(row, col, item)
                                self.myButtons[row].append(None)

        
        @QtCore.pyqtProperty(QtCore.QVariant)
        def SongList(self):
                return QtCore.QVariant(self.selections)

        def buttonClicked(self):
                button = self.sender()
                songNum = button.myRowCol[0]
                source = button.myRowCol[1]
                self.selections[songNum] = source
        
        def reloadSources(self, sources):
            self.selections = sources
            for sng,source in enumerate(self.selections):
                try:
                    if self.myButtons[sng][source] is not None:
                        self.myButtons[sng][source].setChecked(True)
                    else:
                        if self.myButtons[sng][0] is not None:
                            self.myButtons[sng][0].setChecked(True)
                        else:
                            self.myButtons[sng][self.spccol].setChecked(True)
                        print("DEBUG: Asked to load a source that's not available. Defaulting to OST or SPC.")
                except TypeError as e:
                    print("DEBUG: TypeError:", sng, source, repr(e))
                except IndexError as e:
                    print("DEBUG: IndexError (likely hidden source):", sng, source, repr(e))