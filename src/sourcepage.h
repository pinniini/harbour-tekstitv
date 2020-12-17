#ifndef SOURCEPAGE_H
#define SOURCEPAGE_H

#include <QObject>

class SourcePage : public QObject
{
    Q_OBJECT
public:
    explicit SourcePage(QObject *parent = nullptr);
    SourcePage(int pageStatus, int page, int subPage, int subPageCount, int previousPage, int nextPage, QString pageImage, QObject *parent = nullptr);
    ~SourcePage();

    Q_PROPERTY(int pageStatus READ pageStatus NOTIFY pageStatusChanged)
    Q_PROPERTY(int page READ page NOTIFY pageChanged)
    Q_PROPERTY(int subPage READ subPage NOTIFY subPageChanged)
    Q_PROPERTY(int subPageCount READ subPageCount NOTIFY subPageCountChanged)
    Q_PROPERTY(int previousPage READ previousPage NOTIFY previousPageChanged)
    Q_PROPERTY(int nextPage READ nextPage NOTIFY nextPageChanged)
    Q_PROPERTY(QString pageImage READ pageImage NOTIFY pageImageChanged)

    int pageStatus() const;
//    void setPageStatus(int status);

    int page() const;
//    void setPage(int page);

    int subPage() const;
//    void setSubPage(int subPage);

    int subPageCount() const;
//    void setSubPageCount(int subPageCount);

    int previousPage() const;
//    void setPreviousPage(int previousPage);

    int nextPage() const;
//    void setNextPage(int nextPage);

    QString pageImage() const;
//    void setPageImage(QString pageImage);

signals:
    void pageStatusChanged();
    void pageChanged();
    void subPageChanged();
    void subPageCountChanged();
    void previousPageChanged();
    void nextPageChanged();
    void pageImageChanged();

private:
    int _pageStatus;
    int _page;
    int _subPage;
    int _subPageCount;
    int _previousPage;
    int _nextPage;
    QString _pageImageSource;
};

#endif // SOURCEPAGE_H
