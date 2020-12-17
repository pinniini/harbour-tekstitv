import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {
    property alias coverConnections: conn

    Image {
        id: coverBackground
        anchors.centerIn: parent
        source: "cover.png"
        visible: !sourcesPage.currentSource
        width: parent.width - Theme.paddingLarge
        fillMode: Image.PreserveAspectFit
    }

    Column {
        width: parent.width
        y: Theme.paddingMedium
        spacing: Theme.paddingSmall


        Image {
            id: coverImage
            x: Theme.paddingSmall
            width: parent.width - x*2
            height: width //* 0.72
        }

        Label {
            id: sourceLabel
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    CoverActionList {
        id: coverAction

        CoverAction {
            iconSource: "image://theme/icon-cover-previous"
            onTriggered: {
                sourcesPage.navigatePage(false);
            }
        }

        CoverAction {
            iconSource: "image://theme/icon-cover-next"
            onTriggered: {
                sourcesPage.navigatePage(true);
            }
        }
    }

    Connections {
        id: conn
        target: sourcesPage.currentSource

        onPageLoaded: {
            console.log("Cover - onPageLoaded...");
            if (page) {
                coverImage.source = page.pageImage
                sourceLabel.text = sourcesPage.currentSource.pageName
            }
        }
    }
}
