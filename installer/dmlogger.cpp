#include "dmlogger.h"

DMLogger::DMLogger(std::string logfilename, bool toStderr) {
    this->logfilename = logfilename;
    this->logfile = std::ofstream(this->logfilename, std::ios_base::app);
    this->toStderr = toStderr;
}

void DMLogger::moveLog(std::string logfilename) {
    // close current ofstream
    this->logfile.close();

    // copy contents of current log to new log
    std::ifstream src(this->logfilename, std::ios::binary);
    std::ofstream dst(logfilename, std::ios::binary);
    dst << src.rdbuf();

    // close src/dst streams
    src.close();
    dst.close();

    // set current filename and ofstream to new file
    this->logfilename = logfilename;
    this->logfile = std::ofstream(this->logfilename, std::ios_base::app);

    // log change
    this->doLog("Moved log file to" + this->logfilename);

}

void DMLogger::doLog(std::string input) {
    if (this->logfile.is_open()) {
        this->logfile << input << std::endl;
    }
    if (this->toStderr) {
        std::cerr << input << std::endl;
    }

}
void DMLogger::setToStderr(bool toStderr) {
    this->toStderr = toStderr;
}

void DMLogger::closeLog() {
    this->logfile.close();
}

DMLogger::~DMLogger() {
    this->closeLog();
}
