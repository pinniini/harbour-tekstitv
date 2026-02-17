import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.Layouts 1.0
import Nemo.KeepAlive 1.2

import fi.pinniini.tekstitv 1.0

import "../models"
import "../js/database.js" as DB

Page {
    id: mainPage

    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: Orientation.Portrait
    clip: true

    property bool initialLoad: true
    property bool autoUpdateEnabled: false

    // This should be class implementing ISourceModule.
    property SourceModule currentSource: null
    property SourceModel sourceModel

    onCurrentSourceChanged: {
        console.log("Current source changed...");
        conn.target = null;
        conn.target = currentSource;
        updateJob.enabled = false;
        mainPage.autoUpdateEnabled = false;

        if (!initialLoad) {
            console.log("Source changed and not initial load -> load initial page and load favorites...");
            loadWithInitialPage();
        }
    }

    Component.onCompleted: {
        console.log("Component complete, should we load something...");
        loadWithInitialPage();
    }

    Connections {
        id: conn
        target: null

        onLoadingChanged: {
            console.log("Loading changed to " + isLoading);
        }

        onPageLoaded: {
            infoRectangle.visible = false;
            console.log("Page loaded...");
            if (page) {
                var pageText = page.page + " " + page.subPage + "/" + page.subPageCount;
                console.log(pageText)
                pageImage.source = page.pageImage

                pageNumberField.programmaticallySet = true;
                pageNumberField.text = pageText; //page.page;
                pageNumberField.programmaticallySet = false;
            }
        }

        onPageMissing: {
            infoRectangle.visible = true;
        }
    }

    FavoritesModel {
        id: favModel
    }

    // To enable PullDownMenu, place our content in a SilicaFlickable
    SilicaFlickable {
        id: mainFlick
        anchors.fill: parent

        // PullDownMenu and PushUpMenu must be declared in SilicaFlickable, SilicaListView or SilicaGridView
        PullDownMenu {
            MenuItem {
                text: qsTr("Tietoja")
                onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
            }
            MenuItem {
                text: qsTr("Asetukset")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("SettingsPage.qml"), {"sourceModel": sourceModel})
                }
            }

            MenuItem {
                text: qsTr("Aseta lähteen aloitussivuksi")
                onClicked: setInitialPage();
            }
            MenuItem {
                text: mainPage.autoUpdateEnabled ? qsTr("Pysäytä automaattinen päivitys") : qsTr("Päivitä automaattisesti")
                onClicked: {
                    // Disable
                    if (mainPage.autoUpdateEnabled) {
                        console.log("Page auto-update disabled...");
                        updateJob.enabled = false;
                        mainPage.autoUpdateEnabled = false;
                    } else {
                        // Enable auto-update
                        console.log("Page auto-update enabled...");
                        updateJob.enabled = true;
                        mainPage.autoUpdateEnabled = true;
                    }
                }
            }
            MenuItem {
                text: qsTr("Lisää suosikki")
                onClicked: addFavorite(currentSource.currentPage.page, currentSource.currentPage.subPage);
            }
            MenuItem {
                text: qsTr("Lataa uudelleen")
                onClicked: {
                    console.log(currentSource)
                    currentSource.reloadCurrentPage();
                }
            }
            MenuLabel {
                id: currentTeletext
                text: currentSource ? currentSource.name : qsTr("Lähdettä ei ole asetettu")
            }
        }

        // Tell SilicaFlickable the height of its content.
        contentHeight: column.height

        Column {
            id: column
            anchors.top: parent.top
            anchors.topMargin: Screen.topCutout.height + Theme.paddingSmall
            width: parent.width
            spacing: Theme.paddingMedium

            Rectangle {
                id: pageRectangle
                width: parent.width - Theme.paddingSmall
                height: width * 0.72
                color: "transparent"
                Image {
                    id: pageImage
                    anchors.fill: parent

                    MouseArea {
                        anchors.fill: parent
                        onClicked: pageStack.push(Qt.resolvedUrl("PageViewer.qml"), {'pageSource' : pageImage.source})
                    }
                }

                Rectangle {
                    id: infoRectangle
                    anchors.fill: parent
                    color: "black"
                    opacity: 0.9
                    visible: false

                    Label {
                        id: infoLabel
                        anchors.centerIn: parent
                        width: pageRectangle.width
                        wrapMode: Text.Wrap
                        color: Theme.highlightColor
                        text: qsTr("Sivu ei saatavilla, yritä myöhemmin uudelleen.")
                        visible: parent.visible
                    }
                }

                BusyIndicator {
                    anchors.centerIn: parent
                    size: BusyIndicatorSize.Large
                    running: currentSource ? currentSource.loading : false
                }
            }

            ListView {
                id: favoritesList
                anchors {
                    left: parent.left
                    leftMargin: Theme.paddingSmall
                    right: parent.right
                    rightMargin: Theme.paddingSmall
                }

                spacing: Theme.paddingMedium
                height: Theme.itemSizeExtraSmall
                orientation: ListView.Horizontal
                model: favModel
                delegate: ListItem {
                    contentHeight: Theme.itemSizeExtraSmall
                    width: Theme.buttonWidthExtraSmall * 0.5

                    Rectangle {
                        id: favRect
                        color: "transparent"
                        radius: 5
                        anchors.fill: parent

                        Label {
                            id: favLabel
                            anchors.centerIn: parent
                            text: model.caption
                        }
                    }

                    onClicked: {
                        console.log("Fav clicked: " + model.pageNumber);
                        pageNumberField.text = model.pageNumber;
                    }

                    menu: ContextMenu {
                        id: context
                        MenuItem {
                            text: qsTr("Poista suosikki")
                            onClicked: remove();
                        }
                    }

                    function remove() {
                        deleteFavorite(model.itemId, index);
                    }
                }

                Label {
                    anchors.centerIn: parent
                    text: qsTr("Ei suosikkeja")
                    color: Theme.highlightColor
                    visible: favoritesList.count == 0
                }
            }

            RowLayout {
                id: buttonRow
                anchors {
                    left: parent.left
                    leftMargin: Theme.paddingSmall
                    right: parent.right
                    rightMargin: Theme.paddingSmall
                }

                Button {
                    id: previousButton
                    text: "<<"
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop

                    onClicked: {
                        navigatePage(false);
                    }
                }
                Button {
                    id: previousSubButton
                    text: "<"
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop

                    onClicked: {
                        navigateSubPage(false);
                    }
                }
                TextField {
                    id: pageNumberField

                    property bool programmaticallySet: false

                    Layout.fillWidth: true
                    Layout.minimumWidth: Theme.buttonWidthExtraSmall * 1.5
                    Layout.alignment: Qt.AlignBottom
                    horizontalAlignment: TextInput.AlignHCenter
//                    inputMethodHints: Qt.ImhDigitsOnly

                    onFocusChanged: {
                        if (focus) {
                            selectAll();
                        }
                    }

                    onTextChanged: {
                        // Page number.
                        if (text.length >= 3 && !programmaticallySet) {
                            currentSource.loadPage(text, 1);
                        }
                    }
                    enabled: false
                }
                Button {
                    id: nextSubButton
                    text: ">"
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop

                    onClicked: {
                        navigateSubPage(true);
                    }
                }
                Button {
                    id: nextButton
                    text: ">>"
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop

                    onClicked: {
                        navigatePage(true);
                    }
                }
            }

            RowLayout {
                anchors {
                    left: parent.left
                    leftMargin: Theme.paddingSmall
                    right: parent.right
                    rightMargin: Theme.paddingSmall
                }

                Button {
                    text: "1"
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    onClicked: numberPressed(1);
                }
                Button {
                    text: "2"
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    onClicked: numberPressed(2);
                }
                Button {
                    text: "3"
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    onClicked: numberPressed(3);
                }
            }

            RowLayout {
                anchors {
                    left: parent.left
                    leftMargin: Theme.paddingSmall
                    right: parent.right
                    rightMargin: Theme.paddingSmall
                }

                Button {
                    text: "4"
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    onClicked: numberPressed(4);
                }
                Button {
                    text: "5"
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    onClicked: numberPressed(5);
                }
                Button {
                    text: "6"
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    onClicked: numberPressed(6);
                }
            }

            RowLayout {
                anchors {
                    left: parent.left
                    leftMargin: Theme.paddingSmall
                    right: parent.right
                    rightMargin: Theme.paddingSmall
                }

                Button {
                    text: "7"
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    onClicked: numberPressed(7);
                }
                Button {
                    text: "8"
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    onClicked: numberPressed(8);
                }
                Button {
                    text: "9"
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    onClicked: numberPressed(9);
                }
            }

            RowLayout {
                anchors {
                    left: parent.left
                    leftMargin: Theme.paddingSmall
                    right: parent.right
                    rightMargin: Theme.paddingSmall
                }

                Rectangle {
                    color: "transparent"
                    width: zeroButton.width
                    height: zeroButton.height
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                }
                Button {
                    id: zeroButton
                    text: "0"
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    onClicked: numberPressed(0);
                }
                IconButton {
                    id: eraseButton
                    icon.source: "image://theme/icon-m-backspace"
                    width: zeroButton.width
                    height: zeroButton.height
                    //text: "<"
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    onClicked: backspacePressed();
                }
            }
        }
    }

    BackgroundJob {
        id: updateJob
        enabled: false
        frequency: BackgroundJob.TwoAndHalfMinutes

        onTriggered: {
            console.log("Reload page at:", printDateTime(new Date()));
            currentSource.reloadCurrentPage();
            finished();
        }
    }

    function printDateTime(dateTime) {
        return new Date(dateTime).toLocaleString('fi-FI', { timeZone: 'EET' });
    }

    function navigatePage(forwards) {
        if (forwards) {
            currentSource.navNextPage();
        } else {
            currentSource.navPrevPage();
        }
    }

    function navigateSubPage(forwards) {
        if (forwards) {
            currentSource.navNextSubPage();
        } else {
            currentSource.navPrevSubPage();
        }
    }

    function numberPressed(number) {
        console.log("Number", number, "pressed");

        if (pageNumberField.text.length >= 3) {
            pageNumberField.text = number;
        } else {
            pageNumberField.text += number;
        }
    }

    function backspacePressed() {
        if (pageNumberField.text.length == 1) {
            pageNumberField.text = "";
        }
        else if (pageNumberField.text.length > 1 && pageNumberField.text.length <= 3) {
            pageNumberField.text = pageNumberField.text.substring(0, pageNumberField.text.length - 1);
        }
    }

    function addFavorite(page, subPage) {
        console.log("Add favorite: " + page + "/" + subPage);

        if (DB.doesFavoriteExist(currentSource.code, currentSource.currentPage.page, currentSource.currentPage.subPage)) {
            console.log("Favorite exists already...");
            return;
        }

        var favorite = {'itemId': -1, 'caption': currentSource.currentPage.page.toString(), 'source': currentSource.code, 'pageNumber': currentSource.currentPage.page, 'subPageNumber': currentSource.currentPage.subPage};
        var id = DB.addFavorite(favorite);
        if (id > 0) {
            favorite.itemId = id;
            var index = getIndex(currentSource.currentPage.page);
            favModel.insert(index, favorite);
        }
    }

    function getIndex(pageNumber) {
        var count = favModel.count;
        var index = count > 0 ? count : 0;
        for (var i = 0; i < count; ++i) {
            var fav = favModel.get(i);
            if (pageNumber < fav.pageNumber) {
                index = i;
                break;
            }
        }
        return index;
    }

    function loadFavorites() {
        favModel.clear();

        var favorites = DB.getFavorites(currentSource.code);
        if (favorites && favorites.length > 0) {
            var count = favorites.length;
            for(var i = 0; i < count; ++i) {
                var favorite = favorites[i];
                var fav = { "itemId": favorite.rowid, "caption": favorite.caption, "source": favorite.source, "pageNumber": favorite.pageNumber, "subPageNumber": favorite.subPageNumber};
                favModel.append(fav);
            }
        }
    }

    function deleteFavorite(itemId, index) {
        console.log("Delete favorite: " + itemId);
        if (DB.deleteFavorite(itemId)) {
            favModel.remove(index);
        }
    }

    function setInitialPage() {
        DB.upsertSetting('InitialPage', currentSource.currentPage.page.toString(), currentSource.code);
    }

    function loadWithInitialPage() {
        var initialPage = DB.getSetting("InitialPage", currentSource.code);
        if (initialPage !== null) {
            pageNumberField.text = "";
            pageNumberField.text = initialPage.value;
        } else {
            currentSource.loadInitialPage();
        }

        initialLoad = false;
        loadFavorites();
    }
}
