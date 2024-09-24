#include "mirrorchecker.h"


MirrorChecker::MirrorChecker(QObject *parent, DMLogger *logger)
    : QObject{parent}
{
    this->logger = logger;
}

void MirrorChecker::setUrl(std::string newUrl) {
    this->urls.push_back(newUrl);
}

void MirrorChecker::setUrls(std::vector<std::string> newUrls) {
    this->urls = newUrls;
}

void MirrorChecker::checkMirrors() {
    this->testdone = false;
    if (!this->urls.empty()) {
        std::string url = this->urls.at(0);
        dmgr = new DownloadManager(QUrl(QString::fromStdString(url)), this);
        connect(dmgr, SIGNAL(downloaded()), this, SLOT(downloadFinished()));
        this->currurl = 0;
    }
}

void MirrorChecker::downloadFinished() {
    QByteArray retHtml = dmgr->downloadedData();
    if (!retHtml.isEmpty()) {
        this->validUrls.push_back(this->urls.at(this->currurl));
    }
    if (!(this->currurl+1 >= this->urls.size())) {
        this->currurl++;
        std::string url = this->urls.at(this->currurl);
        dmgr = new DownloadManager(QUrl(QString::fromStdString(url)), this);
        connect(dmgr, SIGNAL(downloaded()), this, SLOT(downloadFinished()));
    } else {
        // done checking
        this->testdone = true;
    }
}

std::string MirrorChecker::getMirror() {
    if (this->testdone) {
        if (!this->validUrls.empty()) {
            return this->validUrls.at(0);
        } else {
            return "";
        }
    } else {
        return "";
    }
}

std::vector<std::string> MirrorChecker::getMirrors() {
    if (this->testdone) {
        if (!this->validUrls.empty()) {
            return this->validUrls;
        } else {
            return {};
        }
    } else {
        return {};
    }
}

bool MirrorChecker::isDone() {
    return this->testdone;
}
