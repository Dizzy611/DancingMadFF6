#ifndef CUSTOMTRACKSELECTION_H
#define CUSTOMTRACKSELECTION_H

#include <QDialog>
#include "song_parser.h"

namespace Ui {
class CustomTrackSelection;
}

class CustomTrackSelection : public QDialog
{
    Q_OBJECT

public:
    explicit CustomTrackSelection(QWidget *parent = nullptr);
    ~CustomTrackSelection();
    void setSongs(std::vector<struct Song> songs);
    void setSources(std::map<std::string, std::string> sources);
    void setSelections(std::map<int, std::string> newSelections);
    std::map<int, std::string> getSelections();

private slots:
    void on_buttonBox_accepted();

    void on_buttonBox_rejected();

signals:
    void savedSelections();
    void rejectedSelections();

private:
    Ui::CustomTrackSelection *ui;
    std::map<std::string, std::string> sources;
    std::map<int, std::string> selections;
    std::vector<struct Song> songs;
    void updateSelections();

};

#endif // CUSTOMTRACKSELECTION_H
