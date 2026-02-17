# NOTICE:
#
# Application name defined in TARGET has a corresponding QML filename.
# If name defined in TARGET is changed, the following needs to be done
# to match new name:
#   - corresponding QML filename must be changed
#   - desktop icon filename must be changed
#   - desktop filename must be changed
#   - icon definition filename in desktop file must be changed
#   - translation filenames have to be changed

# The name of your application
TARGET = harbour-tekstitv

CONFIG += sailfishapp

SOURCES += src/harbour-tekstitv.cpp \
    src/isourcemodule.cpp \
    src/migrator.cpp \
    src/mtvmodule.cpp \
    src/sourcemodel.cpp \
    src/sourcepage.cpp \
    src/televideomodule.cpp \
    src/ylemodule.cpp

DISTFILES += qml/harbour-tekstitv.qml \
    qml/js/database.js \
    qml/cover/CoverPage.qml \
    qml/models/FavoritesModel.qml \
    qml/pages/AboutPage.qml \
    qml/pages/MainPage.qml \
    qml/pages/PageViewer.qml \
    qml/pages/SettingsPage.qml \
    qml/pages/SourcesPage.qml \
    rpm/harbour-tekstitv.changes \
    rpm/harbour-tekstitv.changes.run.in \
    rpm/harbour-tekstitv.spec \
    rpm/harbour-tekstitv.yaml \
    translations/*.ts \
    harbour-tekstitv.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n

# German translation is enabled as an example. If you aren't
# planning to localize your app, remember to comment out the
# following TRANSLATIONS line. And also do not forget to
# modify the localized app name in the the .desktop file.
TRANSLATIONS += translations/harbour-tekstitv-en.ts \
    translations/harbour-tekstitv-it.ts

HEADERS += \
    src/isourcemodule.h \
    src/migrator.h \
    src/mtvmodule.h \
    src/sourcemodel.h \
    src/sourcepage.h \
    src/televideomodule.h \
    src/ylemodule.h
