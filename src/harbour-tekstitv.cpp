#include <QtQuick>
#include <QtQml>
#include <sailfishapp.h>

#include "isourcemodule.h"
#include "ylemodule.h"
#include "sourcemodel.h"
#include "sourcepage.h"
#include "migrator.h"

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> a(SailfishApp::application(argc, argv));
    QScopedPointer<QQuickView> view(SailfishApp::createView());

    a->setOrganizationDomain("pinniini.fi");
    a->setOrganizationName("fi.pinniini"); // needed for Sailjail
    a->setApplicationName("TekstiTV");

    // Migrate configs and data.
    Migrator migrator("harbour-tekstitv");
    bool migrationStatus = migrator.migrate();
    QString migrationError = "";
    if (!migrationStatus)
    {
        migrationError = migrator.lastError();
        qDebug() << "Error occured while migrating configurations to comply with SailJail." << migrationError;
    }

    qmlRegisterType<ISourceModule>("fi.pinniini.tekstitv", 1, 0, "SourceModule");
    qmlRegisterType<SourceModel>("fi.pinniini.tekstitv", 1, 0, "SourceModel");
    qmlRegisterType<SourcePage>("fi.pinniini.tekstitv", 1, 0, "SourcePage");

    view->rootContext()->setContextProperty("appVersion", "1.4.0");
    view->setSource(SailfishApp::pathToMainQml());
    view->show();
    return a->exec();
}
