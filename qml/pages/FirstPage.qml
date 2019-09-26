import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: Orientation.All

    Component.onCompleted: {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            console.log("Ready state changed...");

            if (xhr.readyState === 4 && xhr.status === 200) {
                loadDone(xhr.responseText);
            }
        };
        xhr.open("GET", "https://yle.fi/aihe/yle-ttv/json?P=100_01");
        xhr.send();
    }

    // To enable PullDownMenu, place our content in a SilicaFlickable
    SilicaFlickable {
        anchors.fill: parent

        // PullDownMenu and PushUpMenu must be declared in SilicaFlickable, SilicaListView or SilicaGridView
        PullDownMenu {
            MenuItem {
                text: qsTr("Asetukset")
                onClicked: console.log("Ping...")
            }
        }

        // Tell SilicaFlickable the height of its content.
        contentHeight: column.height

        // Place our content in a Column.  The PageHeader is always placed at the top
        // of the page, followed by our content.
        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge
            PageHeader {
                title: qsTr("YLE teksti-tv")
            }
            Image {
                id: pageImage
                width: parent.width// - Theme.paddingMedium - Theme.paddingMedium
                sourceSize.width: width
                fillMode: Image.PreserveAspectFit

                onStatusChanged: {
                    if (status == Image.Ready) {
                        width = parent.width;
                        sourceSize.width = parent.width;
                    }
                }
            }
        }
    }

    function loadDone(responseText) {
        console.log("Loading done...");
        var obj = JSON.parse(responseText);
        console.log(obj.data[0].page.page);

        var imageSrc = obj.data[0].content.image;
        imageSrc = imageSrc.substring(imageSrc.indexOf('"') + 1);
        imageSrc = imageSrc.substring(0, imageSrc.indexOf('"'));
        pageImage.source = imageSrc;
    }
}
