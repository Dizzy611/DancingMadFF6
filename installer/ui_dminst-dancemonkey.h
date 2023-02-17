/********************************************************************************
** Form generated from reading UI file 'dminst-dancemonkeyIUmPXM.ui'
**
** Created by: Qt User Interface Compiler version 5.15.8
**
** WARNING! All changes made in this file will be lost when recompiling UI file!
********************************************************************************/

#ifndef DMINST_2D_DANCEMONKEYIUMPXM_H
#define DMINST_2D_DANCEMONKEYIUMPXM_H

#include <QtCore/QVariant>
#include <QtWidgets/QApplication>
#include <QtWidgets/QCheckBox>
#include <QtWidgets/QComboBox>
#include <QtWidgets/QDialog>
#include <QtWidgets/QFrame>
#include <QtWidgets/QGridLayout>
#include <QtWidgets/QHBoxLayout>
#include <QtWidgets/QLabel>
#include <QtWidgets/QLineEdit>
#include <QtWidgets/QProgressBar>
#include <QtWidgets/QPushButton>
#include <QtWidgets/QVBoxLayout>
#include <QtWidgets/QWidget>

QT_BEGIN_NAMESPACE

class Ui_danceMonkeyDlg
{
public:
    QWidget *verticalLayoutWidget;
    QVBoxLayout *mainLayout;
    QLabel *stepLabel_1;
    QHBoxLayout *ROMLayout;
    QLabel *ROMSelectLabel;
    QLineEdit *ROMSelectLine;
    QPushButton *ROMSelectBrowse;
    QFrame *ROMSeperator;
    QLabel *stepLabel_2;
    QHBoxLayout *soundtrackLayout;
    QLabel *soundtrackSelectLabel;
    QComboBox *soundtrackSelectBox;
    QFrame *soundtrackSeperator;
    QLabel *stepLabel_3;
    QHBoxLayout *operaLayout;
    QLabel *operaSelectLabel;
    QComboBox *operaSelectBox;
    QFrame *operaSeperator;
    QLabel *stepLabel_4;
    QHBoxLayout *customizeLayout;
    QLabel *customizationLabel;
    QPushButton *customizationButton;
    QFrame *customizeSeperator;
    QLabel *stepLabel_5;
    QHBoxLayout *patchLayout;
    QLabel *patchesSelectLabel;
    QGridLayout *patchInnerLayout;
    QCheckBox *patchCheck_1;
    QCheckBox *patchCheck_2;
    QCheckBox *patchCheck_3;
    QFrame *patchSeperator;
    QLabel *stepLabel_6;
    QPushButton *goButton;
    QFrame *goSeperator;
    QProgressBar *downloadProgressBar;
    QLabel *statusLabel;

    void setupUi(QDialog *danceMonkeyDlg)
    {
        if (danceMonkeyDlg->objectName().isEmpty())
            danceMonkeyDlg->setObjectName(QString::fromUtf8("danceMonkeyDlg"));
        danceMonkeyDlg->resize(529, 576);
        verticalLayoutWidget = new QWidget(danceMonkeyDlg);
        verticalLayoutWidget->setObjectName(QString::fromUtf8("verticalLayoutWidget"));
        verticalLayoutWidget->setGeometry(QRect(19, 19, 491, 538));
        mainLayout = new QVBoxLayout(verticalLayoutWidget);
        mainLayout->setObjectName(QString::fromUtf8("mainLayout"));
        mainLayout->setContentsMargins(0, 0, 0, 0);
        stepLabel_1 = new QLabel(verticalLayoutWidget);
        stepLabel_1->setObjectName(QString::fromUtf8("stepLabel_1"));
        QFont font;
        font.setFamily(QString::fromUtf8("Sans Serif"));
        font.setPointSize(14);
        stepLabel_1->setFont(font);

        mainLayout->addWidget(stepLabel_1);

        ROMLayout = new QHBoxLayout();
        ROMLayout->setObjectName(QString::fromUtf8("ROMLayout"));
        ROMSelectLabel = new QLabel(verticalLayoutWidget);
        ROMSelectLabel->setObjectName(QString::fromUtf8("ROMSelectLabel"));

        ROMLayout->addWidget(ROMSelectLabel);

        ROMSelectLine = new QLineEdit(verticalLayoutWidget);
        ROMSelectLine->setObjectName(QString::fromUtf8("ROMSelectLine"));

        ROMLayout->addWidget(ROMSelectLine);

        ROMSelectBrowse = new QPushButton(verticalLayoutWidget);
        ROMSelectBrowse->setObjectName(QString::fromUtf8("ROMSelectBrowse"));

        ROMLayout->addWidget(ROMSelectBrowse);


        mainLayout->addLayout(ROMLayout);

        ROMSeperator = new QFrame(verticalLayoutWidget);
        ROMSeperator->setObjectName(QString::fromUtf8("ROMSeperator"));
        ROMSeperator->setFrameShape(QFrame::HLine);
        ROMSeperator->setFrameShadow(QFrame::Sunken);

        mainLayout->addWidget(ROMSeperator);

        stepLabel_2 = new QLabel(verticalLayoutWidget);
        stepLabel_2->setObjectName(QString::fromUtf8("stepLabel_2"));
        stepLabel_2->setFont(font);

        mainLayout->addWidget(stepLabel_2);

        soundtrackLayout = new QHBoxLayout();
        soundtrackLayout->setObjectName(QString::fromUtf8("soundtrackLayout"));
        soundtrackSelectLabel = new QLabel(verticalLayoutWidget);
        soundtrackSelectLabel->setObjectName(QString::fromUtf8("soundtrackSelectLabel"));
        QSizePolicy sizePolicy(QSizePolicy::Minimum, QSizePolicy::Minimum);
        sizePolicy.setHorizontalStretch(0);
        sizePolicy.setVerticalStretch(0);
        sizePolicy.setHeightForWidth(soundtrackSelectLabel->sizePolicy().hasHeightForWidth());
        soundtrackSelectLabel->setSizePolicy(sizePolicy);
        soundtrackSelectLabel->setAlignment(Qt::AlignLeading|Qt::AlignLeft|Qt::AlignVCenter);

        soundtrackLayout->addWidget(soundtrackSelectLabel);

        soundtrackSelectBox = new QComboBox(verticalLayoutWidget);
        soundtrackSelectBox->addItem(QString());
        soundtrackSelectBox->addItem(QString());
        soundtrackSelectBox->addItem(QString());
        soundtrackSelectBox->addItem(QString());
        soundtrackSelectBox->addItem(QString());
        soundtrackSelectBox->addItem(QString());
        soundtrackSelectBox->addItem(QString());
        soundtrackSelectBox->addItem(QString());
        soundtrackSelectBox->addItem(QString());
        soundtrackSelectBox->addItem(QString());
        soundtrackSelectBox->addItem(QString());
        soundtrackSelectBox->setObjectName(QString::fromUtf8("soundtrackSelectBox"));
        QSizePolicy sizePolicy1(QSizePolicy::Expanding, QSizePolicy::Fixed);
        sizePolicy1.setHorizontalStretch(0);
        sizePolicy1.setVerticalStretch(0);
        sizePolicy1.setHeightForWidth(soundtrackSelectBox->sizePolicy().hasHeightForWidth());
        soundtrackSelectBox->setSizePolicy(sizePolicy1);
        soundtrackSelectBox->setEditable(false);

        soundtrackLayout->addWidget(soundtrackSelectBox);


        mainLayout->addLayout(soundtrackLayout);

        soundtrackSeperator = new QFrame(verticalLayoutWidget);
        soundtrackSeperator->setObjectName(QString::fromUtf8("soundtrackSeperator"));
        soundtrackSeperator->setFrameShape(QFrame::HLine);
        soundtrackSeperator->setFrameShadow(QFrame::Sunken);

        mainLayout->addWidget(soundtrackSeperator);

        stepLabel_3 = new QLabel(verticalLayoutWidget);
        stepLabel_3->setObjectName(QString::fromUtf8("stepLabel_3"));
        stepLabel_3->setFont(font);

        mainLayout->addWidget(stepLabel_3);

        operaLayout = new QHBoxLayout();
        operaLayout->setObjectName(QString::fromUtf8("operaLayout"));
        operaSelectLabel = new QLabel(verticalLayoutWidget);
        operaSelectLabel->setObjectName(QString::fromUtf8("operaSelectLabel"));
        sizePolicy.setHeightForWidth(operaSelectLabel->sizePolicy().hasHeightForWidth());
        operaSelectLabel->setSizePolicy(sizePolicy);

        operaLayout->addWidget(operaSelectLabel);

        operaSelectBox = new QComboBox(verticalLayoutWidget);
        operaSelectBox->addItem(QString());
        operaSelectBox->addItem(QString());
        operaSelectBox->addItem(QString());
        operaSelectBox->addItem(QString());
        operaSelectBox->addItem(QString());
        operaSelectBox->addItem(QString());
        operaSelectBox->addItem(QString());
        operaSelectBox->addItem(QString());
        operaSelectBox->addItem(QString());
        operaSelectBox->addItem(QString());
        operaSelectBox->addItem(QString());
        operaSelectBox->addItem(QString());
        operaSelectBox->setObjectName(QString::fromUtf8("operaSelectBox"));
        sizePolicy1.setHeightForWidth(operaSelectBox->sizePolicy().hasHeightForWidth());
        operaSelectBox->setSizePolicy(sizePolicy1);

        operaLayout->addWidget(operaSelectBox);


        mainLayout->addLayout(operaLayout);

        operaSeperator = new QFrame(verticalLayoutWidget);
        operaSeperator->setObjectName(QString::fromUtf8("operaSeperator"));
        operaSeperator->setFrameShape(QFrame::HLine);
        operaSeperator->setFrameShadow(QFrame::Sunken);

        mainLayout->addWidget(operaSeperator);

        stepLabel_4 = new QLabel(verticalLayoutWidget);
        stepLabel_4->setObjectName(QString::fromUtf8("stepLabel_4"));
        stepLabel_4->setFont(font);

        mainLayout->addWidget(stepLabel_4);

        customizeLayout = new QHBoxLayout();
        customizeLayout->setObjectName(QString::fromUtf8("customizeLayout"));
        customizationLabel = new QLabel(verticalLayoutWidget);
        customizationLabel->setObjectName(QString::fromUtf8("customizationLabel"));
        sizePolicy.setHeightForWidth(customizationLabel->sizePolicy().hasHeightForWidth());
        customizationLabel->setSizePolicy(sizePolicy);

        customizeLayout->addWidget(customizationLabel);

        customizationButton = new QPushButton(verticalLayoutWidget);
        customizationButton->setObjectName(QString::fromUtf8("customizationButton"));
        sizePolicy1.setHeightForWidth(customizationButton->sizePolicy().hasHeightForWidth());
        customizationButton->setSizePolicy(sizePolicy1);

        customizeLayout->addWidget(customizationButton);


        mainLayout->addLayout(customizeLayout);

        customizeSeperator = new QFrame(verticalLayoutWidget);
        customizeSeperator->setObjectName(QString::fromUtf8("customizeSeperator"));
        customizeSeperator->setFrameShape(QFrame::HLine);
        customizeSeperator->setFrameShadow(QFrame::Sunken);

        mainLayout->addWidget(customizeSeperator);

        stepLabel_5 = new QLabel(verticalLayoutWidget);
        stepLabel_5->setObjectName(QString::fromUtf8("stepLabel_5"));
        stepLabel_5->setFont(font);

        mainLayout->addWidget(stepLabel_5);

        patchLayout = new QHBoxLayout();
        patchLayout->setObjectName(QString::fromUtf8("patchLayout"));
        patchesSelectLabel = new QLabel(verticalLayoutWidget);
        patchesSelectLabel->setObjectName(QString::fromUtf8("patchesSelectLabel"));
        sizePolicy.setHeightForWidth(patchesSelectLabel->sizePolicy().hasHeightForWidth());
        patchesSelectLabel->setSizePolicy(sizePolicy);

        patchLayout->addWidget(patchesSelectLabel);

        patchInnerLayout = new QGridLayout();
        patchInnerLayout->setObjectName(QString::fromUtf8("patchInnerLayout"));
        patchCheck_1 = new QCheckBox(verticalLayoutWidget);
        patchCheck_1->setObjectName(QString::fromUtf8("patchCheck_1"));

        patchInnerLayout->addWidget(patchCheck_1, 0, 0, 1, 1);

        patchCheck_2 = new QCheckBox(verticalLayoutWidget);
        patchCheck_2->setObjectName(QString::fromUtf8("patchCheck_2"));

        patchInnerLayout->addWidget(patchCheck_2, 1, 0, 1, 1);

        patchCheck_3 = new QCheckBox(verticalLayoutWidget);
        patchCheck_3->setObjectName(QString::fromUtf8("patchCheck_3"));

        patchInnerLayout->addWidget(patchCheck_3, 2, 0, 1, 1);


        patchLayout->addLayout(patchInnerLayout);


        mainLayout->addLayout(patchLayout);

        patchSeperator = new QFrame(verticalLayoutWidget);
        patchSeperator->setObjectName(QString::fromUtf8("patchSeperator"));
        patchSeperator->setFrameShape(QFrame::HLine);
        patchSeperator->setFrameShadow(QFrame::Sunken);

        mainLayout->addWidget(patchSeperator);

        stepLabel_6 = new QLabel(verticalLayoutWidget);
        stepLabel_6->setObjectName(QString::fromUtf8("stepLabel_6"));
        stepLabel_6->setFont(font);

        mainLayout->addWidget(stepLabel_6);

        goButton = new QPushButton(verticalLayoutWidget);
        goButton->setObjectName(QString::fromUtf8("goButton"));
        QFont font1;
        font1.setPointSize(14);
        goButton->setFont(font1);

        mainLayout->addWidget(goButton);

        goSeperator = new QFrame(verticalLayoutWidget);
        goSeperator->setObjectName(QString::fromUtf8("goSeperator"));
        goSeperator->setFrameShape(QFrame::HLine);
        goSeperator->setFrameShadow(QFrame::Sunken);

        mainLayout->addWidget(goSeperator);

        downloadProgressBar = new QProgressBar(verticalLayoutWidget);
        downloadProgressBar->setObjectName(QString::fromUtf8("downloadProgressBar"));
        downloadProgressBar->setValue(0);

        mainLayout->addWidget(downloadProgressBar);

        statusLabel = new QLabel(verticalLayoutWidget);
        statusLabel->setObjectName(QString::fromUtf8("statusLabel"));
        statusLabel->setAlignment(Qt::AlignCenter);

        mainLayout->addWidget(statusLabel);


        retranslateUi(danceMonkeyDlg);

        soundtrackSelectBox->setCurrentIndex(1);
        operaSelectBox->setCurrentIndex(0);


        QMetaObject::connectSlotsByName(danceMonkeyDlg);
    } // setupUi

    void retranslateUi(QDialog *danceMonkeyDlg)
    {
        danceMonkeyDlg->setWindowTitle(QCoreApplication::translate("danceMonkeyDlg", "Dancing Mad Installer", nullptr));
        stepLabel_1->setText(QCoreApplication::translate("danceMonkeyDlg", "Step 1", nullptr));
        ROMSelectLabel->setText(QCoreApplication::translate("danceMonkeyDlg", "Select your ROM: ", nullptr));
        ROMSelectBrowse->setText(QCoreApplication::translate("danceMonkeyDlg", "Browse", nullptr));
        stepLabel_2->setText(QCoreApplication::translate("danceMonkeyDlg", "Step 2", nullptr));
        soundtrackSelectLabel->setText(QCoreApplication::translate("danceMonkeyDlg", "Select your Base Soundtrack:", nullptr));
        soundtrackSelectBox->setItemText(0, QCoreApplication::translate("danceMonkeyDlg", "Developer's Recommendation", "Recommended"));
        soundtrackSelectBox->setItemText(1, QCoreApplication::translate("danceMonkeyDlg", "Pixel Remaster Soundtrack", nullptr));
        soundtrackSelectBox->setItemText(2, QCoreApplication::translate("danceMonkeyDlg", "Matthew Valenti's Synthetic Origins", nullptr));
        soundtrackSelectBox->setItemText(3, QCoreApplication::translate("danceMonkeyDlg", "FinalFanTim's Arrangements", nullptr));
        soundtrackSelectBox->setItemText(4, QCoreApplication::translate("danceMonkeyDlg", "Sean Schafianski's FFVI Remastered", nullptr));
        soundtrackSelectBox->setItemText(5, QCoreApplication::translate("danceMonkeyDlg", "OCRemix Balance & Ruin", nullptr));
        soundtrackSelectBox->setItemText(6, QCoreApplication::translate("danceMonkeyDlg", "Kara Comparetti's Piano Soundtrack", nullptr));
        soundtrackSelectBox->setItemText(7, QCoreApplication::translate("danceMonkeyDlg", "OCRemix Balance & Ruin (qwertymodo loops)", nullptr));
        soundtrackSelectBox->setItemText(8, QCoreApplication::translate("danceMonkeyDlg", "ChrystalChameleon's Orchestrated", nullptr));
        soundtrackSelectBox->setItemText(9, QCoreApplication::translate("danceMonkeyDlg", "Official Soundtrack", nullptr));
        soundtrackSelectBox->setItemText(10, QCoreApplication::translate("danceMonkeyDlg", "None/SPC", nullptr));

        soundtrackSelectBox->setCurrentText(QCoreApplication::translate("danceMonkeyDlg", "Pixel Remaster Soundtrack", nullptr));
        soundtrackSelectBox->setPlaceholderText(QString());
        stepLabel_3->setText(QCoreApplication::translate("danceMonkeyDlg", "Step 3 ", nullptr));
        operaSelectLabel->setText(QCoreApplication::translate("danceMonkeyDlg", "Select your Opera:", nullptr));
        operaSelectBox->setItemText(0, QCoreApplication::translate("danceMonkeyDlg", "SPC/Do Not Download (No MSU-1)", nullptr));
        operaSelectBox->setItemText(1, QCoreApplication::translate("danceMonkeyDlg", "OST (No Voices)", nullptr));
        operaSelectBox->setItemText(2, QCoreApplication::translate("danceMonkeyDlg", "The Black Mages (Japanese)", nullptr));
        operaSelectBox->setItemText(3, QCoreApplication::translate("danceMonkeyDlg", "Game Music Concert 4 (Japanese)", nullptr));
        operaSelectBox->setItemText(4, QCoreApplication::translate("danceMonkeyDlg", "Distant Worlds (English)", nullptr));
        operaSelectBox->setItemText(5, QCoreApplication::translate("danceMonkeyDlg", "More Friends: Music From Final Fantasy (English)", nullptr));
        operaSelectBox->setItemText(6, QCoreApplication::translate("danceMonkeyDlg", "Pixel Remaster (English)", nullptr));
        operaSelectBox->setItemText(7, QCoreApplication::translate("danceMonkeyDlg", "Pixel Remaster (Japanese)", nullptr));
        operaSelectBox->setItemText(8, QCoreApplication::translate("danceMonkeyDlg", "Pixel Remaster (Italian)", nullptr));
        operaSelectBox->setItemText(9, QCoreApplication::translate("danceMonkeyDlg", "Pixel Remaster (German)", nullptr));
        operaSelectBox->setItemText(10, QCoreApplication::translate("danceMonkeyDlg", "Pixel Remaster (Spanish)", nullptr));
        operaSelectBox->setItemText(11, QCoreApplication::translate("danceMonkeyDlg", "Pixel Remaster (Korean)", nullptr));

        stepLabel_4->setText(QCoreApplication::translate("danceMonkeyDlg", "Step 4 (Optional)", nullptr));
        customizationLabel->setText(QCoreApplication::translate("danceMonkeyDlg", "Customize your Soundtrack:", nullptr));
        customizationButton->setText(QCoreApplication::translate("danceMonkeyDlg", "Customize", nullptr));
        stepLabel_5->setText(QCoreApplication::translate("danceMonkeyDlg", "Step 5 (Optional)", nullptr));
        patchesSelectLabel->setText(QCoreApplication::translate("danceMonkeyDlg", "Select Optional Patches:", nullptr));
        patchCheck_1->setText(QCoreApplication::translate("danceMonkeyDlg", "Ted Woolsey Uncensored Patch", nullptr));
        patchCheck_2->setText(QCoreApplication::translate("danceMonkeyDlg", "Madsiur's Music Player", nullptr));
        patchCheck_3->setText(QCoreApplication::translate("danceMonkeyDlg", "edale2's Cut Songs Restoration", nullptr));
        stepLabel_6->setText(QCoreApplication::translate("danceMonkeyDlg", "Step 6", nullptr));
        goButton->setText(QCoreApplication::translate("danceMonkeyDlg", "GO", nullptr));
        statusLabel->setText(QCoreApplication::translate("danceMonkeyDlg", "Waiting on user... Press GO when ready!", nullptr));
    } // retranslateUi

};

namespace Ui {
    class danceMonkeyDlg: public Ui_danceMonkeyDlg {};
} // namespace Ui

QT_END_NAMESPACE

#endif // DMINST_2D_DANCEMONKEYIUMPXM_H
