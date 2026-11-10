cmake_minimum_required(VERSION 3.16)

project(MetroStart VERSION 0.1.0 LANGUAGES NONE)

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
)

message(STATUS "MetroStart applet package ready (${PLASMOID_ID})")
