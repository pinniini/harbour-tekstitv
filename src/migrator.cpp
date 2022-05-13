#include "migrator.h"

#include <QCoreApplication>
#include <QDebug>
#include <QStandardPaths>
#include <QFileInfo>
#include <QDir>
#include <QFile>
#include <QDirIterator>

Migrator::Migrator(QString oldAppName)
    : _oldAppName(oldAppName), _lastError("")
{
}

bool Migrator::migrate()
{
    bool retValue = true;

    // Old paths.
    QString oldAppDataPath = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + QDir::separator() + _oldAppName + QDir::separator() + _oldAppName;
    QString oldCachePath = "";
    QString oldConfigPath = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation) + QDir::separator() + _oldAppName + QDir::separator() + _oldAppName + ".conf";

    qDebug() << "Old config path:" << oldConfigPath;
    qDebug() << "Old data path:" << oldAppDataPath;

    // Current paths.
    QString currentAppDataPath = dataPath();
    QString currentCachePath = QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
    QString currentConfigPath = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation);
    QString currentConfigFile = configFile();

    qDebug() << "Current config path:" << currentConfigPath;
    qDebug() << "Current data path:" << currentAppDataPath;

    // Handle config file migration
    if ((!QFileInfo(currentConfigFile).exists() && !QDir(currentConfigFile).exists()) &&
            (QFileInfo(oldConfigPath).exists() && !QDir(oldConfigPath).exists()))
    {
        QDir configDir = QDir(currentConfigPath);
        if (!configDir.exists())
        {
            retValue = configDir.mkpath(currentConfigPath);
            if (!retValue)
            {
                _lastError = "Could not create new config directory.";
            }
        }

        qDebug() << "Renaming/moving old config file to new location...";
        retValue = QFile::rename(oldConfigPath, currentConfigFile);
        if (!retValue)
        {
            _lastError = "Could not copy old config file as new one...";
        }
    }

    // Handle app data
    // NOTE! For some reason cannot use filters for iterator. Using NoDot, NoDotDot or NoDotAndDotDot
    // results in empty iterator.
    QDirIterator it(oldAppDataPath, QDirIterator::Subdirectories);
    while (it.hasNext())
    {
        QString dir = it.next();
        if (!dir.endsWith("."))
        {
            QFileInfo sourceInfo(dir);

            dir.remove(oldAppDataPath);
            dir.prepend(currentAppDataPath);
            QDir tmpDir(dir);
            QFileInfo tmpInfo(dir);
            if (sourceInfo.isDir() && !tmpDir.exists())
            {
                tmpDir.mkpath(dir);
            }
            else if (!sourceInfo.isDir() && sourceInfo.isFile())
            {
                QFile::rename(sourceInfo.absoluteFilePath(), dir);
            }
        }
    }

    return retValue;
}

QString Migrator::lastError()
{
    return _lastError;
}

QString Migrator::configFile() const
{
    return QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation)
            + QDir::separator() + QCoreApplication::applicationName() + ".conf";
}

QString Migrator::dataPath() const
{
    return QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
}
