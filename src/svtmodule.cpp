#include "svtmodule.h"

#include <QDebug>
#include <QtQml>
#include <QJsonObject>
#include <QJsonDocument>
#include <QJsonArray>

SvtModule::SvtModule()
{
    _code = "svt_se";
    _name = "SVT";
    _isLoading = false;

    _page = nullptr;
    _pageNum = 100;
    _subPage = 1;
    _baseUrl = "https://www.svt.se/text-tv/api/{pagenum}";
//    _baseImageUrl = "https://www.mtvtekstikanava.fi/new2008/big/images/{pagenum}-{subpagenum}.gif";
    _baseImageUrl = "data:image/gif;base64,{imagedata}";
    _manager = new QNetworkAccessManager(this);
}

SvtModule::~SvtModule()
{

}

QString SvtModule::getCode() const
{
    return _code;
}

QString SvtModule::getName() const
{
    return _name;
}

bool SvtModule::isLoading() const
{
    return _isLoading;
}

SourcePage *SvtModule::getCurrentPage()
{
    return _page;
}

QString SvtModule::getPageName() const
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

bool SvtModule::supportsSubPages() const
{
    return false;
}

void SvtModule::loadInitialPage()
{
    loadPage(100, 1);
}

void SvtModule::loadPage(int pageNum, int subPageNum)
{
    if (pageNum < 100 || pageNum > 899 || subPageNum < 1)
    {
        qDebug() << "Invalid page number...";
    }

    _pageNum = pageNum;
    _subPage = subPageNum;

    setLoadingStatus(true);

    QNetworkRequest request(generateUrl(_baseUrl));
    request.setHeader(QNetworkRequest::UserAgentHeader, "sailfish/pinniini/tekstitv");
    _reply = _manager->get(request);

    connect(_reply, SIGNAL(finished()), this, SLOT(pageLoadingFinished()));
}

void SvtModule::reloadCurrentPage()
{
    loadPage(_page->page(), _page->subPage());
}

void SvtModule::navPrevSubPage()
{
    return;
}

void SvtModule::navPrevPage()
{
    int pnum = _page->previousPage();
    if (pnum == _page->page())
    {
        pnum = 899;
    }
    loadPage(pnum, 1);
}

void SvtModule::navNextPage()
{
    int pnum = _page->nextPage();
    if (pnum == _page->page())
    {
        pnum = 100;
    }
    loadPage(pnum, 1);
}

void SvtModule::navNextSubPage()
{
    return;
}

void SvtModule::pageLoadingFinished()
{
    // Check for errors. These should be already reported by error-signal.
    if (_reply->error() != QNetworkReply::NoError)
    {
        cleanRequest();
        setLoadingStatus(false);
        emit pageMissing();
        return;
    }

    QString pageData = QString::fromLatin1(_reply->readAll());
    parsePageText(pageData);

    setLoadingStatus(false);
    emit pageLoaded(_page);
}

QUrl SvtModule::generateUrl(const QString &base)
{
    QString tmp = base;
    tmp.replace("{pagenum}", QString::number(_pageNum));

    return QUrl(tmp);
}

void SvtModule::cleanRequest()
{

}

void SvtModule::setLoadingStatus(bool status)
{
    if (_isLoading != status)
    {
        _isLoading = status;
        emit loadingChanged(_isLoading);
    }
}

bool SvtModule::parsePageText(QString &document)
{
    int subPageCount = 1;
    int prevPage = 0;
    int nextPage = 0;
    QString image = _baseImageUrl;

//    qDebug() << "parsePageText: document: " << document;

    QJsonParseError *error = new QJsonParseError();
    QJsonDocument docu(QJsonDocument::fromJson(document.toLatin1(), error));
    if (!docu.isEmpty() && docu.isObject() && docu.object().contains("data"))
    {
        QJsonObject docuObj = docu.object().value("data").toObject();

        QString tmpPageNum = docuObj.value("prevPage").toString();
        if (tmpPageNum.isEmpty())
        {
            prevPage = _pageNum;
        }
        else
        {
            prevPage = tmpPageNum.toInt();
        }

        tmpPageNum = docuObj.value("nextPage").toString();
        if (tmpPageNum.isEmpty())
        {
            nextPage = _pageNum;
        }
        else
        {
            nextPage = tmpPageNum.toInt();
        }

        qDebug() << "Page numbers, prev - next: " << prevPage << " - " << nextPage;

//        QJsonObject dataObj = docuObj.value("data").toObject();
        if (docuObj.contains("subPages"))
        {
//            qDebug() << "subPages: " << dataObj.value("subPages");

            QJsonArray pageArray = docuObj.value("subPages").toArray();
            subPageCount = pageArray.count();
            if (subPageCount > 0)
            {
                QJsonObject pageObj = pageArray.at(0).toObject();
                if (pageObj.contains("gifAsBase64"))
                {
                    image.replace("{imagedata}", pageObj.value("gifAsBase64").toString());
                }
            }
        }
    }
    else
    {
        if (error)
        {
            qDebug() << error->error;
            qDebug() << error->errorString();
            qDebug() << error->offset;
        }
    }

    // Clear old page.
    if (_page != nullptr)
    {
        delete _page;
        _page = nullptr;
    }

    _page = new SourcePage(200, _pageNum, _subPage, subPageCount, prevPage, nextPage, image, this);
    // This is necessary, so that the js engine won't garbage collect the object after using get-method.
    // Because the ownership moves to the js engine if we return the object from here to there.
    QQmlEngine::setObjectOwnership(_page, QQmlEngine::CppOwnership);

    return true;
}

void SvtModule::parsePreviousPages(QString &document, int &previousPage, int &previousSubPage)
{

}

void SvtModule::parseNextPages(QString &document, int &nextPage, int &nextSubPage)
{

}
