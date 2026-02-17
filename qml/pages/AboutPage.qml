import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: aboutPage

    allowedOrientations: Orientation.All

    property string issuesText: qsTr("Löysitkö virheen? Onko sinulla hyviä kehitysideoita? Raportoi ne github:iin ja minä katson ne mielelläni läpi :)")
    property string generalAboutText: qsTr("Tämä on helppokäyttöinen teksti-tv sovellus. Tällä hetkellä sovellus tukee YLE:n ja Italian Televideo teksti-tv:tä. Muita lähteitä saatan lisätä tulevaisuudessa (mikäli tiedot on helposti saatavilla). Sovellus on avointa lähdekoodia ja koodit löytyvät github:sta.")

    Component.onCompleted: {
        issueLabel.text = Theme.highlightText(issuesText, "github", Theme.highlightColor)

        console.log(pageStack)
    }

    SilicaFlickable {
        id: aboutFlick
        anchors.fill: parent

        contentHeight: contentColumn.height

        // Place page content to a column.
        Column {
            id: contentColumn

            width: aboutPage.width
            spacing: Theme.paddingLarge
            PageHeader {
                title: qsTr("Tietoja")
            }

            SectionHeader {
                text: qsTr("Info")
            }

            Label {
                id: generalAboutLabel
                text: generalAboutText
                wrapMode: Text.Wrap
                width: parent.width - Theme.paddingMedium - Theme.paddingMedium
                textFormat: Text.AutoText
                x: Theme.paddingMedium
            }

            Label {
                text: qsTr("Versio ") + appVersion
                x: Theme.paddingMedium
            }

            SectionHeader {
                text: qsTr("Tekijä")
            }

            Label {
                text: qsTr("pinniini (Joni Korhonen)")
                x: Theme.paddingMedium
                wrapMode: Text.Wrap
                width: parent.width - Theme.paddingMedium
            }

            SectionHeader {
                text: qsTr("Lähdekoodin lisenssi")
            }

            Label {
                text: "MIT"
                font.underline: true
                x: Theme.paddingMedium
                MouseArea {
                    anchors.fill: parent
                    onClicked: Qt.openUrlExternally("https://opensource.org/licenses/MIT")
                }
            }

            SectionHeader {
                text: qsTr("Lähdekoodi")
            }

            Label {
                text: "https://github.com/pinniini/harbour-tekstitv"
                font.underline: true
                wrapMode: Text.Wrap
                width: parent.width - Theme.paddingMedium
                x: Theme.paddingMedium
                MouseArea {
                    anchors.fill: parent
                    onClicked: Qt.openUrlExternally("https://github.com/pinniini/harbour-tekstitv")
                }
            }

            SectionHeader {
                text: qsTr("Kiitokset")
            }

            Label {
                id: italianTranslationLabel
                wrapMode: Text.Wrap
                width: parent.width - Theme.paddingMedium
                x: Theme.paddingMedium
                text: qsTr("Italiankieliset käännökset: Francesco Gazzetta (fgaz)")
                MouseArea {
                    anchors.fill: parent
                    onClicked: Qt.openUrlExternally("https://github.com/eson57")
                }
            }

            SectionHeader {
                text: qsTr("Ideoita/Ongelmia/Haluatko auttaa")
            }

            Label {
                id: issueLabel
                textFormat: Text.AutoText
                wrapMode: Text.Wrap
                width: parent.width - Theme.paddingMedium - Theme.paddingMedium
                x: Theme.paddingMedium

                MouseArea {
                    anchors.fill: parent
                    onClicked: Qt.openUrlExternally("https://github.com/pinniini/harbour-tekstitv/issues")
                }
            }
        }
    }
}
