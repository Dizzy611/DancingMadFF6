#include "customtrackselection.h"
#include "ui_customtrackselection.h"
#include <QScrollArea>
#include <QVBoxLayout>
#include <QLabel>

CustomTrackSelection::CustomTrackSelection(QWidget *parent)
    : QDialog(parent)
    , ui(new Ui::CustomTrackSelection)
{
    ui->setupUi(this);
    this->findChild<QScrollArea*>("scrollArea")->setWidget(this->findChild<QVBoxLayout*>("verticalLayout")->widget());
}

CustomTrackSelection::~CustomTrackSelection()
{
    delete ui;
}

void CustomTrackSelection::setSources(std::map<std::string, std::string> sources) {
    this->sources = sources;
}

void CustomTrackSelection::setSelections(std::map<int, std::string> newSelections) {
    this->selections.clear();
    this->selections = newSelections;
    this->updateSelections();
}

void CustomTrackSelection::setSongs(std::vector<struct Song> songs) {
    int i = 1;
    for (auto & song : songs) {
        if (this->findChild<QLabel*>(QString::fromStdString("labelSong" + std::to_string(i)))) {
            this->findChild<QLabel*>(QString::fromStdString("labelSong" + std::to_string(i)))->setText(QString::fromStdString(song.name));
            for (auto & source : song.sources) {
                if (this->sources.empty()) {
                    this->findChild<QComboBox*>(QString::fromStdString("comboSong" + std::to_string(i)))->addItem(QString::fromStdString(source), QString::fromStdString(source));
                } else {
                    if (this->sources.contains(source)) {
                        this->findChild<QComboBox*>(QString::fromStdString("comboSong" + std::to_string(i)))->addItem(QString::fromStdString(this->sources.at(source)), QString::fromStdString(source));
                    } else {
                        std::cout << "DEBUG:" << source << " not found in sources list, found in " << song.name << "." << std::endl;
                        this->findChild<QComboBox*>(QString::fromStdString("comboSong" + std::to_string(i)))->addItem(QString::fromStdString(source), QString::fromStdString(source));
                    }
                }
            }
            this->findChild<QComboBox*>(QString::fromStdString("comboSong" + std::to_string(i)))->addItem("SPC/Do Not Download", "spc");
        }
        if (!this->selections.empty()) {
            int selecteditem = this->findChild<QComboBox*>(QString::fromStdString("comboSong" + std::to_string(i)))->findData(QString::fromStdString(this->selections.at(i-1)));
            this->findChild<QComboBox*>(QString::fromStdString("comboSong" + std::to_string(i)))->setCurrentIndex(selecteditem);
        }
        i++;
    }
    this->songs = songs;
}

void CustomTrackSelection::updateSelections() {
    int i = 1;
    for (auto & song : this->songs) {
        if (!this->selections.empty()) {
            int selecteditem = this->findChild<QComboBox*>(QString::fromStdString("comboSong" + std::to_string(i)))->findData(QString::fromStdString(this->selections.at(i-1)));
            this->findChild<QComboBox*>(QString::fromStdString("comboSong" + std::to_string(i)))->setCurrentIndex(selecteditem);
        }
        i++;
    }
}

std::map<int, std::string> CustomTrackSelection::getSelections() {
    return this->selections;
}

void CustomTrackSelection::on_buttonBox_accepted()
{
    int i = 1;
    for (auto & song : this->songs) {
        QComboBox* thiscbox = this->findChild<QComboBox*>(QString::fromStdString("comboSong" + std::to_string(i)));
        this->selections[i-1] = thiscbox->currentData().toString().toStdString();
        i++;
    }
    emit(savedSelections());
}



void CustomTrackSelection::on_buttonBox_rejected()
{
    emit(rejectedSelections());
}

