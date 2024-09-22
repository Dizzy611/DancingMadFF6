#include "downloadmanager.h"
#include <iostream>
#include <QProgressBar>

std::vector<std::string> buildMirroredUrls(std::vector<std::string> mirrors, std::string path) {
    std::vector<std::string> output;
    for (auto & mirror : mirrors) {
        // add a final / if one is missing
        if (!mirror.ends_with("/")) {
            mirror = mirror + "/";
        }
        output.push_back(mirror + path);
    }
    return output;
}

DownloadManager::DownloadManager(QUrl targetUrl, QObject *parent, DMLogger *logger)
    : QObject{parent} {
    this->logger = logger;
    connect(&m_WebCtrl, SIGNAL(finished(QNetworkReply*)), this, SLOT(fileDownloaded(QNetworkReply*)));
    QNetworkRequest request(targetUrl);
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
    request.setTransferTimeout(10000);
    QNetworkReply* reply = m_WebCtrl.get(request);

    connect(reply, SIGNAL(downloadProgress(qint64, qint64)), this, SLOT(downloadProgress(qint64, qint64)));
}

DownloadManager::DownloadManager(std::vector<std::string> targetUrls, QObject *parent, DMLogger *logger)
    : QObject{parent} {
    this->currmirror = 0;
    this->multimode = true;
    this->targetUrls = targetUrls;
    connect(&m_WebCtrl, SIGNAL(finished(QNetworkReply*)), this, SLOT(fileDownloadedMulti(QNetworkReply*)));
    QNetworkRequest request(QUrl(QString::fromStdString(this->targetUrls.at(this->currmirror))));
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
    request.setTransferTimeout(10000);
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

void DownloadManager::fileDownloadedMulti(QNetworkReply* pReply) {
    QVariant test = pReply->attribute(QNetworkRequest::HttpStatusCodeAttribute);
    if (test.isValid()) {
        QString status = test.toString();
        // TODO: figure out why logging breaks with multi-mirror downloads
        //if (this->logger != nullptr) {
        //    this->logger->doLog("DEBUG: HTTP CODE RECEIVED: " + status.toStdString());
        //}
        std::cout << "DEBUG: HTTP CODE RECEIVED: " << status.toStdString() << std::endl;
        std::cout << "Url was " << this->targetUrls.at(this->currmirror) << std::endl;
        if (status.toStdString() != "200") {
            // Try the next url in the list
            this->currmirror++;
            if (this->currmirror < this->targetUrls.size()) {
                std::cout << "Trying " << this->targetUrls.at(this->currmirror) << std::endl;
                QNetworkRequest request(QUrl(QString::fromStdString(this->targetUrls.at(this->currmirror))));
                request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
                request.setTransferTimeout(10000);
                QNetworkReply* reply = m_WebCtrl.get(request);
                connect(reply, SIGNAL(downloadProgress(qint64, qint64)), this, SLOT(downloadProgress(qint64, qint64)));
            } else {
                // Handle errors in later code by checking if m_DownloadedData QByteArray isEmpty()
                m_DownloadedData = "";
                pReply->deleteLater();
                emit downloaded();
            }
        } else {
            m_DownloadedData = pReply->readAll();
            pReply->deleteLater();
            emit downloaded();
        }
    } else {
        std::cout << "DEBUG: Invalid reply to HTTP request" << std::endl;
        std::cout << "Url was " << this->targetUrls.at(this->currmirror) << std::endl;
        // Try the next url in the list
        this->currmirror++;
        if (this->currmirror < this->targetUrls.size()) {
            std::cout << "Trying " << this->targetUrls.at(this->currmirror) << std::endl;
            QNetworkRequest request(QUrl(QString::fromStdString(this->targetUrls.at(this->currmirror))));
            request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
            request.setTransferTimeout(10000);
            QNetworkReply* reply = m_WebCtrl.get(request);
            connect(reply, SIGNAL(downloadProgress(qint64, qint64)), this, SLOT(downloadProgress(qint64, qint64)));
        } else {
            // Handle errors in later code by checking if m_DownloadedData QByteArray isEmpty()
            m_DownloadedData = "";
            pReply->deleteLater();
            emit downloaded();
        }
    }
}

QByteArray DownloadManager::downloadedData() const {
    return m_DownloadedData;
}
