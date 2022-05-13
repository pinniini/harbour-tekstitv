#ifndef MIGRATOR_H
#define MIGRATOR_H

#include <QString>

class Migrator
{
public:
    Migrator(QString oldAppName);

    bool migrate();
    QString lastError();
    QString configFile() const;
    QString dataPath() const;

private:
    QString _oldAppName;
    QString _lastError;
};

#endif // MIGRATOR_H
