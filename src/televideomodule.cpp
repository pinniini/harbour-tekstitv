#include <QNetworkRequest>
#include <QDebug>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QtQml>

#include "televideomodule.h"


TelevideoModule::TelevideoModule(QString region): ISourceModule()
{
    _code = "televideo_" + region.toLower();
    _name = "Televideo " + region;
    _isLoading = false;

    _page = nullptr;
    _pageNum = -1;
    _subPage = -1;
    _baseUrl = "https://www.televideo.rai.it/televideo/pub";
    _region = region;
    _manager = new QNetworkAccessManager(this);

    _testDateTime = QDateTime::currentDateTime();
}

TelevideoModule::~TelevideoModule()
{
}

QString TelevideoModule::getCode() const
{
    return _code;
}

QString TelevideoModule::getName() const
{
    return _name;
}

bool TelevideoModule::isLoading() const
{
    return _isLoading;
}

SourcePage *TelevideoModule::getCurrentPage()
{
    return _page;
}

QString TelevideoModule::getPageName() const
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

void TelevideoModule::loadInitialPage()
{
    // Regional Televideo has a different index page
    loadPage(_region == "Nazionale" ? 100 : 300, 1);
}

void TelevideoModule::loadPage(int pageNum, int subPageNum)
{
    _testDateTime = QDateTime::currentDateTimeUtc();
    qDebug() << "Start page loading...";

    if (pageNum < 100 || pageNum > 899 || subPageNum < 1)
    {
        qDebug() << "Invalid page number...";
    }

    // TODO we should perform the html request only when necessary.
    //bool refreshSubPageCount = pageNum != _pageNum;

    _pageNum = pageNum;
    _subPage = subPageNum;

    setLoadingStatus(true);

    qDebug() << "Duration before network request: " << _testDateTime.msecsTo(QDateTime::currentDateTimeUtc()) << "ms...";
    _testDateTime = QDateTime::currentDateTimeUtc();

    QNetworkRequest request(generateHtmlUrl());
    request.setHeader(QNetworkRequest::UserAgentHeader, "sailfish/pinniini/tekstitv");
    _reply = _manager->get(request);

    //connect(_reply, SIGNAL(error(QNetworkReply::NetworkError)), this, SLOT(errorLoadingData(QNetworkReply::NetworkError)));
    connect(_reply, SIGNAL(finished()), this, SLOT(pageLoadingFinished()));
}

void TelevideoModule::reloadCurrentPage()
{
    loadPage(_page->page(), _page->subPage());
}

void TelevideoModule::navPrevSubPage()
{
    int prevSubPage = _page->subPage() - 1;
    if (prevSubPage < 1)
    {
        prevSubPage = _page->subPageCount();
    }
    loadPage(_page->page(), prevSubPage);
}

void TelevideoModule::navPrevPage()
{
    int pnum = _page->previousPage();
    qDebug() << "Navigate to previous page which is " << pnum;
    if (pnum == _page->page())
    {
        pnum = 899;
    }
    loadPage(pnum, 1);
}

void TelevideoModule::navNextPage()
{
    int pnum = _page->nextPage();
    qDebug() << "Navigate to next page which is " << pnum;
    if (pnum == _page->page())
    {
        pnum = 100;
    }
    loadPage(pnum, 1);
}

void TelevideoModule::navNextSubPage()
{
    int nextSubPage = _page->subPage() + 1;
    if (nextSubPage > _page->subPageCount())
    {
        nextSubPage = 1;
    }
    loadPage(_page->page(), nextSubPage);
}

void TelevideoModule::pageLoadingFinished()
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

    parsePageText(_pageNum, _reply->readAll(), _reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt());

    qDebug() << "Request handling duration: " << _testDateTime.msecsTo(QDateTime::currentDateTimeUtc()) << "ms...";
    setLoadingStatus(false);

    emit pageLoaded(_page);
}

/*
 * Private
 */

QUrl TelevideoModule::generateImageUrl()
{
    QString tmp = _baseUrl + "/tt4web/" + _region + "/page-" + QString::number(_pageNum);
    if (_subPage != 1)
    {
        tmp += "." + QString::number(_subPage);
    }
    tmp += ".png";
    return QUrl(tmp);
}

QUrl TelevideoModule::generateHtmlUrl()
{
    return QUrl(_baseUrl + "/popupTelevideo.jsp?pagetocall=popupTelevideo.jsp&r=" + _region + "&p=" + QString::number(_pageNum));
}

void TelevideoModule::cleanRequest()
{
    // Clean stuff.
//    disconnect(_reply, SIGNAL(error(QNetworkReply::NetworkError)), this, SLOT(errorLoadingData(QNetworkReply::NetworkError)));
    disconnect(_reply, SIGNAL(finished()), this, SLOT(pageLoadingFinished()));
    delete _reply;
    _reply = 0;
}

void TelevideoModule::setLoadingStatus(bool status)
{
    if (_isLoading != status)
    {
        _isLoading = status;
        emit loadingChanged(_isLoading);
    }
}

bool TelevideoModule::parsePageText(int page, QByteArray document, int status)
{
    int subPageCount = 1;
    int prevPage = std::max(100, page - 1);
    int nextPage = std::min(899, page + 1);
    QString image = generateImageUrl().toString();

    // Extract subPageCount from a snippet of generated js that looks like this:
    //     rotator2.addImages("png","2.png",...,"22.png");
    // Alternatively we could get the value of HTML element #sottop
    // but that requires an HTML parser.
    QRegularExpression re("\"(\\d+)\\.png\"\\);");
    QRegularExpressionMatch match = re.match(document);
    if (match.hasMatch()) {
        subPageCount = match.captured(1).toInt();
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

    return true;
}
