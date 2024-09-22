#ifndef DOWNLOADMANAGER_H
#define DOWNLOADMANAGER_H

#include <QObject>
#include <QByteArray>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>

class DownloadManager : public QObject
{
    Q_OBJECT
public:
    explicit DownloadManager(QUrl targetUrl, QObject *parent = nullptr);
    virtual ~DownloadManager();
    QByteArray downloadedData() const;

signals:
    void downloaded();
    
private slots:
    void fileDownloaded(QNetworkReply* pReply);
    void downloadProgress(qint64 ist, qint64 max);

private:
    QNetworkAccessManager m_WebCtrl;
    QByteArray m_DownloadedData;
};

#endif // DOWNLOADMANAGER_H
