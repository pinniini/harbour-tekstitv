import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {
//    Label {
//        id: label
//        anchors.centerIn: parent
//        text: qsTr("Teksti-TV")
//    }

    Column {
        width: parent.width
        y: Theme.paddingMedium
        spacing: Theme.paddingSmall


        Image {
            id: coverImage
            x: Theme.paddingSmall
            width: parent.width - x*2
            height: width //* 0.72
            source: firstPage.currentPageImageString
        }

        Label {
            id: sourceLabel
            anchors.horizontalCenter: parent.horizontalCenter
            text: "YLE / " + firstPage.currentPageNumber
        }
    }

    CoverActionList {
        id: coverAction

        CoverAction {
            iconSource: "image://theme/icon-cover-previous"
            onTriggered: {
                firstPage.stepPage(false);
            }
        }

        CoverAction {
            iconSource: "image://theme/icon-cover-next"
            onTriggered: {
                firstPage.stepPage(true);
            }
        }
    }
}
