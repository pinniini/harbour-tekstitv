#ifndef SOURCEMODEL_H
#define SOURCEMODEL_H

#include <QObject>
#include <QAbstractListModel>
#include <QList>

#include "isourcemodule.h"

class SourceModel : public QAbstractListModel
{
    Q_OBJECT
public:
    enum SourceRoles
    {
        NameRole = Qt::UserRole + 1
    };

    explicit SourceModel(QObject *parent = 0);
    ~SourceModel();

    // QAbstractItemModel interface
    virtual int rowCount(const QModelIndex &parent) const;
    virtual QVariant data(const QModelIndex &index, int role) const;
    QHash<int, QByteArray> roleNames() const;

    Q_INVOKABLE ISourceModule* get(int index);

private:
    QList<ISourceModule *> *_sources;
};

#endif // SOURCEMODEL_H
