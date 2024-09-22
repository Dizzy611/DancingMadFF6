#include "downloadmanager.h"
#include <iostream>
#include <QProgressBar>

DownloadManager::DownloadManager(QUrl targetUrl, QObject *parent, DMLogger *logger)
    : QObject{parent} {
    this->logger = logger;
    connect(&m_WebCtrl, SIGNAL(finished(QNetworkReply*)), this, SLOT(fileDownloaded(QNetworkReply*)));
    QNetworkRequest request(targetUrl);
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);

    QNetworkReply* reply = m_WebCtrl.get(request);

    connect(reply, SIGNAL(downloadProgress(qint64, qint64)), this, SLOT(downloadProgress(qint64, qint64)));
}

DownloadManager::~DownloadManager() {}

void DownloadManager::downloadProgress(qint64 ist, qint64 max) {
    if (this->parent()->findChild<QProgressBar*>("downloadProgressBar")) {
        this->parent()->findChild<QProgressBar*>("downloadProgressBar")->setRange(0, max);
        this->parent()->findChild<QProgressBar*>("downloadProgressBar")->setValue(ist);
    }
}

void DownloadManager::fileDownloaded(QNetworkReply* pReply) {
    QVariant test = pReply->attribute(QNetworkRequest::HttpStatusCodeAttribute);
    if (test.isValid()) {
        QString status = test.toString();
        if (this->logger != nullptr) {
            this->logger->doLog("DEBUG: HTTP CODE RECEIVED: " + status.toStdString());
        }
        if (status.toStdString() != "200") {
            // Handle errors in later code by checking if m_DownloadedData QByteArray isEmpty()
            m_DownloadedData = "";
        } else {
            m_DownloadedData = pReply->readAll();
        }
    }
    pReply->deleteLater();
    emit downloaded();
}

QByteArray DownloadManager::downloadedData() const {
    return m_DownloadedData;
}
