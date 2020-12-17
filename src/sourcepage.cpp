#include "sourcepage.h"

SourcePage::SourcePage(QObject *parent) : QObject(parent)
{

}

SourcePage::SourcePage(int pageStatus, int page, int subPage, int subPageCount, int previousPage, int nextPage, QString pageImage, QObject *parent) : QObject(parent)
{
    _pageStatus = pageStatus;
    _page = page;
    _subPage = subPage;
    _subPageCount = subPageCount;
    _previousPage = previousPage;
    _nextPage = nextPage;
    _pageImageSource = pageImage;
}

SourcePage::~SourcePage()
{

}

int SourcePage::pageStatus() const
{
    return _pageStatus;
}

int SourcePage::page() const
{
    return _page;
}

int SourcePage::subPage() const
{
    return _subPage;
}

int SourcePage::subPageCount() const
{
    return _subPageCount;
}

int SourcePage::previousPage() const
{
    return _previousPage;
}

int SourcePage::nextPage() const
{
    return _nextPage;
}

QString SourcePage::pageImage() const
{
    return _pageImageSource;
}
