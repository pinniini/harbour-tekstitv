import QtQuick 2.5
import Sailfish.Silica 1.0

import fi.pinniini.tekstitv 1.0
import "../js/database.js" as DB

Page {
    id: settingsPage

    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: Orientation.All

    property SourceModel sourceModel
    property double zoomLevel: 1.5

    Component.onCompleted: {
        var initialSource = DB.getSetting("InitialSource", "default");
        if (initialSource !== null) {
            for(var i = 0; i < defaultSourceContext.children.length; ++i)
            {
                var child = defaultSourceContext.children[i]
                if(child.hasOwnProperty("codeProp"))
                {
                    // Default source found.
                    if(child.codeProp === initialSource.value)
                    {
                        defaultSourceCombo.currentIndex = i
                        break
                    }
                }
            }
        }

        var initialZoomLevel = DB.getSetting("DefaultZoomLevel", "default")
        if (initialZoomLevel !== null) {
            zoomLevel = initialZoomLevel.value
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        clip: true
        contentHeight: contentColumn.height

        Column {
            id: contentColumn
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                id: pageHeader
                title: qsTr("Asetukset")
            }

            SectionHeader {
                id: settingsHeaderSource
                text: qsTr("Lähde")
            }

            ComboBox {
                id: defaultSourceCombo
                label: qsTr("Oletuslähde")
                description: qsTr("Lähde, jonka aloitussivu ladataan automaattisesti kun sovellus avataan.")

                menu: ContextMenu {
                    id: defaultSourceContext

                    MenuItem {
                        text: qsTr("Ei mikään")
                        onClicked: {
                            DB.deleteInitialSource();
                        }
                    }

                    Repeater {
                        model: sourceModel
                        MenuItem {
                            property string codeProp: code
                            text: name
                            onClicked: {
                                DB.upsertSetting('InitialSource', codeProp, "default");
                            }
                        }
                    }
                }
            }

            SectionHeader {
                id: settingsHeaderPageViewer
                text: qsTr("Sivunkatselin")
            }

            Slider {
                id: defaultZoomSlider
                width: parent.width
                minimumValue: 1
                maximumValue: 5
                value: zoomLevel
                stepSize: 0.5
                valueText: value + " kertainen"
                label: qsTr("Oletustarkennus")

                onReleased: {
                    DB.upsertSetting("DefaultZoomLevel", value, "default")
                }
            }
        }
    }
}
