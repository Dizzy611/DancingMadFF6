#ifndef MIRRORCHECKER_H
#define MIRRORCHECKER_H

#include <QObject>
#include <QUrl>
#include "downloadmanager.h"
#include "dmlogger.h"
class MirrorChecker : public QObject
{
    Q_OBJECT
public:
    explicit MirrorChecker(QObject *parent = nullptr, DMLogger *logger = nullptr);
    void setUrl(std::string const& newUrl);
    void setUrls(std::vector<std::string> const& urls);
    void checkMirrors();
    std::string getMirror();
    std::vector<std::string> getMirrors() const;
    bool isDone() const;

private slots:
    void downloadFinished();

private:
    std::vector<std::string> urls;
    qint8 currurl;
    DownloadManager *dmgr;
    std::vector<std::string> validUrls;
    bool testdone = false;
    DMLogger *logger;

};


#endif // MIRRORCHECKER_H
