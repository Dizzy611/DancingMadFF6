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
#include <QDesktopServices>
#include <QWindow>
#include <QSound>

#include "rom_validator.h"
#include "song_parser.h"
#include "ips-patcher-master/IPSPatcherHandler.h"
#include "mirrorchecker.h"
#include "dmlogger.h"
#include "customtrackselection.h"

#include <ostream>
#include <iostream>
#include <sstream>
#include <cstring>

// DEBUG
#define LOG_TO_STDERR true

const char *ff3msuxml = R"(<?xml version="1.0" encoding="UTF-8"?><cartridge region="NTSC">
    <rom>
        <map mode="shadow" address="00-3f:8000-ffff"/>
        <map mode="linear" address="40-7f:0000-ffff"/>
        <map mode="shadow" address="80-bf:8000-ffff"/>
        <map mode="linear" address="c0-ff:0000-ffff"/>
    </rom>
    <ram size="0x2000">
        <map mode="linear" address="20-3f:6000-7fff"/>
        <map mode="linear" address="a0-bf:6000-7fff"/>
        <map mode="linear" address="70-7f:0000-7fff"/>
    </ram>
  <msu1>
    <map address="00-3f:2000-2007"/>
        <map address="80-bf:2000-2007"/>
    <mmio>
      <map address="00-3f:2000-2007"/>
      <map address="80-bf:2000-2007"/>
    </mmio>
  </msu1>
</cartridge>
)";

DMInst::DMInst(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::DMInst) {
    setWindowIcon(QIcon("./kefka-16x16.png"));

    this->mc = new MirrorChecker(this, this->logger);
    this->logger = new DMLogger("./install.log", LOG_TO_STDERR);
    this->logger->doLog("Dancing Mad installer (DanceMonkey alpha) loaded...");

    QUrl mirrorsUrl(MIRRORS_URL);
    dmgr = new DownloadManager(mirrorsUrl, this, this->logger);
    this->gostage = 0;
    connect(dmgr, SIGNAL(downloaded()), this, SLOT(downloadFinished()));

    ui->setupUi(this);

    // Set up initial status
    this->findChild<QLabel*>("statusLabel")->setText("Downloading mirror data from GitHub...");


    // Disable browse and go buttons until mirrors and songs are loaded
    this->findChild<QPushButton*>("goButton")->setEnabled(false);
    this->findChild<QPushButton*>("ROMSelectBrowse")->setEnabled(false);

    // Connect custom track selection ok/cancel to update of current selections or reset of custom selections
    connect(&cts, SIGNAL(savedSelections()), this, SLOT(customSelectionSaved()));
    connect(&cts, SIGNAL(rejectedSelections()), this, SLOT(customSelectionRejected()));


}

DMInst::~DMInst()
{
    delete ui;
}

void DMInst::customSelectionSaved() {
    // Change my selections to what's been customized
    if (this->selections != cts.getSelections()) {
        this->selections.clear();
        this->selections = cts.getSelections();
        if (this->customized == false) {
            this->customized = true;
            this->findChild<QLabel*>("customizedLabel")->setText("✅ Soundtrack has been customized. :)");
        }
        std::cout << "DEBUG: Custom selections saved." << std::endl;
    }
    this->show();
}

void DMInst::customSelectionRejected() {
    std::cout << "DEBUG: Custom selections reverted." << std::endl;
    // Reset custom selections to what they were before the user changed them.
    this->cts.setSelections(this->selections);
    this->show();
}

void DMInst::on_ROMSelectBrowse_clicked()
{
    QString filename = QFileDialog::getOpenFileName(this, tr("Choose ROM"), QDir::homePath());
    QLineEdit* selectedfile = this->findChild<QLineEdit*>("ROMSelectLine");
    selectedfile->setText(filename);
}


void DMInst::on_ROMSelectLine_textChanged(const QString &arg1)
{
    struct ROMValid valid_rom = validate_rom(arg1.toStdString(), this->logger);
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

    this->logger->doLog(valid_rom.error_string);
}


void DMInst::on_goButton_clicked()
{
    this->logger->doLog("Reached download stage...");
    if (this->gostage == 2 && !this->selections.empty()) {
        // disable pressing the button twice
        this->findChild<QPushButton*>("goButton")->setEnabled(false);
        this->destdir = QFileDialog::getExistingDirectory(this, tr("Choose destination directory"), QDir::homePath()).toStdString() + "/";
        this->logger->moveLog(this->destdir + "install.log");
        // check if mirror list has been validated and at least one valid mirror has been returned.
        if (mc->isDone()) {
            if (mc->getMirror() != "") {
                QDir directory(QString::fromStdString(this->destdir));
                QStringList existingFiles = directory.entryList(QStringList() << "*.pcm" << "*.PCM",QDir::Files);
                this->findChild<QLabel*>("statusLabel")->setText("Hashing any existing .pcm files in destination directory...");
                this->hashes.clear();
                this->warnings.clear();
                int i = 0;
                this->findChild<QProgressBar*>("downloadProgressBar")->setRange(0, existingFiles.size()-1);
                for (auto & existingFileName : existingFiles) {
                    logger->doLog("DEBUG: Existing file name " + existingFileName.toStdString());
                    // new SHA256 using QCryptographicHash
                    QFile file(QString::fromStdString(this->destdir + existingFileName.toStdString()));
                    file.open(QIODevice::ReadOnly);
                    QCryptographicHash hash(QCryptographicHash::Md5);
                    hash.addData(&file);
                    QByteArray hash_string = hash.result().toHex();
                    file.close();
                    this->hashes.insert({existingFileName.toStdString(), hash_string.toStdString()});
                    i++;
                    this->findChild<QProgressBar*>("downloadProgressBar")->setValue(i);
                }
                this->findChild<QProgressBar*>("downloadProgressBar")->setRange(0,100);
                this->findChild<QProgressBar*>("downloadProgressBar")->setValue(0);

                //std::string selectedmirror = mc->getMirror();
                std::vector<std::string> mirrorList = mc->getMirrors();
                    for (int i = 0; i < songs.size(); i++) {
                        for (auto & pcm : songs[i].pcms) {
                            if (this->selections.contains(i)) {
                                if (this->selections.at(i) != "spc") { // skip download if SPC
                                    std::string uppersource = this->selections.at(i);
                                    std::transform(uppersource.begin(), uppersource.end(), uppersource.begin(), ::toupper);
                                    if (!uppersource.starts_with("X")) {
                                        this->mmsongurls.push_back(buildMirroredUrls(mirrorList, uppersource + "/ff3-" + std::to_string(pcm) + ".pcm.md5sum"));
                                        this->mmsongurls.push_back(buildMirroredUrls(mirrorList, uppersource + "/ff3-" + std::to_string(pcm) + ".pcm"));
                                        //this->songurls.push_back(selectedmirror + uppersource + "/ff3-" + std::to_string(pcm) + ".pcm");
                                    } else {
                                        this->mmsongurls.push_back(buildMirroredUrls(mirrorList, "opera/" + uppersource.substr(1, uppersource.size()) + "/ff3-" + std::to_string(pcm) + ".pcm.md5sum"));
                                        this->mmsongurls.push_back(buildMirroredUrls(mirrorList, "opera/" + uppersource.substr(1, uppersource.size()) + "/ff3-" + std::to_string(pcm) + ".pcm"));
                                        //this->songurls.push_back(selectedmirror + "opera/" + uppersource.substr(1, uppersource.size()) + "/ff3-" + std::to_string(pcm) + ".pcm");
                                    }
                                }
                            }
                        }
                    }
                    // DEBUG
                    this->logger->doLog("SONG URLS:");
                    for (auto & url : mmsongurls) {
                        std::string outstr = "[";
                        for (auto & murl : url) {
                           outstr += murl + ",";
                        }
                        outstr.pop_back();
                        outstr += "]";
                        this->logger->doLog(outstr);
                    }

                    // start the downloads!
                    //QUrl songUrl = QString::fromStdString(songurls.at(0));
                    if (!mmsongurls.empty()) {
                        dmgr = new DownloadManager(mmsongurls.at(0), this);
                        connect(dmgr, SIGNAL(downloaded()), this, SLOT(downloadFinished()));
                        this->currsong = 0;
                        this->findChild<QLabel*>("statusLabel")->setText("Downloading " + QUrl(QString::fromStdString(this->mmsongurls.at(this->currsong)[0])).fileName() + " [1/" + QString::fromStdString(std::to_string(this->mmsongurls.size())) + "] ...");
                        this->logger->doLog("Started download of song 1 of " + std::to_string(this->mmsongurls.size()));
                    } else {
                        // No songs to download, skip to patching.
                        this->nextStage();
                    }

            } else {
                QMessageBox msgBox;
                msgBox.setText("No download mirrors could be contacted. Please try again in 5 minutes. If this error persists, please contact the developer.");
                msgBox.setStandardButtons(QMessageBox::Ok);
                msgBox.setDefaultButton(QMessageBox::Ok);
                msgBox.exec();
                this->findChild<QLabel*>("statusLabel")->setText("ERROR: No valid mirrors found. Try again or report to developer.");
                this->findChild<QPushButton*>("goButton")->setEnabled(true);
            }
        } else {
            this->findChild<QLabel*>("statusLabel")->setText("Still checking for valid mirrors, please wait...");
            this->findChild<QPushButton*>("goButton")->setEnabled(true);
        }
    } else {
        // Not ready to continue.
        return;
    }
}

void DMInst::nextStage() {
    switch(this->gostage) {
    case 0: {
        this->findChild<QLabel*>("statusLabel")->setText("Downloading song and preset lists from GitHub...");
        QUrl xmlUrl(XML_URL);
        dmgr = new DownloadManager(xmlUrl, this, this->logger);
        this->gostage = 1;
        connect(dmgr, SIGNAL(downloaded()), this, SLOT(downloadFinished()));
        break;
    }
    case 1: {
        this->logger->doLog("Reached pre-download stage...");
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

        // Populate customized soundtrack dropdowns
        this->cts.setSources(this->sources);
        this->cts.setSongs(this->songs);

        this->gostage = 2;

        // DEBUG
        this->logger->doLog("MIRROR LIST:");
        for (auto & element : this->mirrors) {
            this->logger->doLog("\t" + element);
        }

        this->findChild<QLabel*>("statusLabel")->setText("Waiting on user... Select your ROM, soundtrack, and patches and press GO when ready!");
        this->findChild<QPushButton*>("ROMSelectBrowse")->setEnabled(true);
        break;
    }
    case 2: {
        this->logger->doLog("Reached patching stage...");
        this->findChild<QLabel*>("statusLabel")->setText("Downloading patches...");
        QUrl patchUrl(PATCH_URL);
        dmgr = new DownloadManager(patchUrl, this, this->logger);
        this->gostage = 3;
        connect(dmgr, SIGNAL(downloaded()), this, SLOT(downloadFinished()));
        break;
    }
    case 3: {
        this->logger->doLog("Reached optional patch stage...");
        // check if any optional patches have been selected
        bool twue = this->findChild<QCheckBox*>("patchCheck_1")->checkState();
        bool mp   = this->findChild<QCheckBox*>("patchCheck_2")->checkState();
        bool csr  = this->findChild<QCheckBox*>("patchCheck_3")->checkState();
        if ((!twue) && (!mp) && (!csr)) {
            this->gostage = 4;
            this->nextStage();
            break;
        } else {
            //std::string selectedmirror = this->mc->getMirror(); // if we got this far, we should have at least one valid mirror, so testing is not necessary (song download is necessary first)
            std::vector<std::string> mirrorList = mc->getMirrors();
            if (twue) {
                this->mmoptpatchqueue.push_back(buildMirroredUrls(mirrorList, "contrib/twue.ips"));
            }
            if (mp && csr) {
                this->mmoptpatchqueue.push_back(buildMirroredUrls(mirrorList, "contrib/mplayer-csr-main-nh.ips"));
            } else if (mp) {
                this->mmoptpatchqueue.push_back(buildMirroredUrls(mirrorList, "contrib/mplayer-main-nh.ips"));
            }
            if (csr) {
                this->mmoptpatchqueue.push_back(buildMirroredUrls(mirrorList, "contrib/CSR/csr.ips"));
                this->mmoptpatchqueue.push_back(buildMirroredUrls(mirrorList, "contrib/CSR/ff3-90.pcm"));
                this->mmoptpatchqueue.push_back(buildMirroredUrls(mirrorList, "contrib/CSR/ff3-91.pcm"));
                this->mmoptpatchqueue.push_back(buildMirroredUrls(mirrorList, "contrib/CSR/ff3-92.pcm"));
                this->mmoptpatchqueue.push_back(buildMirroredUrls(mirrorList, "contrib/CSR/ff3-93.pcm"));
            }
            dmgr = new DownloadManager(this->mmoptpatchqueue.at(0), this);
            connect(dmgr, SIGNAL(downloaded()), this, SLOT(downloadFinished()));
            this->curropt = 0;
            this->gostage = 4;
            this->findChild<QLabel*>("statusLabel")->setText("Downloading " + QUrl(QString::fromStdString(this->mmoptpatchqueue.at(this->curropt)[0])).fileName() + " ...");
        }
        break;
    }
    case 4:
        if(!this->warnings.empty()) {
            std::string boxString = "Unable to download the following paths from any mirror. Please try again in 5 minutes. If this error persists, please contact the developer.\n\n";
            for (auto & warning : this->warnings) {
                boxString += warning + "\n";
            }
            QMessageBox msgBox;
            msgBox.setText(QString::fromStdString(boxString));
            msgBox.setStandardButtons(QMessageBox::Ok);
            msgBox.setDefaultButton(QMessageBox::Ok);
            msgBox.exec();
        }
        this->findChild<QLabel*>("statusLabel")->setText("Finished! You may quit the installer or do another install at this time.");
        this->findChild<QPushButton*>("goButton")->setEnabled(true);
        this->gostage = 2;
        this->mmsongurls.clear();
        this->optpatchqueue.clear();
        QSound::play("kefkalaugh.wav");
        this->findChild<QProgressBar*>("downloadProgressBar")->setRange(0, 100);
        this->findChild<QProgressBar*>("downloadProgressBar")->setValue(100);
    default:
        break;
    }
}

void DMInst::downloadFinished() {
    switch(this->gostage) {
    case 0: {
        this->logger->doLog("Reached mirror setting stage...");
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
        mc->setUrls(this->mirrors);
        mc->checkMirrors();
        this->findChild<QProgressBar*>("downloadProgressBar")->setRange(0, 100);
        this->findChild<QProgressBar*>("downloadProgressBar")->setValue(0);
        this->nextStage();
        break;
    }
    case 1: {
        this->logger->doLog("Reached song data setting stage...");
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
        std::tuple<std::map<std::string, std::string>, std::vector<struct Preset>, std::vector<struct Song>> xmlparse = parseSongsXML(xmlData, this->logger);
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
            std::string warnString = this->mmsongurls.at(this->currsong)[0];
            warnString = warnString.substr(warnString.find("ff6data/")+8);
            msgBox.setText("WARNING: Unable to download " + QString::fromStdString(warnString));
            msgBox.setStandardButtons(QMessageBox::Ok);
            msgBox.setDefaultButton(QMessageBox::Ok);
            msgBox.exec();
            this->warnings.push_back(warnString);
        } else {
            if (this->mmsongurls.at(this->currsong)[0].ends_with("md5sum")) {
                std::string matchFile = QUrl(QString::fromStdString(this->mmsongurls.at(this->currsong)[0])).fileName().toStdString();
                matchFile.erase(matchFile.size()-7);
                if (this->hashes.contains(matchFile)) {
                        this->logger->doLog("HASH CHECK: Existing:" + this->hashes.at(matchFile) + ", Remote:" + songData.toStdString().substr(0, songData.toStdString().find(' ')));
                    if (this->hashes.at(matchFile) == songData.toStdString().substr(0, songData.toStdString().find(' '))) {
                        // skip next pcm as we've already got it
                        if (this->currsong+1 < this->mmsongurls.size()) {
                            this->currsong++;
                        }
                    }
                }
            } else {
                QFile file(QString::fromStdString(this->destdir + QUrl(QString::fromStdString(this->mmsongurls.at(this->currsong)[0])).fileName().toStdString()));
                file.open(QIODevice::WriteOnly);
                file.write(songData);
                file.close();
            }
        }
        if (this->currsong+1 >= this->mmsongurls.size()) {
            this->findChild<QProgressBar*>("downloadProgressBar")->setRange(0, 100);
            this->findChild<QProgressBar*>("downloadProgressBar")->setValue(0);
            this->nextStage();
            break;
        } else {
            // next song please!
            this->currsong++;
            if (QUrl(QString::fromStdString(this->mmsongurls.at(this->currsong)[0])).fileName().endsWith("md5sum")) {
                std::string checkFile = QUrl(QString::fromStdString(this->mmsongurls.at(this->currsong)[0])).fileName().toStdString();
                checkFile.erase(checkFile.size()-7);
                this->findChild<QLabel*>("statusLabel")->setText("Skipping " + QString::fromStdString(checkFile) + " if it matches remote hash...");
            } else {
                this->findChild<QLabel*>("statusLabel")->setText("Downloading " + QUrl(QString::fromStdString(this->mmsongurls.at(this->currsong)[0])).fileName() + " [" + QString::fromStdString(std::to_string(this->currsong+1)) + "/" + QString::fromStdString(std::to_string(this->mmsongurls.size())) + "] ...");
                this->logger->doLog("Started download of song " + std::to_string(this->currsong+1) + " of " + std::to_string(this->mmsongurls.size()));
            }

            //QUrl songUrl = QString::fromStdString(songurls.at(this->currsong));
            dmgr = new DownloadManager(mmsongurls.at(this->currsong), this);
            connect(dmgr, SIGNAL(downloaded()), this, SLOT(downloadFinished()));
        }
        this->findChild<QProgressBar*>("downloadProgressBar")->setRange(0, 100);
        this->findChild<QProgressBar*>("downloadProgressBar")->setValue(0);
        break;
    }
    case 3: {
        this->logger->doLog("Reached patch downloaded stage...");
        QByteArray patchData = dmgr->downloadedData();
        if (patchData.isEmpty()) {
            // patch data failed to download for one reason or another. Try local copy (potentially out of date)
            QFile patchFile(DATA_PATH "/ff3msu.ips");
            if(!patchFile.open(QIODevice::ReadOnly)) {
                QMessageBox msgBox;
                msgBox.setText("Unable to download main patch or find local copy. Installation cannot continue.");
                msgBox.setStandardButtons(QMessageBox::Ok);
                msgBox.setDefaultButton(QMessageBox::Ok);
                msgBox.exec();
                QCoreApplication::exit(1); // Quit, as we can't continue
                break;
                return;
            } else {
                QMessageBox msgBox;
                msgBox.setText("Warning: Using local copy of patch, possibly out of date.");
                msgBox.setStandardButtons(QMessageBox::Ok);
                msgBox.setDefaultButton(QMessageBox::Ok);
                msgBox.exec();
                patchData = patchFile.readAll();
                patchFile.close();
            }
        }
        this->findChild<QLabel*>("statusLabel")->setText("Patching ROM...");
        this->findChild<QProgressBar*>("downloadProgressBar")->setRange(0, 100);
        this->findChild<QProgressBar*>("downloadProgressBar")->setValue(0);
        QFile file(QString::fromStdString(this->destdir) + "ff3msu.ips");
        file.open(QIODevice::WriteOnly);
        file.write(patchData);
        file.close();
        this->findChild<QProgressBar*>("downloadProgressBar")->setValue(50);
        IPSPatcherHandler* patcher = new IPSPatcherHandler();
        patcher->applyPatch((this->destdir + "ff3msu.ips").c_str(), this->findChild<QLineEdit*>("ROMSelectLine")->text().toStdString().c_str(), (this->destdir + "ff3.sfc").c_str());
        QDir dir(QString::fromStdString(this->destdir));
        dir.remove(QString::fromStdString("ff3msu.ips"));
        this->findChild<QProgressBar*>("downloadProgressBar")->setValue(100);
        this->findChild<QLabel*>("statusLabel")->setText("ROM patched.");
        // create empty .msu file
        QFile msufile(QString::fromStdString(this->destdir) + "ff3.msu");
        msufile.open(QIODevice::WriteOnly);
        msufile.close();
        // create ff3.xml file for bsnes
        QFile ff3xmlfile(QString::fromStdString(this->destdir) + "ff3.xml");
        ff3xmlfile.open(QIODevice::WriteOnly);
        ff3xmlfile.write(ff3msuxml);
        ff3xmlfile.close();
        this->nextStage();
        break;
    }
    case 4: {
        QByteArray optData = dmgr->downloadedData();
        if (optData.isEmpty()) {
            // optional patch data failed to download, warn user but continue
            QMessageBox msgBox;
            std::string warnString = this->mmoptpatchqueue.at(this->curropt)[0];
            warnString = warnString.substr(warnString.find("ff6data/")+8);
            msgBox.setText("WARNING: Unable to download " + QString::fromStdString(warnString));
            msgBox.setStandardButtons(QMessageBox::Ok);
            msgBox.setDefaultButton(QMessageBox::Ok);
            msgBox.exec();
            this->warnings.push_back(warnString);
        } else {
            QFile file(QString::fromStdString(this->destdir + QUrl(QString::fromStdString(this->mmoptpatchqueue.at(this->curropt)[0])).fileName().toStdString()));
            this->findChild<QProgressBar*>("downloadProgressBar")->setRange(0, 100);
            this->findChild<QProgressBar*>("downloadProgressBar")->setValue(0);
            file.open(QIODevice::WriteOnly);
            file.write(optData);
            file.close();
            if (QUrl(QString::fromStdString(this->mmoptpatchqueue.at(this->curropt)[0])).fileName().toStdString().ends_with(".ips")) {
                this->findChild<QLabel*>("statusLabel")->setText("Patching with optional patch...");
                this->findChild<QProgressBar*>("downloadProgressBar")->setValue(50);
                IPSPatcherHandler* patcher = new IPSPatcherHandler();
                patcher->applyPatch((this->destdir + QUrl(QString::fromStdString(this->mmoptpatchqueue.at(this->curropt)[0])).fileName().toStdString()).c_str(), (this->destdir + "ff3.sfc").c_str(), (this->destdir + "ff3.sfc").c_str());
                this->findChild<QProgressBar*>("downloadProgressBar")->setValue(100);
                QDir dir(QString::fromStdString(this->destdir));
                dir.remove(QUrl(QString::fromStdString(this->mmoptpatchqueue.at(this->curropt)[0])).fileName());
            } else {
                this->findChild<QProgressBar*>("downloadProgressBar")->setValue(100);
            }
        }
        if (this->curropt+1 >= this->mmoptpatchqueue.size()) {
            this->findChild<QProgressBar*>("downloadProgressBar")->setRange(0, 100);
            this->findChild<QProgressBar*>("downloadProgressBar")->setValue(0);
            this->nextStage();
            break;
        } else {
            // next patch please
            this->curropt++;
            this->findChild<QLabel*>("statusLabel")->setText("Downloading " + QUrl(QString::fromStdString(this->mmoptpatchqueue.at(this->curropt)[0])).fileName() + " ...");
            dmgr = new DownloadManager(mmoptpatchqueue.at(this->curropt), this);
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
    this->logger->doLog("SELECTION INDEX: " + std::to_string(index));

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
    this->logger->doLog("SELECTIONS:");
    for (auto & selection : this->selections) {
        this->logger->doLog(this->songs[selection.first].name + " [#" + std::to_string(selection.first) + "]: " + selection.second);
    }
    // Update soundtrack selection on customization list
    this->cts.setSelections(this->selections);
    // Update label to show soundtrack is no longer customized if it was
    if (this->customized == true) {
        this->customized = false;
        this->findChild<QLabel*>("customizedLabel")->setText("Soundtrack has not been customized.");
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
    // Update soundtrack selection on customization list
    this->cts.setSelections(this->selections);
}


void DMInst::on_actionContact_Info_About_triggered()
{
    QMessageBox msgBox;
    msgBox.setTextFormat(Qt::RichText);
    msgBox.setWindowTitle("About/Contact...");
    msgBox.setText("Dancing Mad MSU-1 is by Dylan \"Dizzy\" O'Malley-Morrison &lt;dizzy@domad.science&gt;, Copyright (C)2017-2024, licensed under the <a href=\"https://raw.githubusercontent.com/Dizzy611/DancingMadFF6/refs/heads/master/LICENSE\">BSD 2-clause license.</a><br /><br />\"Final Fantasy\",\"Final Fantasy III\", and \"Final Fantasy VI\" are registered trademarks of Square Enix Holdings Co., Ltd, hereafter \"Square Enix\". This is NOT a licensed product of Square Enix. The developers are not affiliated with or sponsored by Square Enix or any other rights holders.<br /><br />Issues? Contact Dizzy on Discord at <a href=\"https://discord.gg/ynZkNnK\">https://discord.gg/ynZkNnK</a>, open an issue on GitHub at <a href=\"https://github.com/Dizzy611/DancingMadFF6/issues\">https://github.com/Dizzy611/DancingMadFF6/issues</a>, or contact me by email at <a href=\"mailto:dizzy@domad.science.\">dizzy@domad.science</a>");
    msgBox.setStandardButtons(QMessageBox::Ok);
    msgBox.setDefaultButton(QMessageBox::Ok);
    msgBox.exec();
}



void DMInst::on_actionJoin_our_Discord_triggered()
{
    QDesktopServices::openUrl(QUrl("https://discord.gg/ynZkNnK"));
}


void DMInst::on_actionGitHub_Issue_Tracker_triggered()
{
    QDesktopServices::openUrl(QUrl("https://github.com/Dizzy611/DancingMadFF6/issues"));
}


void DMInst::on_customizationButton_clicked()
{

    this->cts.show();
    this->hide();

}

