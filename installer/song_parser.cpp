#include <QtXml/QDomDocument>
#include <QFile>
#include <sstream>
#include <iostream>
#include <map>

struct Preset {
    std::string name;
    std::map<std::string, std::vector<int>> selections;
};

std::pair<int, int> parseRange(std::string input) {
    std::pair<int, int> retval;
    int dash = input.find('-');
    if (dash != std::string::npos) {
        std::string startString = input.substr(0,dash);
        std::string endString = input.substr(dash+1,input.size());
        retval.first = std::stoi(startString);
        retval.second = std::stoi(endString);
        return retval;
    } else { // Is not a range, just a single number.
        retval.first = std::stoi(input);
        retval.second = retval.first;
        return retval;
    }
}

void parseSongsXML(const QString &filename) {
    QDomDocument songxml;
    std::vector<std::string> sources;
    std::vector<struct Preset> presets;

    QFile file(filename);
    if (!file.open(QIODevice::ReadOnly) || !songxml.setContent(&file))
        return;

    // Get list of all sources
    QDomNodeList sources_xml = songxml.elementsByTagName("source");
    for (int i = 0; i < sources_xml.size(); i++) {
        QDomNode source_xml = sources_xml.item(i);
        sources.push_back(source_xml.toElement().text().toStdString());
    }

    // DEBUG
    std::cout << "SOURCE LIST:" << std::endl;
    for (auto & element : sources) {
        std::cout << "\t" << element << std::endl;
    }
    // END DEBUG

    // Get and parse list of all presets in the "presets" containing element (ignore <preset> tags within songs)
    QDomNodeList presets_container_xml = songxml.elementsByTagName("presets");
    for (int i = 0; i < presets_container_xml.size(); i++) {
        QDomNode root = presets_container_xml.item(i);
        QDomElement preset = root.firstChildElement("preset");
        for (; !preset.isNull(); preset = preset.nextSiblingElement("preset")) {
            struct Preset newpreset;
            if (preset.hasAttribute("name")) {
                newpreset.name = preset.attribute("name").toStdString();
                QDomNodeList selections_xml = preset.childNodes();
                for (int j = 0; j < selections_xml.size(); j++) {
                    QDomNode selection = selections_xml.item(j);
                    std::string key = selection.nodeName().toStdString();

                    // temporary empty range for testing, eventually parse out ranges.
                    //std::vector<int> ranges;
                    //ranges.push_back(0);
                    //ranges.push_back(0);

                    std::vector<int> ranges;
                    if (selection.toElement().hasAttribute("range")) {
                        std::string rawrange = selection.toElement().attribute("range").toStdString();
                        // Check if multiple entries or just one
                        if (rawrange.find(',') != std::string::npos) {
                            // If multiple entries, parse out each one
                            std::stringstream rrs(rawrange);
                            std::string token;
                            while (std::getline(rrs, token, ',')) {
                                std::pair<int, int> range = parseRange(token);
                                ranges.push_back(range.first);
                                ranges.push_back(range.second);
                            }
                        } else {
                            // If a single entry, just use it as is
                            std::pair<int, int> range = parseRange(rawrange);
                            ranges.push_back(range.first);
                            ranges.push_back(range.second);
                        }
                    }

                    newpreset.selections.insert({key, ranges});
                }
            }
            presets.push_back(newpreset);
        }
    }

    // DEBUG
    std::cout << "PRESET LIST:" << std::endl;
    for (auto & element : presets) {
        std::cout << "\t" << element.name << std::endl;
        for (auto & keyval : element.selections) {
            std::cout << "\t\t";
            std::cout << keyval.first << ":";
            for (auto & rangeval : keyval.second) {
                std::cout << rangeval << ",";
            }
            std::cout << std::endl;
        }
    }

}
