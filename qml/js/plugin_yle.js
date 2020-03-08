function loadDone(responseText) {
    console.log("Loading done...");
    var obj = JSON.parse(responseText);

    // Parse page information.
    parsePageData(obj);

    // Check page status.
    if (pageStatus != 200) {
        console.log("Code: " + pageStatus);
        infoRectangle.visible = true;
        loading = false;
        return;
    }
    else {
        infoRectangle.visible = false;
    }

    // Parse image information.
    currentPageImageString = parseImage(obj);

    loading = false;
}

function loadPage(pageNum, subPageNum) {
    console.log("Page to be loaded: " + pageNum + "_" + subPageNum);

    if (loading && !initialLoad) {
        return;
    }

    loading = true;
    initialLoad = false;

    var urli = 'https://yle.fi/aihe/yle-ttv/json?P=';
    urli = urli + pageNum;
    urli = urli + "_";
    if (subPageNum < 10) {
        urli = urli + "0" + subPageNum;
    }
    else {
        urli = urli + subPageNum;
    }

    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
        if (xhr.readyState === 4 && (xhr.status === 200 || xhr.status === 404)) {
            loadDone(xhr.responseText);
        }
    };
    xhr.open("GET", urli);
    xhr.setRequestHeader('User-Agent','Teksti-TV (Sailfish OS)');
    xhr.send();
}

function stepSubPage(step) {
    if (subPages == 1) {
        return;
    }

    var moveTo = currentSubPageNumber + step;

    // Went to previous sub page, but there aren't any.
    // Let's go to the last sub page.
    if (moveTo <= 0) {
        moveTo = subPages;
    }

    // Went to next sub page, but there aren't any.
    // Let's go to the first sub page.
    else if (moveTo > subPages) {
        moveTo = 1;
    }

    loadPage(currentPageNumber, moveTo);
}

function stepPage(forward) {
    // Next page
    if (forward) {
        if (currentPageNumber == 899) {
            currentPageNumber = 100;
        }
        else {
            currentPageNumber = nextPage;
        }
    }
    else { // Previous page
        if (currentPageNumber == 100) {
            currentPageNumber = 899;
        }
        else {
            currentPageNumber = previousPage;
        }
    }

    currentSubPageNumber = 1;
    pageNumberField.text = currentPageNumber;
}

function parseImage(json) {
    var imageSrc = json.data[0].content.image;
    imageSrc = imageSrc.substring(imageSrc.indexOf('"') + 1);
    imageSrc = imageSrc.substring(0, imageSrc.indexOf('"'));
    return imageSrc;
}

function parsePageData(json) {
    // Parse page status.
    if (json.meta.code) {
        console.log("Code exists: " + json.meta.code);
        pageStatus = Number(json.meta.code);
    }
    else {
        console.log("Code does not exist...");
        return;
    }

    // Check page status.
    if (pageStatus != 200) {
        return;
    }

    // Parse current page number.
    if (json.data[0].page.page) {
        currentPageNumber = Number(json.data[0].page.page);
    }

    // Parse current sub page number.
    if (json.data[0].page.subpage) {
        currentSubPageNumber = Number(json.data[0].page.subpage);
    }

    // Parse sub pages count.
    if (json.data[0].info.page.subpages) {
        subPages = json.data[0].info.page.subpages;
    }
    else if (updateSubPageCount) {
        subPages = 1;
    }

    if (!updateSubPageCount) {
        updateSubPageCount = true;
    }

    // Parse pagination.
    if (json.data[0].content.pagination) {
        var tmp = json.data[0].content.pagination;
        var indx = tmp.indexOf('href="?P=');
        var pageNum = "";
        if (indx >= 0)
        {
            tmp = tmp.substring(indx + 9);
            pageNum = tmp.substring(0, tmp.indexOf('"'));
            var num = Number(pageNum)

            if (num !== NaN)
            {
                previousPage = num;
            }

            console.log("Previous page: " + previousPage);
        }

        indx = tmp.lastIndexOf('href="?P=');
        if (indx >= 0)
        {
            tmp = tmp.substring(indx + 9, indx + 12);
            var num2 = Number(tmp)

            if (num2 !== NaN)
            {
                nextPage = num2;
            }

            console.log("Next page: " + nextPage);
        }
    }

    console.log("Current page: " + currentPageNumber);
    console.log("Current sub page: " + currentSubPageNumber);
    console.log("Sub pages: " + subPages);
}
