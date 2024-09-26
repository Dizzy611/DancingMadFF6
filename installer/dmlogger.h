#ifndef DMLOGGER_H
#define DMLOGGER_H
#include <string>
#include <iostream>
#include <fstream>

class DMLogger
{
public:
    DMLogger(std::string const& logfilename, bool toStderrSet = false);
    ~DMLogger();
    void closeLog();
    void moveLog(std::string const& logfilename);
    void doLog(std::string const& input);
    void setToStderr(bool toStderrSet);
private:
    std::string logfilename;
    std::ofstream logfile;
    bool toStderr;
};

#endif // DMLOGGER_H
