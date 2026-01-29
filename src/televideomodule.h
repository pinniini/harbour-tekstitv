#ifndef TELEVIDEOMODULE_H
#define TELEVIDEOMODULE_H

#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QJsonDocument>

#include "isourcemodule.h"
#include "sourcepage.h"

class TelevideoModule : public ISourceModule
{
    Q_OBJECT
public:
    TelevideoModule(QString region = "Nazionale");
    ~TelevideoModule();

    // ISourceModule interface
    QString getCode() const override;
    QString getName() const override;
    bool isLoading() const override;
    SourcePage *getCurrentPage() override;
    QString getPageName() const override;

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
    QString _region;
    QNetworkAccessManager* _manager;
    QNetworkReply* _reply;

    QDateTime _testDateTime;

    QUrl generateImageUrl();
    QUrl generateHtmlUrl();
    void cleanRequest();
    void setLoadingStatus(bool status);
    bool parsePageText(int page, QByteArray document, int status);
};

#endif // TELEVIDEOMODULE_H
