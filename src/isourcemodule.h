#ifndef ISOURCEMODULE_H
#define ISOURCEMODULE_H

#include <QObject>
#include <QString>

#include "sourcepage.h"

class ISourceModule : public QObject
{
    Q_OBJECT
public:
    ISourceModule();
    ~ISourceModule();

    Q_PROPERTY(QString code READ getCode)
    Q_PROPERTY(QString name READ getName)
    Q_PROPERTY(bool loading READ isLoading NOTIFY loadingChanged)
    Q_PROPERTY(SourcePage* currentPage READ getCurrentPage)
    Q_PROPERTY(QString pageName READ getPageName)
    Q_PROPERTY(bool supportsSubPages READ supportsSubPages)

    virtual QString getCode() const;
    virtual QString getName() const;
    virtual bool isLoading() const;
    virtual SourcePage* getCurrentPage();
    virtual QString getPageName() const;
    virtual bool supportsSubPages() const;

    Q_INVOKABLE virtual void loadInitialPage();
    Q_INVOKABLE virtual void loadPage(int pageNum, int subPageNum = 1);
    Q_INVOKABLE virtual void reloadCurrentPage();
    Q_INVOKABLE virtual void navPrevSubPage();
    Q_INVOKABLE virtual void navPrevPage();
    Q_INVOKABLE virtual void navNextPage();
    Q_INVOKABLE virtual void navNextSubPage();

signals:
    void pageLoaded(SourcePage *page);
    void loadingChanged(const bool& isLoading);
    void pageMissing();

private:
    QString _code;
    QString _name;
    bool _isLoading;
    SourcePage *_currentPage;
};

#endif // ISOURCEMODULE_H
