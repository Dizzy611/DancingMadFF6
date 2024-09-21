/* BSD 2-Clause License

Copyright (c) 2017-2024, Dylan "Dizzy" O'Malley-Morrison <dizzy@domad.science>

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Disclaimer of Trademark and of Association with Rights Holders
"Final Fantasy","Final Fantasy III", and "Final Fantasy VI" are registered trademarks
of Square Enix Holdings Co., Ltd, hereafter "Square Enix". This is NOT a licensed product
of Square Enix. The developers are not affiliated with or sponsored by Square Enix or any other
rights holders.

This patch is intended to be used only with a legally obtained copy of Final Fantasy III. */

#include "dminst.h"
#include "./ui_dminst.h"
#include <QFileDialog>
#include <QMessageBox>


#include "rom_validator.h"
#include "song_parser.h"

#include <ostream>
#include <iostream>
#include <sstream>


DMInst::DMInst(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::DMInst)
{

    // intentional bad URL to test error handling
    //QUrl mirrorsUrl("https://gorthub.com/Dizzy611/DancingMadFF6/raw/refs/heads/master/installer/mirrors.dat");

    QUrl mirrorsUrl(MIRRORS_URL);
    dmgr = new DownloadManager(mirrorsUrl, this);
    this->gostage = 0;
    connect(dmgr, SIGNAL(downloaded()), this, SLOT(downloadFinished()));
    
    //std::tuple<std::vector<std::string>, std::vector<struct Preset>, std::vector<struct Song>> xmlparse = parseSongsXML("./songs.xml");
    //std::vector<struct Song> songs = std::get<2>(xmlparse);
    //std::vector<struct Preset> presets = std::get<1>(xmlparse);
    //std::vector<std::string> sources = std::get<0>(xmlparse);

    ui->setupUi(this);

    // Set up initial status
    this->findChild<QLabel*>("statusLabel")->setText("Downloading mirror data from GitHub...");


    // Disable browse and go buttons until mirrors and songs are loaded
    this->findChild<QPushButton*>("goButton")->setEnabled(false);
    this->findChild<QPushButton*>("ROMSelectBrowse")->setEnabled(false);

}

DMInst::~DMInst()
{
    delete ui;
}

void DMInst::on_ROMSelectBrowse_clicked()
{
    QString filename = QFileDialog::getOpenFileName(this, tr("Choose ROM"), QDir::homePath());
    QLineEdit* selectedfile = this->findChild<QLineEdit*>("ROMSelectLine");
    selectedfile->setText(filename);
}


void DMInst::on_ROMSelectLine_textChanged(const QString &arg1)
{
    struct ROMValid valid_rom = validate_rom(arg1.toStdString());
    if ((valid_rom.return_code == WARN_PATCHED) || (valid_rom.return_code == VALID_US_V11) || (valid_rom.return_code == VALID_JP)) {
        this->findChild<QCheckBox*>("patchCheck_1")->setEnabled(false);
        this->findChild<QCheckBox*>("patchCheck_2")->setEnabled(false);
        this->findChild<QCheckBox*>("patchCheck_3")->setEnabled(false);
        this->findChild<QPushButton*>("goButton")->setEnabled(true);
    } else if (valid_rom.return_code == VALID_US_V10) {
        this->findChild<QCheckBox*>("patchCheck_1")->setEnabled(true);
        this->findChild<QCheckBox*>("patchCheck_2")->setEnabled(true);
        this->findChild<QCheckBox*>("patchCheck_3")->setEnabled(true);
        this->findChild<QPushButton*>("goButton")->setEnabled(true);
    } else {
        this->findChild<QCheckBox*>("patchCheck_1")->setEnabled(false);
        this->findChild<QCheckBox*>("patchCheck_2")->setEnabled(false);
        this->findChild<QCheckBox*>("patchCheck_3")->setEnabled(false);
        this->findChild<QPushButton*>("goButton")->setEnabled(false);
    }

    if (valid_rom.return_code == WARN_PATCHED) {
        this->findChild<QLabel*>("statusLabel")->setText("Already patched ROM detected. Proceed with caution.");
    } else if (valid_rom.return_code == VALID_US_V11) {
        this->findChild<QLabel*>("statusLabel")->setText("Valid US V1.1 ROM detected. Optional patches disabled.");
    } else if (valid_rom.return_code == VALID_US_V10) {
        this->findChild<QLabel*>("statusLabel")->setText("Valid US V1.0 ROM detected. All features enabled.");
    } else if (valid_rom.return_code == VALID_JP) {
        this->findChild<QLabel*>("statusLabel")->setText("Valid JP ROM detected. Optional patches disabled.");
    } else {
        this->findChild<QLabel*>("statusLabel")->setText("Invalid ROM detected. Unable to continue.");
    }

    std::cout << valid_rom.error_string << std::endl;
}


void DMInst::on_goButton_clicked()
{

}

void DMInst::nextStage() {
    switch(this->gostage) {
    case 0: {
        this->findChild<QLabel*>("statusLabel")->setText("Downloading song and preset lists from GitHub...");
        QUrl xmlUrl(XML_URL);
        dmgr = new DownloadManager(xmlUrl, this);
        this->gostage = 1;
        connect(dmgr, SIGNAL(downloaded()), this, SLOT(downloadFinished()));
        break;
    }
    case 1: {
        this->findChild<QLabel*>("statusLabel")->setText("Populating song and preset lists from downloaded data...");
        int i = 0;

        // Set presets in soundtrack list
        for (auto & element : this->presets) {
            this->findChild<QComboBox*>("soundtrackSelectBox")->setItemText(i, QString::fromStdString(element.friendly_name));
            i++;
        }
        this->findChild<QComboBox*>("soundtrackSelectBox")->setItemText(i, "None/SPC");

        // Set opera selections
        this->findChild<QComboBox*>("operaSelectBox")->setItemText(0, "SPC/Do Not Download");
        i = 1;
        for (auto & element : this->sources) {
            if (element.first.rfind("x", 0) != std::string::npos) {
                this->findChild<QComboBox*>("operaSelectBox")->setItemText(i, QString::fromStdString(element.second));
                i++;
            }
        }

        // TODO: Populate song and preset lists
        this->gostage = 2;

        // DEBUG
        std::cout << "MIRROR LIST:" << std::endl;
        for (auto & element : this->mirrors) {
            std::cout << "\t" << element << std::endl;
        }

        this->findChild<QLabel*>("statusLabel")->setText("Waiting on user... Select your ROM, soundtrack, and patches and press GO when ready!");
        this->findChild<QPushButton*>("ROMSelectBrowse")->setEnabled(true);
    }
    default:
        break;
    }
}
void DMInst::downloadFinished() {
    switch(this->gostage) {
    case 0: {
        QByteArray mirrorData = dmgr->downloadedData();
        if (mirrorData.isEmpty()) {
            // mirror data failed to download for one reason or another, response code will have been logged to stdout. use local mirror data if available, else fatal.
            QFile mirrorDat(DATA_PATH "/mirrors.dat");
            if(!mirrorDat.open(QIODevice::ReadOnly)) {
                QMessageBox msgBox;
                msgBox.setText("Unable to download list of mirrors or read local list of mirrors. Installation cannot continue.");
                msgBox.setStandardButtons(QMessageBox::Ok);
                msgBox.setDefaultButton(QMessageBox::Ok);
                msgBox.exec();
                QCoreApplication::exit(1); // Quit, as we can't continue
                return;
            } else {
                mirrorData = mirrorDat.readAll();
            }
        }
        std::istringstream in(mirrorData.toStdString());
        std::string line;
        while (std::getline(in, line)) {
            this->mirrors.push_back(line);
        }
        this->nextStage();
        break;
    }
    case 1: {
        QByteArray xmlData = dmgr->downloadedData();
        if (xmlData.isEmpty()) {
            // xml data failed to download for one reason or another, response code will have been logged to stdout. use local mirror data if available, else fatal.
            QFile songsXml(DATA_PATH "/songs.xml");
            if(!songsXml.open(QIODevice::ReadOnly)) {
                QMessageBox msgBox;
                msgBox.setText("Unable to download list of songs and presets or read local copy. Installation cannot continue.");
                msgBox.setStandardButtons(QMessageBox::Ok);
                msgBox.setDefaultButton(QMessageBox::Ok);
                msgBox.exec();
                QCoreApplication::exit(1); // Quit, as we can't continue
                return;
            } else {
                xmlData = songsXml.readAll();
            }
        }
        std::tuple<std::map<std::string, std::string>, std::vector<struct Preset>, std::vector<struct Song>> xmlparse = parseSongsXML(xmlData);
        this->songs = std::get<2>(xmlparse);
        this->presets = std::get<1>(xmlparse);
        this->sources = std::get<0>(xmlparse);
        this->nextStage();
        break;
    }
    default:
        break;

    }
}
