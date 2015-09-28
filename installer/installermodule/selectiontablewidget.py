# Customized Table Widget

from PyQt5 import QtCore, QtGui, QtWidgets
import csv

class selectionTableWidget(QtWidgets.QTableWidget):
        def __init__(self, parent):
                super().__init__(parent)


                # Static design stuff. Copied from old hand-edited UIC file.
                self.setGeometry(QtCore.QRect(0, 10, 551, 401))
                self.setCornerButtonEnabled(False)
                self.setObjectName("tableWidget")
                self.setColumnCount(5)
                self.setRowCount(59)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(0, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(1, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(2, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(3, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(4, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(5, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(6, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(7, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(8, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(9, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(10, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(11, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(12, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(13, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(14, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(15, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(16, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(17, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(18, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(19, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(20, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(21, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(22, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(23, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(24, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(25, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(26, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(27, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(28, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(29, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(30, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(31, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(32, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(33, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(34, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(35, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(36, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(37, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(38, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(39, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(40, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(41, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(42, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(43, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(44, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(45, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(46, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(47, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(48, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(49, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(50, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(51, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(52, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(53, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(54, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(55, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(56, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(57, item)
                item = QtWidgets.QTableWidgetItem()
                self.setVerticalHeaderItem(58, item)
                item = QtWidgets.QTableWidgetItem()
                self.setHorizontalHeaderItem(0, item)
                item = QtWidgets.QTableWidgetItem()
                self.setHorizontalHeaderItem(1, item)
                item = QtWidgets.QTableWidgetItem()
                self.setHorizontalHeaderItem(2, item)
                item = QtWidgets.QTableWidgetItem()
                self.setHorizontalHeaderItem(3, item)
                item = QtWidgets.QTableWidgetItem()
                self.setHorizontalHeaderItem(4, item)
                self.horizontalHeader().setDefaultSectionSize(40)
                self.horizontalHeader().setMinimumSectionSize(10)
                self.horizontalHeader().setStretchLastSection(False)
                self.verticalHeader().setCascadingSectionResizes(False)
                self.verticalHeader().setMinimumSectionSize(10)
                self.verticalHeader().setStretchLastSection(False)
                item = self.horizontalHeaderItem(0)
                item.setText("OST")
                item = self.horizontalHeaderItem(1)
                item.setText("FFT")
                item = self.horizontalHeaderItem(2)
                item.setText("SSC")
                item = self.horizontalHeaderItem(3)
                item.setText("OCR")
                item = self.horizontalHeaderItem(4)
                item.setText("OTH")
                # End static crap.

                # Initialize song list and fill with 0s.
                self.songList = []
                self.songList = self.songList + [0]*59

		# Read list of track titles and place as vertical header text.
                index = 0
                with open("trackTitles.dat") as f:
                        for line in f:
                                if index <= 58:
                                        item = self.verticalHeaderItem(index)
                                        item.setText(line)
                                index = index + 1

                # Read valid sources csv and populate radio buttons based on this.
                with open("trackSources.csv") as csvfile:
                        csvreader = csv.reader(csvfile)
                        rowindex = 0
                        for song in csvreader:
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
                                        else:
                                                item = QtWidgets.QTableWidgetItem()
                                                item.setFlags(QtCore.Qt.NoItemFlags)
                                                self.setItem(rowindex, colindex, item)
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
