import QtQuick 2.5
import Sailfish.Silica 1.0

import "../js/database.js" as DB

Page {
    id: pageViewer

    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: Orientation.All

    property string pageSource: ""
    property double scaleFactor: 1.5
    property double zoomLevel: 1.5
    property bool continuousZoom: false

    Component.onCompleted: {
        var initialZoomLevel = DB.getSetting("DefaultZoomLevel", "default")
        if (initialZoomLevel !== null) {
            scaleFactor = initialZoomLevel.value
            zoomLevel = scaleFactor
        }
    }

    // To enable PullDownMenu, place our content in a SilicaFlickable
    SilicaFlickable {
        id: viewerFlick
        anchors.fill: parent

        // Tell SilicaFlickable the height of its content.
        contentHeight: pageImage.height
        contentWidth: pageImage.width

        Item {
            id: placeholder
            height: pageImage.height > pageViewer.height ? pageImage.height : pageViewer.height
            width: pageImage.width > pageViewer.width ? pageImage.width : pageViewer.width

            Image {
                id: pageImage
                source: pageSource
                anchors.centerIn: parent
                autoTransform: true
                asynchronous: true
                fillMode: Image.PreserveAspectFit
                width: pageViewer.width * scaleFactor
                height: width / (sourceSize.width / sourceSize.height)

                Behavior on width {
                    id: zoomBehavior
                    enabled: false
                    NumberAnimation {duration: 300; easing.type: Easing.InOutQuad }
                }
            }

            PinchArea {
                anchors.fill: parent
                pinch.target: pageImage
                onPinchUpdated: {
                    var delta = pinch.scale - pinch.previousScale
                    pageViewer.scaleFactor += delta

                    if (pageViewer.scaleFactor < 1) {
                        pageViewer.scaleFactor = 1
                    } else if (pageViewer.scaleFactor > 5) {
                        pageViewer.scaleFactor = 5
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onDoubleClicked: {
                        zoomBehavior.enabled = true
                        if (pageViewer.scaleFactor == 1.0) {
                            pageViewer.scaleFactor = pageViewer.zoomLevel
                        } else {
                            pageViewer.scaleFactor = 1.0
                        }
                        zoomBehavior.enabled = false
                    }
                }
            }
        }
    }
}
