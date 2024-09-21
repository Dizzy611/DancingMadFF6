#ifndef SONG_PARSER_H
#define SONG_PARSER_H
#include <tuple>
#include <vector>
#include <string>
#include <QString>
#include <map>

struct Preset {
    std::string name;
    std::string friendly_name;
    std::map<std::string, std::vector<int>> selections;
};

struct Song {
    std::string name;
    std::vector<int> pcms;
    std::vector<std::string> sources;
};

std::tuple<std::map<std::string, std::string>, std::vector<struct Preset>, std::vector<struct Song>> parseSongsXML(const QByteArray &data);

#endif // SONG_PARSER_H
