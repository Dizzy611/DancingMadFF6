#ifndef DOWNLOADMANAGER_H
#define DOWNLOADMANAGER_H

#include <QObject>
#include <QByteArray>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include "dmlogger.h"

std::vector<std::string> buildMirroredUrls(std::vector<std::string> mirrors, std::string const& path);

class DownloadManager : public QObject
{
    Q_OBJECT
public:
    explicit DownloadManager(QUrl targetUrl, QObject *parent = nullptr, DMLogger *logger = nullptr);
    explicit DownloadManager(std::vector<std::string> const& targetUrls, QObject *parent = nullptr);
    ~DownloadManager() final;
    QByteArray downloadedData() const;

signals:
    void downloaded();
    
private slots:
    void fileDownloaded(QNetworkReply* pReply);
    void fileDownloadedMulti(QNetworkReply* pReply);
    void downloadProgress(qint64 ist, qint64 max) const;

private:
    QNetworkAccessManager m_WebCtrl;
    QByteArray m_DownloadedData;
    DMLogger *logger;
    std::vector<std::string> targetUrls;
    bool multimode;
    qint8 currmirror;
};

#endif // DOWNLOADMANAGER_H
