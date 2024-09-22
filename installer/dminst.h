#ifndef DMINST_H
#define DMINST_H

#include <QMainWindow>
#include "downloadmanager.h"
#include "song_parser.h"
#include "mirrorchecker.h"
#include "dmlogger.h"

// data path will depend on whether we're running in an AppImage/a MacOS .app bundle or directly on Linux/Windows. Should be "." for the latter, set as default here.
#define DATA_PATH "."
#define MIRRORS_URL "https://github.com/Dizzy611/DancingMadFF6/raw/refs/heads/master/installer/mirrors.dat"
// final version
//#define XML_URL "https://github.com/Dizzy611/DancingMadFF6/raw/refs/heads/master/installer/songs.xml"
// debug version
#define XML_URL "https://github.com/Dizzy611/DancingMadFF6/raw/refs/heads/dancemonkey-installer-rewrite/installer/songs.xml"
#define PATCH_URL "https://github.com/Dizzy611/DancingMadFF6/raw/refs/heads/master/patch/ff3msu.ips"
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
    std::vector<std::vector<std::string>> mmsongurls;
    std::vector<std::string> optpatchqueue;
    std::vector<std::vector<std::string>> mmoptpatchqueue;
    std::string destdir;
    qint8 currsong;
    qint8 curropt;
    MirrorChecker *mc;
    DMLogger *logger;
    void nextStage();
};
#endif // DMINST_H
