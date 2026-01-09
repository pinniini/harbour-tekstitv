#ifndef SVTMODULE_H
#define SVTMODULE_H

#include <QNetworkAccessManager>
#include <QNetworkReply>

#include "isourcemodule.h"
#include "sourcepage.h"

class SvtModule : public ISourceModule
{
    Q_OBJECT
public:
    SvtModule();
    ~SvtModule();

    // ISourceModule interface
    QString getCode() const override;
    QString getName() const override;
    bool isLoading() const override;
    SourcePage *getCurrentPage() override;
    QString getPageName() const override;
    bool supportsSubPages() const override;

    Q_INVOKABLE void loadInitialPage() override;
    Q_INVOKABLE void loadPage(int pageNum, int subPageNum) override;
    Q_INVOKABLE void reloadCurrentPage() override;
    Q_INVOKABLE void navPrevSubPage() override;
    Q_INVOKABLE void navPrevPage() override;
    Q_INVOKABLE void navNextPage() override;
    Q_INVOKABLE void navNextSubPage() override;

public slots:
    void pageLoadingFinished();

private:
    QString _code;
    QString _name;
    bool _isLoading;

    SourcePage *_page;
    int _pageNum;
    int _subPage;
    QString _baseUrl;
    QString _baseImageUrl;
    QNetworkAccessManager* _manager;
    QNetworkReply* _reply;

    QUrl generateUrl(const QString& base);
    void cleanRequest();
    void setLoadingStatus(bool status);

    bool parsePageText(QString &document);
    void parsePreviousPages(QString &document, int &previousPage, int &previousSubPage);
    void parseNextPages(QString &document, int &nextPage, int &nextSubPage);
};

#endif // SVTMODULE_H
