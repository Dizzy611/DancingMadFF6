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
#include "ips-patcher-master/IPSPatcherHandler.h"
#include "mirrorchecker.h"

#include <ostream>
#include <iostream>
#include <sstream>
#include <cstring>



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
    // check if mirror list has been validated and at least one valid mirror has been returned.
    if (mc.isDone()) {
        if (mc.getMirror() != "") {
            std::string selectedmirror = mc.getMirror();
            if (this->gostage == 2 && !this->selections.empty()) {
                for (int i = 0; i < songs.size(); i++) {
                    for (auto & pcm : songs[i].pcms) {
                        if (this->selections.at(i) != "spc") { // skip download if SPC
                            std::string uppersource = this->selections.at(i);
                            std::transform(uppersource.begin(), uppersource.end(), uppersource.begin(), ::toupper);
                            if (!uppersource.starts_with("X")) {
                                this->songurls.push_back(selectedmirror + uppersource + "/ff3-" + std::to_string(pcm) + ".pcm");
                            } else {
                                this->songurls.push_back(selectedmirror + "opera/" + uppersource.substr(1, uppersource.size()) + "/ff3-" + std::to_string(pcm) + ".pcm");
                            }
                        }
                    }
                }
                // DEBUG
                std::cout << "SONG URLS:" << std::endl;
                for (auto & url : songurls) {
                    std::cout << url << std::endl;
                }

                // start the downloads!
                QUrl songUrl = QString::fromStdString(songurls.at(0));
                dmgr = new DownloadManager(songUrl, this);
                connect(dmgr, SIGNAL(downloaded()), this, SLOT(downloadFinished()));
                this->currsong = 0;
                this->findChild<QLabel*>("statusLabel")->setText("Downloading " + QUrl(QString::fromStdString(this->songurls.at(this->currsong))).fileName() + " ...");

            } else {
                // Not ready to continue.
                return;
            }
        } else {
            this->findChild<QLabel*>("statusLabel")->setText("ERROR: No valid mirrors found. Try again or report to developer.");
        }
    } else {
        this->findChild<QLabel*>("statusLabel")->setText("Still checking for valid mirrors, please wait...");
    }

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
            if (element.first.starts_with("x")) {
                this->findChild<QComboBox*>("operaSelectBox")->setItemText(i, QString::fromStdString(element.second));
                i++;
            }
        }

        // messy, but the best way to avoid code duplication: Manually fire off soundtrack/opera selection changed with default index of 0
        this->on_soundtrackSelectBox_currentIndexChanged(0);
        this->on_operaSelectBox_currentIndexChanged(0);

        // TODO: Populate customized soundtrack dropdowns
        this->gostage = 2;

        // DEBUG
        std::cout << "MIRROR LIST:" << std::endl;
        for (auto & element : this->mirrors) {
            std::cout << "\t" << element << std::endl;
        }

        this->findChild<QLabel*>("statusLabel")->setText("Waiting on user... Select your ROM, soundtrack, and patches and press GO when ready!");
        this->findChild<QPushButton*>("ROMSelectBrowse")->setEnabled(true);
        break;
    }
    case 2: {
        this->findChild<QLabel*>("statusLabel")->setText("Downloading patches...");
        QUrl patchUrl(PATCH_URL);
        dmgr = new DownloadManager(patchUrl, this);
        this->gostage = 3;
        connect(dmgr, SIGNAL(downloaded()), this, SLOT(downloadFinished()));
        break;
    }
    case 3: {
        // check if any optional patches have been selected
        bool twue = this->findChild<QCheckBox*>("patchCheck_1")->checkState();
        bool mp   = this->findChild<QCheckBox*>("patchCheck_2")->checkState();
        bool csr  = this->findChild<QCheckBox*>("patchCheck_3")->checkState();
        if ((!twue) && (!mp) && (!csr)) {
            this->gostage = 4;
            this->nextStage();
            break;
        } else {
            std::string selectedmirror = this->mc.getMirror(); // if we got this far, we should have at least one valid mirror, so testing is not necessary (song download is necessary first)
            if (twue) {
                this->optpatchqueue.push_back(selectedmirror + "contrib/twue.ips");
            }
            if (mp && csr) {
                this->optpatchqueue.push_back(selectedmirror + "contrib/mplayer-csr-main-nh.ips");
            } else if (mp) {
                this->optpatchqueue.push_back(selectedmirror + "contrib/mplayer-main-nh.ips");
            }
            if (csr) {
                this->optpatchqueue.push_back(selectedmirror + "contrib/CSR/csr.ips");
                this->optpatchqueue.push_back(selectedmirror + "contrib/CSR/ff3-90.pcm");
                this->optpatchqueue.push_back(selectedmirror + "contrib/CSR/ff3-91.pcm");
                this->optpatchqueue.push_back(selectedmirror + "contrib/CSR/ff3-92.pcm");
                this->optpatchqueue.push_back(selectedmirror + "contrib/CSR/ff3-93.pcm");
            }
            QUrl optUrl = QString::fromStdString(optpatchqueue.at(0));
            dmgr = new DownloadManager(optUrl, this);
            connect(dmgr, SIGNAL(downloaded()), this, SLOT(downloadFinished()));
            this->curropt = 0;
            this->gostage = 4;
            this->findChild<QLabel*>("statusLabel")->setText("Downloading " + QUrl(QString::fromStdString(this->optpatchqueue.at(this->curropt))).fileName() + " ...");
        }
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
            // remove whitespace
            line.erase(std::remove_if(line.begin(), line.end(), ::isspace), line.end());
            this->mirrors.push_back(line);
        }
        // begin test of mirrors to find which are available
        mc.setUrls(this->mirrors);
        mc.checkMirrors();
        this->findChild<QProgressBar*>("downloadProgressBar")->setRange(0, 100);
        this->findChild<QProgressBar*>("downloadProgressBar")->setValue(0);
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
        this->findChild<QProgressBar*>("downloadProgressBar")->setRange(0, 100);
        this->findChild<QProgressBar*>("downloadProgressBar")->setValue(0);
        this->nextStage();
        break;
    }
    case 2: {
        QByteArray songData = dmgr->downloadedData();
        if (songData.isEmpty()) {
            // song data failed to download for one reason or another. TODO: Explain reason in text box, attempt other mirror or allow user to continue.
            QMessageBox msgBox;
            msgBox.setText("Unable to download " + QString::fromStdString(this->songurls.at(this->currsong)) + ". Installation cannot continue.");
            msgBox.setStandardButtons(QMessageBox::Ok);
            msgBox.setDefaultButton(QMessageBox::Ok);
            msgBox.exec();
            QCoreApplication::exit(1); // Quit, as we can't continue
            return;
        } else {
            QFile file(QString::fromStdString("./" + QUrl(QString::fromStdString(this->songurls.at(this->currsong))).fileName().toStdString()));
            file.open(QIODevice::WriteOnly);
            file.write(songData);
            file.close();
        }
        if (this->currsong+1 >= this->songurls.size()) {
            this->findChild<QProgressBar*>("downloadProgressBar")->setRange(0, 100);
            this->findChild<QProgressBar*>("downloadProgressBar")->setValue(0);
            this->nextStage();
            break;
        } else {
            // next song please!
            this->currsong++;
            this->findChild<QLabel*>("statusLabel")->setText("Downloading " + QUrl(QString::fromStdString(this->songurls.at(this->currsong))).fileName() + " ...");
            QUrl songUrl = QString::fromStdString(songurls.at(this->currsong));
            dmgr = new DownloadManager(songUrl, this);
            connect(dmgr, SIGNAL(downloaded()), this, SLOT(downloadFinished()));
        }
        this->findChild<QProgressBar*>("downloadProgressBar")->setRange(0, 100);
        this->findChild<QProgressBar*>("downloadProgressBar")->setValue(0);
        break;
    }
    case 3: {
        QByteArray patchData = dmgr->downloadedData();
        if (patchData.isEmpty()) {
            // patch data failed to download for one reason or another. This is definitely a fatal unless we decide to mirror the patch elsewhere.
            QMessageBox msgBox;
            msgBox.setText("Unable to download main patch. Installation cannot continue.");
            msgBox.setStandardButtons(QMessageBox::Ok);
            msgBox.setDefaultButton(QMessageBox::Ok);
            msgBox.exec();
            QCoreApplication::exit(1); // Quit, as we can't continue
            break;
        }
        this->findChild<QLabel*>("statusLabel")->setText("Patching ROM...");
        this->findChild<QProgressBar*>("downloadProgressBar")->setRange(0, 100);
        this->findChild<QProgressBar*>("downloadProgressBar")->setValue(0);
        QFile file("./ff3msu.ips");
        file.open(QIODevice::WriteOnly);
        file.write(patchData);
        file.close();
        this->findChild<QProgressBar*>("downloadProgressBar")->setValue(50);
        IPSPatcherHandler* patcher = new IPSPatcherHandler();
        patcher->applyPatch("./ff3msu.ips", this->findChild<QLineEdit*>("ROMSelectLine")->text().toStdString().c_str(), "./ff3.sfc");
        this->findChild<QProgressBar*>("downloadProgressBar")->setValue(100);
        this->findChild<QLabel*>("statusLabel")->setText("ROM patched.");
        this->nextStage();
        break;
    }
    case 4: {
        QByteArray optData = dmgr->downloadedData();
        if (optData.isEmpty()) {
            // optional patch data failed to download, warn user but continue
            QMessageBox msgBox;
            msgBox.setText("Unable to download " + QUrl(QString::fromStdString(this->optpatchqueue.at(this->curropt))).fileName() + ". Continuing without...");
            msgBox.setStandardButtons(QMessageBox::Ok);
            msgBox.setDefaultButton(QMessageBox::Ok);
            msgBox.exec();
        } else {
            QFile file(QString::fromStdString("./" + QUrl(QString::fromStdString(this->optpatchqueue.at(this->curropt))).fileName().toStdString()));
            this->findChild<QProgressBar*>("downloadProgressBar")->setRange(0, 100);
            this->findChild<QProgressBar*>("downloadProgressBar")->setValue(0);
            file.open(QIODevice::WriteOnly);
            file.write(optData);
            file.close();
            if (QUrl(QString::fromStdString(this->optpatchqueue.at(this->curropt))).fileName().toStdString().ends_with(".ips")) {
                this->findChild<QLabel*>("statusLabel")->setText("Patching with optional patch...");
                this->findChild<QProgressBar*>("downloadProgressBar")->setValue(50);
                IPSPatcherHandler* patcher = new IPSPatcherHandler();
                patcher->applyPatch(("./" + QUrl(QString::fromStdString(this->optpatchqueue.at(this->curropt))).fileName().toStdString()).c_str(), "./ff3.sfc", "./ff3.sfc");
                this->findChild<QProgressBar*>("downloadProgressBar")->setValue(100);
            } else {
                this->findChild<QProgressBar*>("downloadProgressBar")->setValue(100);
            }
        }
        if (this->curropt+1 >= this->optpatchqueue.size()) {
            this->findChild<QProgressBar*>("downloadProgressBar")->setRange(0, 100);
            this->findChild<QProgressBar*>("downloadProgressBar")->setValue(0);
            this->nextStage();
            break;
        } else {
            // next patch please
            this->curropt++;
            this->findChild<QLabel*>("statusLabel")->setText("Downloading " + QUrl(QString::fromStdString(this->optpatchqueue.at(this->curropt))).fileName() + " ...");
            QUrl optUrl = QString::fromStdString(optpatchqueue.at(this->curropt));
            dmgr = new DownloadManager(optUrl, this);
            connect(dmgr, SIGNAL(downloaded()), this, SLOT(downloadFinished()));
        }
        this->findChild<QProgressBar*>("downloadProgressBar")->setRange(0, 100);
        this->findChild<QProgressBar*>("downloadProgressBar")->setValue(0);
        break;
    }
    default:
        break;

    }
}

void DMInst::on_soundtrackSelectBox_currentIndexChanged(int index)
{
    // DEBUG
    std::cout << "SELECTION INDEX: " << index << std::endl;

    // preserve opera source, if set
    std::string opera_source = "spc";
    if (this->selections.count(31) != 0) {
        opera_source = this->selections.at(31);
    }

    // clear selection map
    this->selections.clear();

    // re-set opera source
    this->selections.insert({31, opera_source});

    if (index < this->presets.size()) {
        struct Preset mypreset = this->presets[index];
        for (auto & source : mypreset.selections) {
            for (int i = 0; i < source.second.size()-1; i+=2) {
                int rangemin = source.second.at(i);
                int rangemax = source.second.at(i+1);
                for (int j = rangemin; j <= rangemax; j++) {
                    // skip opera tracks, these are handled by the other dropdown
                    if (j != 31) {
                        this->selections.insert({j, source.first});
                    }
                }
            }
        }
    } else {
        for (int i = 0; i <= 59; i++) {
            // skip opera tracks, these are handled by the other dropdown
            if (i != 31) {
                // Too high index means SPC/Do Not Download was selected.
                this->selections.insert({i, "spc"});
            }

        }
    }
    // DEBUG
    std::cout << "SELECTIONS:" << std::endl;
    for (auto & selection : this->selections) {
        std::cout << this->songs[selection.first].name << " [#" << selection.first << "]: " << selection.second << std::endl;
    }
}



void DMInst::on_operaSelectBox_currentIndexChanged(int index)
{
    // build map of valid opera sources
    std::map<int, std::string> opera_sources;
    opera_sources.insert({0, "spc"});
    int i = 1;
    for (auto & element : this->sources) {
        if (element.first.starts_with("x")) {
            opera_sources.insert({i, element.first});
            i++;
        }
    }
    // find selected source
    std::string selected_source = opera_sources.at(index);
    // set selected source in selections map
    this->selections[31] = opera_sources.at(index);
}

