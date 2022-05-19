import QtQuick 2.0
import Sailfish.Silica 1.0
import "pages"
import "cover"

ApplicationWindow
{
    SourcesPage {
        id: sourcesPage
    }

    initialPage: sourcesPage
    cover: coverPage
    allowedOrientations: Orientation.All //Orientation.Portrait

    CoverPage {
        id: coverPage
    }
}
