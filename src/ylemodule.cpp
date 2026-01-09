#include <QNetworkRequest>
#include <QDebug>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QtQml>

#include "ylemodule.h"

YleModule::YleModule(): ISourceModule()
{
    _code = "yle_fi";
    _name = "YLE";
    _isLoading = false;

    _page = nullptr;
    _pageNum = 100;
    _subPage = 1;
    _baseUrl = "https://yle.fi/aihe/yle-ttv/json?P=";
    _manager = new QNetworkAccessManager(this);

    _testDateTime = QDateTime::currentDateTime();
}

YleModule::~YleModule()
{
}

QString YleModule::getCode() const
{
    return _code;
}

QString YleModule::getName() const
{
    return _name;
}

bool YleModule::isLoading() const
{
    return _isLoading;
}

SourcePage *YleModule::getCurrentPage()
{
    return _page;
}

QString YleModule::getPageName() const
{
    if (_page != nullptr)
    {
        return QString("%1 %2 %3/%4").arg(_name).arg(QString::number(_page->page())).arg(QString::number(_page->subPage())).arg(QString::number(_page->subPageCount()));
    }
    else
    {
        return QString("%1").arg(_name);
    }
}

bool YleModule::supportsSubPages() const
{
    return true;
}

void YleModule::loadInitialPage()
{
    loadPage(100, 1);
}

void YleModule::loadPage(int pageNum, int subPageNum)
{
    _testDateTime = QDateTime::currentDateTimeUtc();
    qDebug() << "Start page loading...";

    if (pageNum < 100 || pageNum > 899 || subPageNum < 1)
    {
        qDebug() << "Invalid page number...";
    }

    _pageNum = pageNum;
    _subPage = subPageNum;

    setLoadingStatus(true);

    qDebug() << "Duration before network request: " << _testDateTime.msecsTo(QDateTime::currentDateTimeUtc()) << "ms...";
    _testDateTime = QDateTime::currentDateTimeUtc();

    QNetworkRequest request(generateUrl());
    request.setHeader(QNetworkRequest::UserAgentHeader, "sailfish/pinniini/tekstitv");
    _reply = _manager->get(request);

    //connect(_reply, SIGNAL(error(QNetworkReply::NetworkError)), this, SLOT(errorLoadingData(QNetworkReply::NetworkError)));
    connect(_reply, SIGNAL(finished()), this, SLOT(pageLoadingFinished()));
}

void YleModule::reloadCurrentPage()
{
    loadPage(_page->page(), _page->subPage());
}

void YleModule::navPrevSubPage()
{
    int prevSubPage = _page->subPage() - 1;
    if (prevSubPage < 1)
    {
        prevSubPage = _page->subPageCount();
    }
    loadPage(_page->page(), prevSubPage);
}

void YleModule::navPrevPage()
{
    int pnum = _page->previousPage();
    qDebug() << "Navigate to previous page which is " << pnum;
    if (pnum == _page->page())
    {
        pnum = 899;
    }
    loadPage(pnum, 1);
}

void YleModule::navNextPage()
{
    int pnum = _page->nextPage();
    qDebug() << "Navigate to next page which is " << pnum;
    if (pnum == _page->page())
    {
        pnum = 100;
    }
    loadPage(pnum, 1);
}

void YleModule::navNextSubPage()
{
    int nextSubPage = _page->subPage() + 1;
    if (nextSubPage > _page->subPageCount())
    {
        nextSubPage = 1;
    }
    loadPage(_page->page(), nextSubPage);
}

void YleModule::pageLoadingFinished()
{
    qDebug() << "Network request duration: " << _testDateTime.msecsTo(QDateTime::currentDateTimeUtc()) << "ms...";
    _testDateTime = QDateTime::currentDateTimeUtc();

    qDebug() << "Page loaded...";
    qDebug() << _reply->errorString();

    // Check for errors. These should be already reported by error-signal.
    if (_reply->error() != QNetworkReply::NoError)
    {
        cleanRequest();
        setLoadingStatus(false);
        emit pageMissing();
        return;
    }

//    QString pageData = QString::fromLatin1(_reply->readAll());
    //qDebug() << pageData;

    // Parse json
    QJsonDocument document(QJsonDocument::fromJson(_reply->readAll()));
    if (!parsePageJson(_pageNum, _subPage, document, _subPage != 1))
    {

    }
    else
    {

    }

    qDebug() << "Request handling duration: " << _testDateTime.msecsTo(QDateTime::currentDateTimeUtc()) << "ms...";
    setLoadingStatus(false);

    //emit pageLoaded("This should be the page image.");
    emit pageLoaded(_page);
}

/*
 * Private
 */

QUrl YleModule::generateUrl()
{
    QString tmp = _baseUrl + QString::number(_pageNum) + "_00";
    if (_subPage < 10)
    {
        tmp += "0";
    }

    tmp += QString::number(_subPage);

    return QUrl(tmp);
}

void YleModule::cleanRequest()
{
    // Clean stuff.
//    disconnect(_reply, SIGNAL(error(QNetworkReply::NetworkError)), this, SLOT(errorLoadingData(QNetworkReply::NetworkError)));
    disconnect(_reply, SIGNAL(finished()), this, SLOT(pageLoadingFinished()));
    delete _reply;
    _reply = 0;
}

void YleModule::setLoadingStatus(bool status)
{
    if (_isLoading != status)
    {
        _isLoading = status;
        emit loadingChanged(_isLoading);
    }
}

//!
//! \brief YleModule::parsePageJson
//! \param document
//! \return False if page does not exist or parsing fails.
//!
bool YleModule::parsePageJson(int page, int subPage, QJsonDocument &document, bool parseSubPage)
{
    int status = -1;
    int subPageCount = 1;
    int prevPage = 0;
    int nextPage = 0;
    QString image = "";

    if (parseSubPage && _page != nullptr)
    {
        qDebug() << "We should parse sub page info...";
        subPageCount = _page->subPageCount();
    }

    QJsonObject obj = document.object();
    if (obj.contains("meta") && obj.value("meta").isObject() && obj.value("meta").toObject().contains("code"))
    {
        qDebug() << "Page json status: " << obj.value("meta").toObject().value("code").toString();
        status = obj.value("meta").toObject().value("code").toString().toInt();
    }

    if (obj.contains("data") && obj.value("data").isArray())
    {
        QJsonArray data = obj.value("data").toArray();
        if (data.count() > 0)
        {
            QJsonObject pageObj = data[0].toObject();

            // page (pagenum, subpagenum)
            if (pageObj.contains("page") && pageObj.value("page").isObject())
            {

            }

            // info (number, name, label, subpagecount)
            if (pageObj.contains("info") && pageObj.value("info").isObject() && pageObj.value("info").toObject().contains(("page")) && pageObj.value("info").toObject().value("page").isObject())
            {
                QJsonObject infoPage = pageObj.value("info").toObject().value("page").toObject();
                if (infoPage.contains("subpages"))
                {
                    subPageCount = infoPage.value("subpages").toString().toInt();
                    qDebug() << "Sub page count: " << subPageCount;
                }
            }

            // content (text, image, image map, pagination)
            if (pageObj.contains("content") && pageObj.value("content").isObject())
            {
                QJsonObject content = pageObj.value("content").toObject();
                if (content.contains("image"))
                {
                    qDebug() << "Found the page image...";
                    QString tmp = content.value("image").toString();
                    int startIndex = tmp.indexOf("\"") + 1;
                    int length = tmp.indexOf("\"", startIndex) - startIndex;
                    image = tmp.mid(startIndex, length);
                }

                if (content.contains("pagination"))
                {
                    qDebug() << "Found the page pagination...";
                    QString pagination = content.value("pagination").toString();
                    int indx = pagination.indexOf("href=\"?P=");
                    QString pageNum = "";
                    if (indx >= 0)
                    {
                        pagination = pagination.mid(indx + 9);
                        pageNum = pagination.left(3);
                        int num = pageNum.toInt();

                        if (num != 0)
                        {
                            prevPage = num;
                        }

                        qDebug() << "Previous page: " << prevPage;
                    }

                    indx = pagination.lastIndexOf("href=\"?P=");
                    if (indx >= 0)
                    {
                        pageNum = "";
                        pageNum = pagination.mid(indx + 9, 3);
                        int num2 = pageNum.toInt();

                        if (num2 != 0)
                        {
                            nextPage = num2;
                        }

                        qDebug() << "Next page: " << nextPage;
                    }
                }
            }
        }
        else
        {
            qDebug() << "No page data, page does not exist...";
        }
    }

    // Clear old page.
    if (_page != nullptr)
    {
        delete _page;
        _page = nullptr;
    }

    _page = new SourcePage(status, _pageNum, _subPage, subPageCount, prevPage, nextPage, image, this);
    // This is necessary, so that the js engine won't garbage collect the object after using get-method.
    // Because the ownership moves to the js engine if we return the object from here to there.
    QQmlEngine::setObjectOwnership(_page, QQmlEngine::CppOwnership);

//    return true;
    return status == 200;
}
