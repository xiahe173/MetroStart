cmake_minimum_required(VERSION 3.16)

project(MetroStart VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick)
find_package(KF6WindowSystem REQUIRED)

# QML plugin with the compositor effects (blur behind, slide).
add_library(metrostarteffects MODULE plugin/plugin.cpp)
target_link_libraries(metrostarteffects PRIVATE Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick KF6::WindowSystem)
set_target_properties(metrostarteffects PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}/package/contents/ui/effects"
    PREFIX "lib"
)

set(PLASMOID_ID org.kde.plasma.metrostart)
set(PLASMOID_DIR "share/plasma/plasmoids/${PLASMOID_ID}")

install(TARGETS metrostarteffects LIBRARY DESTINATION "${PLASMOID_DIR}/contents/ui/effects")
install(FILES package/contents/ui/effects/qmldir DESTINATION "${PLASMOID_DIR}/contents/ui/effects")

install(DIRECTORY package/ DESTINATION "${PLASMOID_DIR}"
        FILES_MATCHING
        PATTERN "*.qml"
        PATTERN "*.js"
        PATTERN "*.json"
        PATTERN "*.png"
        PATTERN "*.svg"
)

message(STATUS "MetroStart applet package ready (${PLASMOID_ID})")
