import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.Layouts 1.0

import fi.pinniini.tekstitv 1.0

import "../models"
import "../js/database.js" as DB

Page {
    id: mainPage

    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: Orientation.All

    property bool initialLoad: true

    // This should be class implementing ISourceModule.
//    property var currentSource: null
    property SourceModule currentSource: null

    onCurrentSourceChanged: {
        console.log("Current source changed...");
        conn.target = null;
        conn.target = currentSource;

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
            //loadingIndicator.running = false;
            if (page) {
                console.log(page.page + " / " + page.subPage)
//                pageImage.source = currentSource.currentPage.pageImage //page.pageImage
                pageImage.source = page.pageImage

                pageNumberField.programmaticallySet = true;
                pageNumberField.text = page.page;
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
                text: qsTr("Aseta lähteen aloitussivuksi")
                onClicked: setInitialPage();
            }

            MenuItem {
                text: qsTr("Lisää suosikki")
//                onClicked: addFavorite(currentPageNumber, currentSubPageNumber);
                onClicked: addFavorite(currentSource.currentPage.page, currentSource.currentPage.subPage);
            }
            MenuItem {
                text: qsTr("Lataa uudelleen")
                onClicked: {
                    //                            console.log("Reload page " + currentPageNumber +  "/" + 1 + "...");
                    //                            loadPage(currentPageNumber, 1);
                    console.log(currentSource)
//                    currentSource.loadPage(100, 1);
                    currentSource.reloadCurrentPage();
                }
            }
            MenuLabel {
                id: currentTeletext
                text: currentSource ? currentSource.name : "Source not set" //"YLE"
            }
        }

        // Tell SilicaFlickable the height of its content.
        contentHeight: column.height

        Column {
            id: column
            y: Theme.paddingMedium
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
//                    source: currentSource ? currentSource.currentPage ? currentSource.currentPage.pageImage : "" : ""
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
                        text: "Sivu ei saatavilla, yritä myöhemmin uudelleen."
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
                            text: "Poista suosikki"
                            onClicked: remove();
                        }
//                        MenuItem {
//                            text: "Aseta aloitussivuksi"
//                            onClicked: setInitialPage();
//                        }
                    }

                    function remove() {
//                        remorseAction("Poistetaan", function() {deleteFavorite(model.itemId, index);}); //favoritesList.model.remove(index);});
                        deleteFavorite(model.itemId, index);
                    }
                }

                Label {
                    anchors.centerIn: parent
                    text: "Ei suosikkeja"
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
                    Layout.minimumWidth: Theme.buttonWidthExtraSmall
                    Layout.alignment: Qt.AlignBottom
                    horizontalAlignment: TextInput.AlignHCenter
                    inputMethodHints: Qt.ImhDigitsOnly
//                    validator: IntValidator {
//                        bottom: 100
//                        top: 899
//                    }

                    onFocusChanged: {
                        if (focus) {
                            selectAll();
                        }
                    }

                    onTextChanged: {
//                        text = text.replace("+", "");
//                        text = text.replace("-", "");

                        // Page number.
                        if (text.length >= 3 && !programmaticallySet) {
//                            selectAll();
//                            loadPage(text, 1);
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
//                height: ((mainFlick.height - (buttonRow.y + buttonRow.height) - 3 * Theme.paddingMedium) / 4)

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
//                Rectangle {
//                    color: "transparent"
//                    width: zeroButton.width
//                    height: zeroButton.height
//                    Layout.fillWidth: true
//                    Layout.alignment: Qt.AlignTop
//                }
            }
        }
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
        else if (pageNumberField.text.length > 1) {
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
