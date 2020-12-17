import QtQuick 2.0
import Sailfish.Silica 1.0

import fi.pinniini.tekstitv 1.0

import "../js/database.js" as DB

Page {
    id: sourcesPage

    orientation: Orientation.Portrait
    clip: true

    property bool initialLoad: true
    onStatusChanged: {
        if (initialLoad && status === PageStatus.Active) {
            var initialSource = DB.getSetting("InitialSource", "default");
            if (initialSource !== null) {
                findAndSelectSource(initialSource.value);
            }
            initialLoad = false;
        }
    }

    property SourceModule currentSource: null
    onCurrentSourceChanged: {
        console.log("SourcesPage - currentSource changed:", currentSource);
        coverPage.coverConnections.target = null;
        coverPage.coverConnections.target = currentSource;
    }
    property Page currentTeletextPage: null

    SourceModel {
        id: sourceModel
    }

    SilicaListView {
        id: sourceList
        anchors.fill: parent
        model: sourceModel

        // PullDownMenu and PushUpMenu must be declared in SilicaFlickable, SilicaListView or SilicaGridView
        PullDownMenu {
            MenuItem {
                text: qsTr("Tietoja")
                onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
            }
        }

        header: PageHeader {
            title: qsTr("Lähteet")
        }

        delegate: ListItem {
            contentHeight: Theme.itemSizeSmall
            width: parent.width

            Label {
                text: model.name
                y: (parent.height / 2) - (height / 2)
                x: Theme.paddingMedium
                width: parent.width - Theme.paddingMedium - Theme.paddingMedium
            }

            onClicked: {
                console.log("Module \"" + model.name + "\" clicked at index: " + index);
                console.log(sourceModel.get(index).code);

                sourceList.currentIndex = index;
                selectSource(index)
            }

            menu: ContextMenu {
                id: context
                MenuItem {
                    id: toggleDefaultMenuItem
                    text: qsTr("Aseta oletukseksi")
                    onClicked: toggleDefaultSource(index);
                }

                onActiveChanged: {
                    if (active) {
                        toggleDefaultMenuItem.text = isDefaultSource(index) ? qsTr("Poista oletus") : qsTr("Aseta oletukseksi")
                    }
                }
            }
        }
    }

    function selectSource(index) {
        var selected = sourceModel.get(index);

        if (!currentTeletextPage) {
            console.log("No teletext page yet, let's add it...");
            console.log(pageStack);
            console.log(selected);
            currentTeletextPage = pageStack.pushAttached(Qt.resolvedUrl("MainPage.qml"), {"currentSource": selected});
            currentSource = selected;
            pageStack.navigateForward(PageStackAction.Animated);
        }
        else {
            // Source changes.
            if (currentSource !== selected) {
                currentTeletextPage.currentSource = selected;
                currentSource = selected;
            }

            pageStack.navigateForward(PageStackAction.Animated);
        }
    }

    function navigatePage(forwards) {
        if (currentSource === null) {
            console.log("No source selected...");
            return;
        }

        if (forwards) {
            currentSource.navNextPage();
        } else {
            currentSource.navPrevPage();
        }
    }

    function navigateSubPage(forwards) {
        if (currentSource === null) {
            console.log("No source selected...");
            return;
        }

        if (forwards) {
            currentSource.navNextSubPage();
        } else {
            currentSource.navPrevSubPage();
        }
    }

    function toggleDefaultSource(index) {
        if (isDefaultSource(index)) {
            deleteDefaultSource();
        } else {
            setAsDefaultSource(index);
        }
    }

    function setAsDefaultSource(index) {
        var selected = sourceModel.get(index);
        console.log("Setting source as default:", selected.code);

        if (selected) {
            DB.upsertSetting('InitialSource', selected.code, "default");
        }
    }

    function deleteDefaultSource() {
        DB.deleteInitialSource();
    }

    function isDefaultSource(index) {
        console.log("Checking if the source is set as default, id:", index);
        var selected = sourceModel.get(index);
        var initialSource = DB.getSetting("InitialSource", "default");

        if (initialSource && selected && initialSource.value === selected.code) {
            return true;
        }
    }

    function findAndSelectSource(code) {
        console.log("Finding source:", code);
        var index = -1;
        if (sourceModel && sourceList.count > 0) {
            for (var i = 0; i < sourceList.count; ++i) {
                var source = sourceModel.get(i);
                if (source && source.code === code) {
                    console.log("Found source at index", i);
                    index = i;
                    break;
                }
            }
        }

        // Found source.
        if (index > -1) {
            selectSource(i);
        }
    }
}
