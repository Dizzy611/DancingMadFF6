#ifndef DMLOGGER_H
#define DMLOGGER_H
#include <string>
#include <iostream>
#include <fstream>

class DMLogger
{
public:
    DMLogger(std::string logfilename, bool toStderr = false);
    ~DMLogger();
    void closeLog();
    void moveLog(std::string logfilename);
    void doLog(std::string input);
    void setToStderr(bool toStderr);
private:
    std::string logfilename;
    std::ofstream logfile;
    bool toStderr;
};

#endif // DMLOGGER_H
