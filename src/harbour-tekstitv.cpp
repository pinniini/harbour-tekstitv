#ifdef QT_QML_DEBUG
#include <QtQuick>
#endif

#include <QtQml>
#include <sailfishapp.h>

#include "isourcemodule.h"
#include "ylemodule.h"
#include "sourcemodel.h"
#include "sourcepage.h"

int main(int argc, char *argv[])
{
    // SailfishApp::main() will display "qml/harbour-tekstitv.qml", if you need more
    // control over initialization, you can use:
    //
    //   - SailfishApp::application(int, char *[]) to get the QGuiApplication *
    //   - SailfishApp::createView() to get a new QQuickView * instance
    //   - SailfishApp::pathTo(QString) to get a QUrl to a resource file
    //   - SailfishApp::pathToMainQml() to get a QUrl to the main QML file
    //
    // To display the view, call "show()" (will show fullscreen on device).

//    return SailfishApp::main(argc, argv);

    QScopedPointer<QGuiApplication> a(SailfishApp::application(argc, argv));
    QScopedPointer<QQuickView> view(SailfishApp::createView());

    qmlRegisterType<ISourceModule>("fi.pinniini.tekstitv", 1, 0, "SourceModule");
    qmlRegisterType<SourceModel>("fi.pinniini.tekstitv", 1, 0, "SourceModel");
    qmlRegisterType<SourcePage>("fi.pinniini.tekstitv", 1, 0, "SourcePage");

    view->rootContext()->setContextProperty("appVersion", "0.1" /*APP_VERSION*/);
    view->setSource(SailfishApp::pathToMainQml());
    view->show();
    return a->exec();
}
