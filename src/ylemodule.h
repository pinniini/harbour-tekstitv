#ifndef YLEMODULE_H
#define YLEMODULE_H

#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QJsonDocument>

#include "isourcemodule.h"
#include "sourcepage.h"

class YleModule : public ISourceModule
{
    Q_OBJECT
public:
    YleModule();
    ~YleModule();

    // ISourceModule interface
    QString getCode() const override;
    QString getName() const override;
    bool isLoading() const override;
    SourcePage *getCurrentPage() override;
    QString getPageName() const override;

    Q_INVOKABLE void loadInitialPage();
    Q_INVOKABLE void loadPage(int pageNum, int subPageNum) override;
    Q_INVOKABLE void reloadCurrentPage() override;
    Q_INVOKABLE void navPrevSubPage() override;
    Q_INVOKABLE void navPrevPage() override;
    Q_INVOKABLE void navNextPage() override;
    Q_INVOKABLE void navNextSubPage() override;

public slots:
    void pageLoadingFinished();

signals:
    //void pageLoaded(const QString &pageSource);
    //void loadingChanged(const bool &isLoading);

private:
    QString _code;
    QString _name;
    bool _isLoading;

    SourcePage *_page;
//    int _prevPage;
    int _pageNum;
//    int _nextPage;
    int _subPage;
//    int _subPageCount;
    QString _baseUrl;
    QNetworkAccessManager* _manager;
    QNetworkReply* _reply;

    QDateTime _testDateTime;

    QUrl generateUrl();
    void cleanRequest();
    void setLoadingStatus(bool status);
    bool parsePageJson(int page, int subPage, QJsonDocument &document, bool parseSubPage = false);
};

#endif // YLEMODULE_H
