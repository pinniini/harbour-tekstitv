#include "mtvmodule.h"

#include <QNetworkRequest>
#include <QDebug>
#include <QtQml>

MtvModule::MtvModule()
{
    _code = "mtv3_fi";
    _name = "MTV3";
    _isLoading = false;

    _page = nullptr;
    _pageNum = 100;
    _subPage = 1;
    _baseUrl = "https://www.mtvtekstikanava.fi/new2008/{pagenum}-{subpagenum}.htm";
//    _baseImageUrl = "https://www.mtvtekstikanava.fi/new2008/big/images/{pagenum}-{subpagenum}.gif";
    _baseImageUrl = "https://www.mtvtekstikanava.fi/new2008/images/{pagenum}-{subpagenum}.gif";
    _manager = new QNetworkAccessManager(this);

    _testDateTime = QDateTime::currentDateTime();
}

MtvModule::~MtvModule()
{

}

QString MtvModule::getCode() const
{
    return _code;
}

QString MtvModule::getName() const
{
    return _name;
}

bool MtvModule::isLoading() const
{
    return _isLoading;
}

SourcePage *MtvModule::getCurrentPage()
{
    return _page;
}

QString MtvModule::getPageName() const
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

void MtvModule::loadInitialPage()
{
    loadPage(100, 1);
}

void MtvModule::loadPage(int pageNum, int subPageNum)
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

    QNetworkRequest request(generateUrl(_baseUrl));
    request.setHeader(QNetworkRequest::UserAgentHeader, "sailfish/pinniini/tekstitv");
    _reply = _manager->get(request);

    //connect(_reply, SIGNAL(error(QNetworkReply::NetworkError)), this, SLOT(errorLoadingData(QNetworkReply::NetworkError)));
    connect(_reply, SIGNAL(finished()), this, SLOT(pageLoadingFinished()));
}

void MtvModule::reloadCurrentPage()
{
    loadPage(_page->page(), _page->subPage());
}

void MtvModule::navPrevSubPage()
{
    int prevSubPage = _page->subPage() - 1;
    if (prevSubPage < 1)
    {
        prevSubPage = _page->subPageCount();
    }
    loadPage(_page->page(), prevSubPage);
}

void MtvModule::navPrevPage()
{
    int pnum = _page->previousPage();
    if (pnum == _page->page())
    {
        pnum = 899;
    }
    loadPage(pnum, 1);
}

void MtvModule::navNextPage()
{
    int pnum = _page->nextPage();
    if (pnum == _page->page())
    {
        pnum = 100;
    }
    loadPage(pnum, 1);
}

void MtvModule::navNextSubPage()
{
    int nextSubPage = _page->subPage() + 1;
    if (nextSubPage > _page->subPageCount())
    {
        nextSubPage = 1;
    }
    loadPage(_page->page(), nextSubPage);
}

void MtvModule::pageLoadingFinished()
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

    QString pageData = QString(_reply->readAll());
    parsePageText(pageData);

    qDebug() << "Request handling duration: " << _testDateTime.msecsTo(QDateTime::currentDateTimeUtc()) << "ms...";
    setLoadingStatus(false);

    emit pageLoaded(_page);
}

// --------------------------------------------------
// Private

QUrl MtvModule::generateUrl(const QString& base)
{
    QString tmp = base;
    tmp.replace("{pagenum}", QString::number(_pageNum));

    QString sub = "";
    if (_subPage < 10)
    {
        sub += "0";
    }

    sub += QString::number(_subPage);
    tmp.replace("{subpagenum}", sub);

    return QUrl(tmp);
}

void MtvModule::cleanRequest()
{

}

void MtvModule::setLoadingStatus(bool status)
{
    if (_isLoading != status)
    {
        _isLoading = status;
        emit loadingChanged(_isLoading);
    }
}

bool MtvModule::parsePageText(QString &document)
{
    int subPageCount = 1;
    int prevPage = 0;
    int prevSubPage = 0;
    int nextPage = 0;
    int nextSubPage = 0;
    QString image = "";

    parsePreviousPages(document, prevPage, prevSubPage);
    qDebug() << "Previous page:" << prevPage << "/" << prevSubPage;
    if (prevPage < 100)
    {
        prevPage = 899;
    }

    int pageInfoIndex = document.indexOf(_pageInfoTemplate);
    if (pageInfoIndex > -1)
    {
        pageInfoIndex += _pageInfoTemplate.length();
        QString pageInfo = document.mid(pageInfoIndex, document.indexOf("<", pageInfoIndex) - pageInfoIndex);
        qDebug() << "Page info:" << pageInfo;

        QStringList pieces = pageInfo.split(" ");
        if (pieces.length() == 2)
        {
            QStringList subPieces = pieces[1].split("/");
            if (subPieces.length() == 2)
            {
                subPageCount = subPieces[1].toInt();
            }
        }
    }

    parseNextPages(document, nextPage, nextSubPage);
    qDebug() << "Next page:" << nextPage << "/" << nextSubPage;
    if (nextPage < 100 || nextPage >= 900)
    {
        nextPage = 100;
    }

    // Clear old page.
    if (_page != nullptr)
    {
        delete _page;
        _page = nullptr;
    }

    _page = new SourcePage(200, _pageNum, _subPage, subPageCount, prevPage, nextPage, generateUrl(_baseImageUrl).toString(), this);
    // This is necessary, so that the js engine won't garbage collect the object after using get-method.
    // Because the ownership moves to the js engine if we return the object from here to there.
    QQmlEngine::setObjectOwnership(_page, QQmlEngine::CppOwnership);

    return true;
}

void MtvModule::parsePreviousPages(QString &document, int &previousPage, int &previousSubPage)
{
    int previousLinkIndex = document.indexOf(_previousPageTemplate);
    if (previousLinkIndex > -1)
    {
        previousLinkIndex += _previousPageTemplate.length();
        QString previousInfo = document.mid(previousLinkIndex, document.indexOf(".", previousLinkIndex) - previousLinkIndex);
        qDebug() << "Previous page info:" << previousInfo;

        QStringList pieces = previousInfo.split("-");
        if (pieces.length() == 2)
        {
            previousPage = pieces[0].toInt();
            previousSubPage = pieces[1].toInt();
        }
    }
}

void MtvModule::parseNextPages(QString &document, int &nextPage, int &nextSubPage)
{
    int nextLinkIndex = document.indexOf(_nextPageTemplate);
    if (nextLinkIndex > -1)
    {
        nextLinkIndex += _nextPageTemplate.length();
        QString nextInfo = document.mid(nextLinkIndex, document.indexOf(".", nextLinkIndex) - nextLinkIndex);
        qDebug() << "Next page info:" << nextInfo;

        QStringList pieces = nextInfo.split("-");
        if (pieces.length() == 2)
        {
            nextPage = pieces[0].toInt();
            nextSubPage = pieces[1].toInt();
        }
    }
}
