#include <QtXml/QDomDocument>
#include <QFile>
#include <sstream>
#include <iostream>
#include <fstream>
#include <map>
#include "song_parser.h"

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

std::tuple<std::vector<std::string>, std::vector<struct Preset>, std::vector<struct Song>> parseSongsXML(const QByteArray &data) {
    QDomDocument songxml;
    std::vector<std::string> sources;
    std::vector<struct Preset> presets;
    std::vector<struct Song> songs;
    if (!songxml.setContent(data)) {
        return std::tuple(sources, presets, songs);
    }
    //QFile file(filename);
    //if (!file.open(QIODevice::ReadOnly) || !songxml.setContent(&file))
    //    return std::tuple(sources, presets, songs);

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

    // Get and parse all songs
    QDomNodeList songs_xml = songxml.elementsByTagName("song");
    for (int i = 0; i < songs_xml.size(); i++) {
        struct Song song;
        QDomNode root = songs_xml.item(i);

        // Find name
        QDomElement name_xml = root.firstChildElement("name");
        std::string name = name_xml.text().toStdString();
        song.name = name;

        // Build vector of PCMs
        QDomElement pcms_xml = root.firstChildElement("pcms");
        std::string rawpcms = pcms_xml.text().toStdString();
        std::vector<int> pcms;
        // Check if multiple PCMs or just one
        if (rawpcms.find(',') != std::string::npos) {
            // If multiple entries, pull out each one and add it to the vector
            std::stringstream pcmss(rawpcms);
            std::string token;
            while (std::getline(pcmss, token, ',')) {
                pcms.push_back(std::stoi(token));
            }
        } else {
            // Otherwise just add it as is
            pcms.push_back(std::stoi(rawpcms));
        }
        song.pcms = pcms;

        // Build vector of sources
        std::vector<std::string> sources;
        QDomNodeList song_nodes = root.childNodes();
        for (int j = 0; j < song_nodes.size(); j++) {
            if (song_nodes.item(j).nodeName() == "name" || song_nodes.item(j).nodeName() == "pcms" || song_nodes.item(j).nodeName() == "preset") {
                continue;
            } else {
                sources.push_back(song_nodes.item(j).nodeName().toStdString());
            }
        }
        song.sources = sources;

        // Populate per song presets
        QDomElement preset = root.firstChildElement("preset");
        for (; !preset.isNull(); preset = preset.nextSiblingElement("preset")) {
            if (preset.hasAttribute("name")) {
                // Find preset with the given name in previously populated vector
                for (auto & element : presets) {
                    if (element.name == preset.attribute("name").toStdString()) {
                        // Find source being set for preset. Should be name of very first child node
                        std::string source = preset.childNodes().item(0).nodeName().toStdString();
                        // Check if source already exists in preset
                        if (element.selections.find(source) == element.selections.end()) {
                            // Source does not already exist in preset, add it.
                            std::vector<int> ranges;
                            ranges.push_back(i);
                            ranges.push_back(i);
                            element.selections.insert({source, ranges});
                        } else {
                            // Source exists in preset, append to it
                            element.selections[source].push_back(i);
                            element.selections[source].push_back(i);
                        }
                    }
                }
            }
        }

        // Add song to vector
        songs.push_back(song);

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

    // DEBUG
    std::cout << "SONG LIST:" << std::endl;
    for (auto & element : songs) {
        std::cout << "\t" << element.name << std::endl;
        std::cout << "\t\tPCMs:";
        for (auto & element2 : element.pcms) {
            std::cout << element2 << ",";
        }
        std::cout << std::endl;
        std::cout << "\t\tSources:";
        for (auto & element2 : element.sources) {
            std::cout << element2 << ",";
        }
        std::cout << std::endl;
    }

    return std::tuple(sources, presets, songs);
}
