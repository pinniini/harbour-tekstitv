#include <QtQml>

#include "sourcemodel.h"
#include "ylemodule.h"
#include "mtvmodule.h"
#include "televideomodule.h"

SourceModel::SourceModel(QObject *parent) : QAbstractListModel(parent)
{
    _sources = new QList<ISourceModule *>();

    // Add YLE module.
    YleModule *yle = new YleModule();
    // This is necessary, so that the js engine won't garbage collect the object after using get-method.
    // Because the ownership moves to the js engine if we return the object from here to there.
    QQmlEngine::setObjectOwnership(yle, QQmlEngine::CppOwnership);
    _sources->append(yle);

    // Add MTV module.
    MtvModule *mtv = new MtvModule();
    // This is necessary, so that the js engine won't garbage collect the object after using get-method.
    // Because the ownership moves to the js engine if we return the object from here to there.
    QQmlEngine::setObjectOwnership(mtv, QQmlEngine::CppOwnership);
    _sources->append(mtv);

    // Add Televideo module.
    TelevideoModule *televideo = new TelevideoModule();
    // This is necessary, so that the js engine won't garbage collect the object after using get-method.
    // Because the ownership moves to the js engine if we return the object from here to there.
    QQmlEngine::setObjectOwnership(televideo, QQmlEngine::CppOwnership);
    _sources->append(televideo);

    // Add Regional Televideo modules.
    QList<QString> regions = {
        "Abruzzo",
        "Altoadige",
        "Basilicata",
        "Calabria",
        "Campania",
        "Emilia",
        "Friuli",
        "Lazio",
        "Liguria",
        "Lombardia",
        "Marche",
        "Molise",
        "Piemonte",
        "Puglia",
        "Sardegna",
        "Sicilia",
        "Toscana",
        "Trentino",
        "Umbria",
        "Aosta",
        "Veneto",
    };
    foreach (QString region, regions)
    {
        TelevideoModule *regionalTelevideo = new TelevideoModule(region);
        // This is necessary, so that the js engine won't garbage collect the object after using get-method.
        // Because the ownership moves to the js engine if we return the object from here to there.
        QQmlEngine::setObjectOwnership(regionalTelevideo, QQmlEngine::CppOwnership);
        _sources->append(regionalTelevideo);
    }
}

SourceModel::~SourceModel()
{
    if (_sources)
    {
        for (int i = 0; i < _sources->length(); ++i)
        {
            if (_sources->at(i))
            {
                delete _sources->at(i);
                _sources->replace(i, nullptr);
            }
        }

        delete _sources;
        _sources = nullptr;
    }
}

int SourceModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)

    if (_sources)
    {
        return _sources->length();
    }
    else
    {
        return 0;
    }
}

QVariant SourceModel::data(const QModelIndex &index, int role) const
{
    // Validate index.
    if (index.isValid())
    {
        switch (role) {
        case NameRole:
            return QVariant(_sources->at(index.row())->getName());
        case CodeRole:
            return QVariant(_sources->at(index.row())->getCode());
        default:
            return QVariant();
        }
    }
    else // Invalid index, return empty.
    {
        return QVariant();
    }
}

QHash<int, QByteArray> SourceModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[NameRole] = "name";
    roles[CodeRole] = "code";
    return roles;
}

ISourceModule *SourceModel::get(int index)
{
    if (_sources == nullptr || index < 0 || index >= _sources->length())
    {
        return nullptr;
    }

    return _sources->at(index);
}
