#ifndef MIRRORCHECKER_H
#define MIRRORCHECKER_H

#include <QObject>
#include <QUrl>
#include "downloadmanager.h"

class MirrorChecker : public QObject
{
    Q_OBJECT
public:
    explicit MirrorChecker(QObject *parent = nullptr);
    void setUrl(std::string newUrl);
    void setUrls(std::vector<std::string> urls);
    void checkMirrors();
    std::string getMirror();
    std::vector<std::string> getMirrors();
    bool isDone();

private slots:
    void downloadFinished();

private:
    std::vector<std::string> urls;
    qint8 currurl;
    DownloadManager *dmgr;
    std::vector<std::string> validUrls;
    bool testdone = false;

signals:
};


#endif // MIRRORCHECKER_H