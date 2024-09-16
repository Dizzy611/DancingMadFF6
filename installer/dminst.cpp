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

#include "rom_validator.h"

#include <ostream>
#include <iostream>

void ROMValidate(QString filename) {

}

DMInst::DMInst(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::DMInst)
{
    ui->setupUi(this);
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

