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

void CustomTrackSelection::setSources(std::map<std::string, std::string> const& newSources) {
    this->sources = newSources;
}

void CustomTrackSelection::setSelections(std::map<int, std::string> const& newSelections) {
    this->selections.clear();
    this->selections = newSelections;
    this->updateSelections();
}

void CustomTrackSelection::setSongs(std::vector<struct Song> const& newSongs) {
    int i = 1;
    for (auto & song : newSongs) {
        if (this->findChild<QLabel*>(QString::fromStdString(std::format("labelSong{}",i)))) {
            this->findChild<QLabel*>(QString::fromStdString(std::format("labelSong{}",i)))->setText(QString::fromStdString(song.name));
            for (auto & source : song.sources) {
                if (this->sources.empty()) {
                    this->findChild<QComboBox*>(QString::fromStdString(std::format("comboSong{}",i)))->addItem(QString::fromStdString(source), QString::fromStdString(source));
                } else {
                    if (this->sources.contains(source)) {
                        this->findChild<QComboBox*>(QString::fromStdString(std::format("comboSong{}",i)))->addItem(QString::fromStdString(this->sources.at(source)), QString::fromStdString(source));
                    } else {
                        std::cout << "DEBUG:" << source << " not found in sources list, found in " << song.name << "." << std::endl;
                        this->findChild<QComboBox*>(QString::fromStdString(std::format("comboSong{}",i)))->addItem(QString::fromStdString(source), QString::fromStdString(source));
                    }
                }
            }
            this->findChild<QComboBox*>(QString::fromStdString(std::format("comboSong{}",i)))->addItem("SPC/Do Not Download", "spc");
        }
        if (!this->selections.empty()) {
            int selecteditem = this->findChild<QComboBox*>(QString::fromStdString(std::format("comboSong{}",i)))->findData(QString::fromStdString(this->selections.at(i-1)));
            this->findChild<QComboBox*>(QString::fromStdString(std::format("comboSong{}",i)))->setCurrentIndex(selecteditem);
        }
        i++;
    }
    this->songs = newSongs;
}

void CustomTrackSelection::updateSelections() {
    int i = 1;
    for (auto const & song : this->songs) {
        if (!this->selections.empty()) {
            int selecteditem = this->findChild<QComboBox*>(QString::fromStdString(std::format("comboSong{}",i)))->findData(QString::fromStdString(this->selections.at(i-1)));
            this->findChild<QComboBox*>(QString::fromStdString(std::format("comboSong{}",i)))->setCurrentIndex(selecteditem);
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
    for (auto const & song : this->songs) {
        QComboBox const* thiscbox = this->findChild<QComboBox*>(QString::fromStdString(std::format("comboSong{}",i)));
        this->selections[i-1] = thiscbox->currentData().toString().toStdString();
        i++;
    }
    emit(savedSelections());
}



void CustomTrackSelection::on_buttonBox_rejected()
{
    emit(rejectedSelections());
}

