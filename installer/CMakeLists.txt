cmake_minimum_required(VERSION 3.5)

project(DancingMadInstaller VERSION 0.1 LANGUAGES CXX C)

option(DMINST_WINDOWS_FORCE_STATIC "Force static linking for Windows build (legacy)" OFF)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT DEFINED QT_DEFAULT_MAJOR_VERSION)
    set(QT_DEFAULT_MAJOR_VERSION 6)
endif()

if(QT_DEFAULT_MAJOR_VERSION EQUAL 5)
    find_package(QT NAMES Qt5 Qt6 REQUIRED COMPONENTS Widgets LinguistTools Xml Network Multimedia)
elseif(QT_DEFAULT_MAJOR_VERSION EQUAL 6)
    find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Widgets LinguistTools Xml Network Multimedia)
else()
    message(FATAL_ERROR "QT_DEFAULT_MAJOR_VERSION must be 5 or 6")
endif()
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Widgets LinguistTools Xml Network Multimedia)

set(TS_FILES DanceMonkey_en_US.ts)


set(PROJECT_SOURCES
        main.cpp
        dminst.cpp
        dminst.h
        dminst.ui


        ${TS_FILES}
)

if(${QT_VERSION_MAJOR} GREATER_EQUAL 6)
    qt_add_executable(DancingMadInstaller
        MANUAL_FINALIZATION
        ${PROJECT_SOURCES}
        customtrackselection.cpp
        downloadmanager.cpp
        mirrorchecker.cpp
        rom_validator.cpp
        song_parser.cpp
        customtrackselection.h
        customtrackselection.h customtrackselection.ui
        dmlogger.cpp dmlogger.h
        mirrorchecker.h
        song_parser.h
        rom_validator.h
        downloadmanager.h
        ips-patcher-master/IPSPatcherHandler.cpp ips-patcher-master/IPSPatcherHandler.h
    )
# Define target properties for Android with Qt 6 as:
#    set_property(TARGET DancingMadInstaller APPEND PROPERTY QT_ANDROID_PACKAGE_SOURCE_DIR
#                 ${CMAKE_CURRENT_SOURCE_DIR}/android)
# For more information, see https://doc.qt.io/qt-6/qt-add-executable.html#target-creation

    qt_create_translation(QM_FILES ${CMAKE_SOURCE_DIR} ${TS_FILES})
else()
    if(ANDROID)
        add_library(DancingMadInstaller SHARED
            ${PROJECT_SOURCES}
        )
# Define properties for Android with Qt 5 after find_package() calls as:
#    set(ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/android")
    elseif(WIN32)
        add_executable(DancingMadInstaller
            ${PROJECT_SOURCES}
            rom_validator.cpp
            rom_validator.h
            song_parser.cpp
            song_parser.h
            downloadmanager.h downloadmanager.cpp
            customtrackselection.h customtrackselection.cpp customtrackselection.ui
            ips-patcher-master/IPSPatcherHandler.h ips-patcher-master/IPSPatcherHandler.cpp
            mirrorchecker.h mirrorchecker.cpp
            dmlogger.h dmlogger.cpp dminst.rc
        )
    else()
        add_executable(DancingMadInstaller
            ${PROJECT_SOURCES}
            rom_validator.cpp
            rom_validator.h
            song_parser.cpp
            song_parser.h
            downloadmanager.h downloadmanager.cpp
            customtrackselection.h customtrackselection.cpp customtrackselection.ui
            ips-patcher-master/IPSPatcherHandler.h ips-patcher-master/IPSPatcherHandler.cpp
            mirrorchecker.h mirrorchecker.cpp
            dmlogger.h dmlogger.cpp
        )
    endif()

    qt5_create_translation(QM_FILES ${CMAKE_SOURCE_DIR} ${TS_FILES})
endif()

target_link_libraries(DancingMadInstaller PRIVATE Qt${QT_VERSION_MAJOR}::Widgets Qt${QT_VERSION_MAJOR}::Xml Qt${QT_VERSION_MAJOR}::Network Qt${QT_VERSION_MAJOR}::Multimedia)
# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
if(${QT_VERSION} VERSION_LESS 6.1.0)
  set(BUNDLE_ID_OPTION MACOSX_BUNDLE_GUI_IDENTIFIER com.example.DancingMadInstaller)
endif()
set_target_properties(DancingMadInstaller PROPERTIES
    ${BUNDLE_ID_OPTION}
    OUTPUT_NAME DanceMonkey
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

include(GNUInstallDirs)
# explicitly include G++14 stuff, as Qt Creator is being dumb
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    if(EXISTS "/usr/include/x86_64-linux-gnu/c++/14/")
        include_directories("/usr/include/x86_64-linux-gnu/c++/14/")
    endif()
endif()

# explicitly include local includes and libraries
#include_directories("/usr/local/include/")
#link_directories("/usr/local/lib/")

install(TARGETS DancingMadInstaller
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

install(FILES
    kefka-16x16.png
    kefka.ico
    kefkalaugh.wav
    mirrors.dat
    songs.xml
    DESTINATION ${CMAKE_INSTALL_BINDIR}
)

if(EXISTS "${CMAKE_SOURCE_DIR}/../patch/ff3msu.ips")
    install(FILES
        "${CMAKE_SOURCE_DIR}/../patch/ff3msu.ips"
        DESTINATION ${CMAKE_INSTALL_BINDIR}
    )
endif()

if(QT_VERSION_MAJOR EQUAL 6)
    qt_finalize_executable(DancingMadInstaller)
endif()

# Legacy static linking can produce brittle executables with modern MSYS2/Qt packaging.
# Keep it opt-in for manual experiments only.
if(WIN32 AND DMINST_WINDOWS_FORCE_STATIC)
    set(CMAKE_FIND_LIBRARY_SUFFIXES ".a")
    target_link_options(DancingMadInstaller PRIVATE "-static")
endif()

