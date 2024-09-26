#ifndef DMINST_H
#define DMINST_H

#include <QMainWindow>
#include "downloadmanager.h"
#include "song_parser.h"
#include "mirrorchecker.h"
#include "dmlogger.h"
#include "customtrackselection.h"

// data path will depend on whether we're running in an AppImage/a MacOS .app bundle or directly on Linux/Windows. Should be "." for the latter, set as default here.
const std::string data_path = ".";
const std::string mirrors_url = "https://github.com/Dizzy611/DancingMadFF6/raw/refs/heads/master/installer/mirrors.dat";
const std::string xml_url = "https://github.com/Dizzy611/DancingMadFF6/raw/refs/heads/master/installer/songs.xml";
const std::string patch_url = "https://github.com/Dizzy611/DancingMadFF6/raw/refs/heads/master/patch/ff3msu.ips";


QT_BEGIN_NAMESPACE
namespace Ui {
class DMInst;
}
QT_END_NAMESPACE

class DMInst : public QMainWindow
{
    Q_OBJECT

public:
    explicit DMInst(QWidget *parent = nullptr);
    ~DMInst() final;

private slots:
    void on_ROMSelectBrowse_clicked();

    void on_ROMSelectLine_textChanged(const QString &arg1);

    void on_goButton_clicked();

    void downloadFinished();

    void on_soundtrackSelectBox_currentIndexChanged(int index);

    void on_operaSelectBox_currentIndexChanged(int index);

    void on_actionContact_Info_About_triggered();

    void on_actionJoin_our_Discord_triggered();

    void on_actionGitHub_Issue_Tracker_triggered();

    void on_customizationButton_clicked();

    void customSelectionSaved();

    void customSelectionRejected();

private:
    Ui::DMInst *ui;
    CustomTrackSelection cts;
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
    std::vector<std::string> warnings;
    std::map<std::string, std::string> hashes;
    std::string destdir;
    int currsong;
    qint8 curropt;
    MirrorChecker *mc;
    DMLogger *logger;
    bool customized = false;
    void nextStage();
};
#endif // DMINST_H
