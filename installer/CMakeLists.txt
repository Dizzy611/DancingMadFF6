cmake_minimum_required(VERSION 3.5)

project(DanceMonkey VERSION 0.1 LANGUAGES CXX C)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Widgets LinguistTools Xml Network Multimedia)
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
    qt_add_executable(DanceMonkey
        MANUAL_FINALIZATION
        ${PROJECT_SOURCES}
    )
# Define target properties for Android with Qt 6 as:
#    set_property(TARGET DanceMonkey APPEND PROPERTY QT_ANDROID_PACKAGE_SOURCE_DIR
#                 ${CMAKE_CURRENT_SOURCE_DIR}/android)
# For more information, see https://doc.qt.io/qt-6/qt-add-executable.html#target-creation

    qt_create_translation(QM_FILES ${CMAKE_SOURCE_DIR} ${TS_FILES})
else()
    if(ANDROID)
        add_library(DanceMonkey SHARED
            ${PROJECT_SOURCES}
        )
# Define properties for Android with Qt 5 after find_package() calls as:
#    set(ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/android")
    elseif(WIN32)
        add_executable(DanceMonkey
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
        add_executable(DanceMonkey
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

target_link_libraries(DanceMonkey PRIVATE Qt${QT_VERSION_MAJOR}::Widgets Qt${QT_VERSION_MAJOR}::Xml Qt${QT_VERSION_MAJOR}::Network Qt${QT_VERSION_MAJOR}::Multimedia)
# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
if(${QT_VERSION} VERSION_LESS 6.1.0)
  set(BUNDLE_ID_OPTION MACOSX_BUNDLE_GUI_IDENTIFIER com.example.DanceMonkey)
endif()
set_target_properties(DanceMonkey PROPERTIES
    ${BUNDLE_ID_OPTION}
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

include(GNUInstallDirs)
# explicitly include G++14 stuff, as Qt Creator is being dumb
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    include_directories("/usr/include/x86_64-linux-gnu/c++/14/")
endif()

# explicitly include local includes and libraries
#include_directories("/usr/local/include/")
#link_directories("/usr/local/lib/")

install(TARGETS DanceMonkey
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

if(QT_VERSION_MAJOR EQUAL 6)
    qt_finalize_executable(DanceMonkey)
endif()

# statically link on windows
if(WIN32)
    set(CMAKE_FIND_LIBRARY_SUFFIXES ".a")
    target_link_options(DanceMonkey PRIVATE "-static")
endif()

