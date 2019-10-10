import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.Layouts 1.0

import "../models"
import "../js/database.js" as DB

Page {
    id: page

    // Loading
    property bool loading: true
    property bool initialLoad: true
    property bool updateSubPageCount: true

    // Page info
    property int currentPageNumber: 100
    property int currentSubPageNumber: 1
    property int subPages: 1
    property int pageStatus: 200
    property string currentPageImageString: ""
    property int nextPage: 101
    property int previousPage: 899

    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: Orientation.Portrait

    Component.onCompleted: {
        loadSettings();
        loadFavorites();
        pageNumberField.focus = true;
    }

    FavoritesModel {
        id: favModel
    }

    // To enable PullDownMenu, place our content in a SilicaFlickable
    SilicaFlickable {
        anchors.fill: parent

        // PullDownMenu and PushUpMenu must be declared in SilicaFlickable, SilicaListView or SilicaGridView
        PullDownMenu {
            MenuItem {
                text: qsTr("Tietoja")
                onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
            }
            MenuItem {
                text: qsTr("Lisää suosikki")
                onClicked: addFavorite(currentPageNumber, currentSubPageNumber);
            }
            MenuLabel {
                id: currentTeletext
                text: "YLE"
            }
        }

        PushUpMenu {
            MenuItem {
                text: qsTr("Lisää suosikki")
                onClicked: addFavorite(currentPageNumber, currentSubPageNumber);
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
                    source: currentPageImageString
                }

                Rectangle {
                    id: infoRectangle
                    anchors.centerIn: parent
                    x: Theme.paddingSmall
                    width: infoLabel.width
                    height: infoLabel.height
                    color: "black"
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
                    running: loading
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
                height: 70
                orientation: ListView.Horizontal
                model: favModel
                delegate: ListItem {
                    contentHeight: 70
                    width: 64

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
                        MenuItem {
                            text: "Aseta aloitussivuksi"
                            onClicked: setInitialPage();
                        }
                    }

                    function remove() {
                        remorseAction("Poistetaan", function() {deleteFavorite(model.itemId, index);}); //favoritesList.model.remove(index);});
                    }

                    function setInitialPage() {
                        DB.upsertSetting('InitialPage', model.caption);
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
                        stepPage(false);
                    }
                }
                Button {
                    id: previousSubButton
                    text: "<"
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop

                    onClicked: {
                        updateSubPageCount = false;
                        stepSubPage(-1);
                    }
                }
                TextField {
                    id: pageNumberField
                    Layout.fillWidth: true
                    Layout.minimumWidth: 150
                    Layout.alignment: Qt.AlignBottom
                    horizontalAlignment: TextInput.AlignHCenter
                    inputMethodHints: Qt.ImhDigitsOnly
                    validator: IntValidator {
                        bottom: 100
                        top: 899
                    }

                    onFocusChanged: {
                        if (focus) {
                            selectAll();
                        }
                    }

                    onTextChanged: {
                        text = text.replace("+", "");
                        text = text.replace("-", "");

                        // Page number.
                        if (text.length >= 3) {
                            selectAll();
                            loadPage(text, 1);
                        }
                    }
                }
                Button {
                    id: nextSubButton
                    text: ">"
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop

                    onClicked: {
                        updateSubPageCount = false;
                        stepSubPage(1);
                    }
                }
                Button {
                    id: nextButton
                    text: ">>"
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop

                    onClicked: {
                        stepPage(true);
                    }
                }
            }
        }
    }

    function loadFavorites() {
        favModel.clear();

        var favorites = DB.getFavorites();
        if (favorites && favorites.length > 0) {
            var count = favorites.length;
            for(var i = 0; i < count; ++i) {
                var favorite = favorites[i];
                var fav = { "itemId": favorite.rowid, "caption": favorite.caption, "pageNumber": favorite.pageNumber, "subPageNumber": favorite.subPageNumber};
                favModel.append(fav);
            }
        }
    }

    function loadSettings() {
        var initPage = DB.getSetting('InitialPage');
        if (initPage && initPage.hasOwnProperty('value')) {
            pageNumberField.text = initPage.value;
        }
        else {
            pageNumberField.text = "100";
        }
    }

    function loadDone(responseText) {
        console.log("Loading done...");
        var obj = JSON.parse(responseText);

        // Parse page information.
        parsePageData(obj);

        // Check page status.
        if (pageStatus != 200) {
            console.log("Code: " + pageStatus);
            infoRectangle.visible = true;
            loading = false;
            return;
        }
        else {
            infoRectangle.visible = false;
        }

        // Parse image information.
        currentPageImageString = parseImage(obj);

        loading = false;
    }

    function loadPage(pageNum, subPageNum) {
        console.log("Page to be loaded: " + pageNum + "_" + subPageNum);

        if (loading && !initialLoad) {
            return;
        }

        loading = true;
        initialLoad = false;

        var urli = 'https://yle.fi/aihe/yle-ttv/json?P=';
        urli = urli + pageNum;
        urli = urli + "_";
        if (subPageNum < 10) {
            urli = urli + "0" + subPageNum;
        }
        else {
            urli = urli + subPageNum;
        }

        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === 4 && (xhr.status === 200 || xhr.status === 404)) {
                loadDone(xhr.responseText);
            }
        };
        xhr.open("GET", urli);
        xhr.setRequestHeader('User-Agent','Teksti-TV (Sailfish OS)');
        xhr.send();
    }

    function stepSubPage(step) {
        if (subPages == 1) {
            return;
        }

        var moveTo = currentSubPageNumber + step;

        // Went to previous sub page, but there aren't any.
        // Let's go to the last sub page.
        if (moveTo <= 0) {
            moveTo = subPages;
        }

        // Went to next sub page, but there aren't any.
        // Let's go to the first sub page.
        else if (moveTo > subPages) {
            moveTo = 1;
        }

        loadPage(currentPageNumber, moveTo);
    }

    function stepPage(forward) {
        // Next page
        if (forward) {
            if (currentPageNumber == 899) {
                currentPageNumber = 100;
            }
            else {
                currentPageNumber = nextPage;
            }
        }
        else { // Previous page
            if (currentPageNumber == 100) {
                currentPageNumber = 899;
            }
            else {
                currentPageNumber = previousPage;
            }
        }

        currentSubPageNumber = 1;
        pageNumberField.text = currentPageNumber;
    }

    function parseImage(json) {
        var imageSrc = json.data[0].content.image;
        imageSrc = imageSrc.substring(imageSrc.indexOf('"') + 1);
        imageSrc = imageSrc.substring(0, imageSrc.indexOf('"'));
        return imageSrc;
    }

    function parsePageData(json) {
        // Parse page status.
        if (json.meta.code) {
            console.log("Code exists: " + json.meta.code);
            pageStatus = Number(json.meta.code);
        }
        else {
            console.log("Code does not exist...");
            return;
        }

        // Check page status.
        if (pageStatus != 200) {
            return;
        }

        // Parse current page number.
        if (json.data[0].page.page) {
            currentPageNumber = Number(json.data[0].page.page);
        }

        // Parse current sub page number.
        if (json.data[0].page.subpage) {
            currentSubPageNumber = Number(json.data[0].page.subpage);
        }

        // Parse sub pages count.
        if (json.data[0].info.page.subpages) {
            subPages = json.data[0].info.page.subpages;
        }
        else if (updateSubPageCount) {
            subPages = 1;
        }

        if (!updateSubPageCount) {
            updateSubPageCount = true;
        }

        // Parse pagination.
        if (json.data[0].content.pagination) {
            var tmp = json.data[0].content.pagination;
            var indx = tmp.indexOf('href="?P=');
            var pageNum = "";
            if (indx >= 0)
            {
                tmp = tmp.substring(indx + 9);
                pageNum = tmp.substring(0, tmp.indexOf('"'));
                var num = Number(pageNum)

                if (num !== NaN)
                {
                    previousPage = num;
                }

                console.log("Previous page: " + previousPage);
            }

            indx = tmp.lastIndexOf('href="?P=');
            if (indx >= 0)
            {
                tmp = tmp.substring(indx + 9, indx + 12);
                var num2 = Number(tmp)

                if (num2 !== NaN)
                {
                    nextPage = num2;
                }

                console.log("Next page: " + nextPage);
            }
        }

        console.log("Current page: " + currentPageNumber);
        console.log("Current sub page: " + currentSubPageNumber);
        console.log("Sub pages: " + subPages);
    }

    function addFavorite(pageNumber, subPageNumber) {
        console.log("Add favorite: " + pageNumber);

        if (DB.doesFavoriteExist(pageNumber, subPageNumber)) {
            console.log("Favorite exists already...");
            return;
        }

        var favorite = {'itemId': -1, 'caption': pageNumber.toString(), 'pageNumber': pageNumber, 'subPageNumber': subPageNumber};
        var id = DB.addFavorite(favorite);
        if (id > 0) {
            favorite.itemId = id;
            var index = getIndex(pageNumber);
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

    function deleteFavorite(itemId, index) {
        console.log("Delete favorite: " + itemId);
        if (DB.deleteFavorite(itemId)) {
            favModel.remove(index);
        }
    }
}
