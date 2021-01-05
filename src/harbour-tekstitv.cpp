#include <QtQuick>
#include <QtQml>
#include <sailfishapp.h>

#include "isourcemodule.h"
#include "ylemodule.h"
#include "sourcemodel.h"
#include "sourcepage.h"

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> a(SailfishApp::application(argc, argv));
    QScopedPointer<QQuickView> view(SailfishApp::createView());

    qmlRegisterType<ISourceModule>("fi.pinniini.tekstitv", 1, 0, "SourceModule");
    qmlRegisterType<SourceModel>("fi.pinniini.tekstitv", 1, 0, "SourceModel");
    qmlRegisterType<SourcePage>("fi.pinniini.tekstitv", 1, 0, "SourcePage");

    view->rootContext()->setContextProperty("appVersion", "1.1");
    view->setSource(SailfishApp::pathToMainQml());
    view->show();
    return a->exec();
}
