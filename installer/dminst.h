#ifndef DMINST_H
#define DMINST_H

#include <QMainWindow>
#include "downloadmanager.h"
#include "song_parser.h"

// data path will depend on whether we're running in an AppImage/a MacOS .app bundle or directly on Linux/Windows. Should be "." for the latter, set as default here.
#define DATA_PATH "."
#define MIRRORS_URL "https://github.com/Dizzy611/DancingMadFF6/raw/refs/heads/master/installer/mirrors.dat"
// final version
//#define XML_URL "https://github.com/Dizzy611/DancingMadFF6/raw/refs/heads/master/installer/songs.xml"
// debug version
#define XML_URL "https://github.com/Dizzy611/DancingMadFF6/raw/refs/heads/dancemonkey-installer-rewrite/installer/songs.xml"

QT_BEGIN_NAMESPACE
namespace Ui {
class DMInst;
}
QT_END_NAMESPACE

class DMInst : public QMainWindow
{
    Q_OBJECT

public:
    DMInst(QWidget *parent = nullptr);
    ~DMInst();

private slots:
    void on_ROMSelectBrowse_clicked();

    void on_ROMSelectLine_textChanged(const QString &arg1);

    void on_goButton_clicked();

    void downloadFinished();

    void on_soundtrackSelectBox_currentIndexChanged(int index);

    void on_operaSelectBox_currentIndexChanged(int index);

private:
    Ui::DMInst *ui;
    qint8 gostage;
    DownloadManager *dmgr;
    std::vector<std::string> mirrors;
    std::vector<struct Song> songs;
    std::vector<struct Preset> presets;
    std::map<std::string, std::string> sources;
    std::map<int, std::string> selections;
    std::vector<std::string> songurls;
    qint8 currsong;
    void nextStage();
};
#endif // DMINST_H
