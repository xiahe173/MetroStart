cmake_minimum_required(VERSION 3.16)

project(MetroStart VERSION 0.2.1 LANGUAGES NONE)

# MetroStart is a pure QML Plasma applet: installing it means copying the
# package into the plasmoid directory.
set(PLASMOID_ID org.kde.plasma.metrostart)

install(DIRECTORY package/ DESTINATION "share/plasma/plasmoids/${PLASMOID_ID}"
        FILES_MATCHING
        PATTERN "*.qml"
        PATTERN "*.js"
        PATTERN "*.json"
        PATTERN "*.png"
        PATTERN "*.svg"
        PATTERN "*.qsb"
        PATTERN "*.frag"
        PATTERN "*.xml"
        # The QML module file has no extension: it declares the Translations
        # singleton, so a package without it loses every translated string.
        PATTERN "qmldir"
)

message(STATUS "MetroStart applet package ready (${PLASMOID_ID})")
