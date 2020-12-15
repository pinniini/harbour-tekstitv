#include "isourcemodule.h"

ISourceModule::ISourceModule()
{
    _name = "Do not use me, but implement your own instead!";
    _code = "Do not use me, but implement your own instead!";
    _isLoading = false;
    _currentPage = nullptr;
}

ISourceModule::~ISourceModule()
{

}

QString ISourceModule::getCode() const
{
    return _code;
}

QString ISourceModule::getName() const
{
    return _name;
}

bool ISourceModule::isLoading() const
{
    return _isLoading;
}

SourcePage *ISourceModule::getCurrentPage()
{
    return _currentPage;
}

QString ISourceModule::getPageName() const
{
    return _name;
}

void ISourceModule::loadInitialPage()
{
    _isLoading = true;
    emit loadingChanged(_isLoading);
    _isLoading = false;
    emit loadingChanged(_isLoading);
}

void ISourceModule::loadPage(int pageNum, int subPageNum)
{
    Q_UNUSED(pageNum)
    Q_UNUSED(subPageNum)
    _isLoading = true;
    emit loadingChanged(_isLoading);
    _isLoading = false;
    emit loadingChanged(_isLoading);
}

void ISourceModule::reloadCurrentPage()
{

}

void ISourceModule::navPrevSubPage()
{

}

void ISourceModule::navPrevPage()
{

}

void ISourceModule::navNextPage()
{

}

void ISourceModule::navNextSubPage()
{

}
