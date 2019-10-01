import QtQuick 2.0
import Sailfish.Silica 1.0
import "pages"
import "cover"

ApplicationWindow
{
//    initialPage: Component { FirstPage { } }
//    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    initialPage: firstPage
    cover: coverPage
    allowedOrientations: Orientation.Portrait

    FirstPage {
        id: firstPage
    }

    CoverPage {
        id: coverPage
    }
}
