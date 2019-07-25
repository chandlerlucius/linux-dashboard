'use strict';

//Handle reconnecting websocket
let timerID = 0;

//Handle initiliazation features
let initialized = false;

//Handle resizing charts with window
const chartMap = new Map();

//Helper methods
const resizeCharts = function () {
    chartMap.forEach(function (value) {
        if (value.closest('.row').style.display !== 'none') {
            window.echarts.getInstanceByDom(value).resize();
        }
    });
};

const search = function (element) {
    const filter = element.value.toUpperCase();
    const table = element.closest('.card').querySelector('table');
    const trs = table.getElementsByTagName('tr');

    for (let i = 1; i < trs.length; i += 1) {
        let found = false;
        const tr = trs[i];
        const tds = tr.getElementsByTagName('td');
        for (let j = 0; j < tds.length; j += 1) {
            const td = tds[j];
            const text = td.textContent || td.innerText;
            if (text.toUpperCase().indexOf(filter) > -1) {
                found = true;
            }
        }
        if (found) {
            tr.style.display = '';
        } else {
            tr.style.display = 'none';
        }
    }
};

const searchThis = function () {
    search(this);
};

const clearSearch = function () {
    const parentElement = this.parentElement;
    const searchElement = parentElement.querySelector('.search');
    searchElement.value = '';
    search(searchElement);
};

const populateHidden = function (element) {
    element.innerHTML = '<a class="waves-effect waves-light btn-small" onclick="populateRow(this.parentElement);">Click to Populate -></a>';
};

const populateRow = function (element) {
    const title = element.closest('.card').querySelector('.card-title').innerHTML;
    const tr = element.closest('tr');
    if (title === _('Connections')) {
        const ip = element.previousSibling.innerHTML;
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (this.readyState === 4 && this.status === 200) {
                const json = JSON.parse(xhr.responseText);
                const array = [json.city, json.region, json.country, json.postal];
                element.innerHTML = json.org;
                for (let i = 0; i < 4; i += 1) {
                    const td = tr.insertCell(i + 3);
                    td.innerHTML = array[i];
                }
            }
        };
        xhr.open('GET', `https://ipapi.co/${ip}/json/`, true);
        xhr.send();
    }
};

const drawChart = function (chart, xAxisData, seriesData) {
    chart.setOption({
        animation: false,
        grid: {
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
        },
        tooltip: {
            trigger: 'axis',
            formatter(params) {
                let result;
                params.forEach(function (item) {
                    result = '<p>' + '<span style="display:inline-block;margin-right:5px;border-radius:10px;width:9px;height:9px;background-color:' +
                        item.color + '"></span>' + ' ' + item.seriesName + ': ' + item.data + '%' + '</p>';
                });
                return result;
            },
        },
        xAxis: {
            axisLabel: {
                show: false,
            },
            boundaryGap: false,
            data: xAxisData,
        },
        yAxis: {
            axisLabel: {
                show: false,
            },
            max: 100,
        },
        series: [{
            type: 'line',
            data: seriesData,
            itemStyle: {
                color: '#00bfa5',
            },
            symbolSize: 2,
            areaStyle: {},
        }],
    });
};

const escapeHTML = function (unsafe) {
    return unsafe
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&apos;');
};

const createSearchRow = function (rows, tabContent, table, i, j, k, l) {
    const row = rows[l];
    const tabSearchTrId = 'tab-search-' + i + '-' + j + '-' + k + '-' + l;
    let tabSearchTr = tabContent.querySelector('#' + tabSearchTrId);
    if (tabSearchTr === null) {
        tabSearchTr = table.insertRow(l);
        tabSearchTr.id = tabSearchTrId;
    }
    if (l === 0) {
        tabSearchTr.classList.add('white-text');
    }

    const cols = row.split('|');
    for (let m = 0; m < cols.length; m += 1) {
        const col = cols[m];
        const tabSearchTdId = 'tab-search-' + i + '-' + j + '-' + k + '-' + l + '-' + m;
        let tabSearchTd = tabContent.querySelector('#' + tabSearchTdId);
        if (tabSearchTd === null) {
            tabSearchTd = tabSearchTr.insertCell(m);
            tabSearchTd.id = tabSearchTdId;
            if (col === '[hidden]') {
                populateHidden(tabSearchTd);
            } else if (col === '[client-request]') {
                populateRow(tabSearchTd);
            } else {
                //Skip the row
            }
        }
        if (tabSearchTd != null && col !== '[hidden]' && col !== '[client-request]') {
            tabSearchTd.innerHTML = escapeHTML(col);
        }
    }
};

const createToastDetails = function (tabDetailResult) {
    //Handle toasts for thresholds
    const key = tabDetailResult.title.toLowerCase().replace(/ /g, '_');
    const thresholdKey = key + '-threshold';
    let threshold = localStorage.getItem(thresholdKey);

    if (tabDetailResult.threshold !== '' && threshold === null) {
        threshold = tabDetailResult.threshold;
        localStorage.setItem(thresholdKey, threshold);
    }
    if (threshold !== null) {
        const exceededThreshold = parseFloat(tabDetailResult.value) > parseFloat(threshold);
        const toastTitleElement = document.querySelector(`#${thresholdKey}_title`);
        const toastValueElement = document.querySelector(`#${thresholdKey}_value`);
        const toastTitle = _(`High ${tabDetailResult.title}`);
        const toastValue = `${tabDetailResult.value}%`;
        if (toastTitleElement === null && exceededThreshold) {
            const toastHTML =
                `<span id='${thresholdKey}_title'>${toastTitle}</span>` +
                `<span id='${thresholdKey}_value' class='lime-text accent-2-text'>${toastValue}</span>` +
                `<button class='btn-flat toast-action modal-trigger' href='#menu'>Edit</button>`;
            M.toast({ html: toastHTML, displayLength: Infinity });
        } else if (exceededThreshold) {
            toastTitleElement.innerHTML = toastTitle;
            toastValueElement.innerHTML = toastValue;
        } else if (toastTitleElement !== null) {
            const toastInstance = M.Toast.getInstance(toastTitleElement.parentElement);
            toastInstance.dismiss();
        } else {
            //Toast not available
        }
    }
};

const createSearchDetails = function (tabContent, tabDetailResult, i, j, k) {
    //Show search and make card large
    tabContent.querySelector('.card-search').style.display = '';
    tabContent.querySelector('.card').classList.remove('small');
    tabContent.querySelector('.card').classList.add('large');
    tabContent.querySelector('.card-detail').classList.add('search-table');

    //Update table with searchable data
    const table = tabContent.querySelector('table');
    const rows = tabDetailResult.value.split('#');
    for (let l = 0; l < rows.length - 1; l += 1) {
        createSearchRow(rows, tabContent, table, i, j, k, l);
    }

    const rowCount = table.querySelectorAll('tr').length - 1;
    for (let l = rows.length; l < rowCount; l += 1) {
        table.deleteRow(l);
    }
    search(tabContent.querySelector('.search'));
};

const createChartDetails = function (tabContent, tabDetailResult, i, j, k) {
    //Show chart and remove height restriction on card
    tabContent.querySelector('.card-chart').style.display = '';
    tabContent.querySelector('.card').classList.remove('small');
    tabContent.querySelector('.card').classList.add('large');

    //Update data within chart
    const tabChartId = 'tab-chart-' + i + '-' + j + '-' + k;
    let tabChart = tabContent.querySelector('#' + tabChartId);
    const total = 30;
    if (tabChart === null) {
        tabChart = tabContent.querySelector('.card-chart');
        tabChart.id = tabChartId;

        const origXAxisData = [];
        for (let l = total; l > 0; l--) {
            origXAxisData.push(k);
        }

        const seriesData = [];
        for (let l = total; l > 0; l--) {
            seriesData.push(0);
        }

        const origChart = echarts.init(tabChart, null, {});
        chartMap.set(i + '_' + j + '_' + k, tabChart);
        drawChart(origChart, origXAxisData, seriesData);
    }

    const chart = echarts.getInstanceByDom(tabChart);
    const xAxisData = chart.getOption().xAxis[0].data;
    const seriesData = chart.getOption().series[0].data;

    seriesData.shift();
    seriesData[total - 1] = tabDetailResult.value;
    chart.setOption({
        xAxis: {
            data: xAxisData,
        },
        series: [{
            name: _(tabDetailResult.title),
            data: seriesData,
        }],
    });
};

const createDetails = function (groupResult, tabContent, i, j) {
    const groupValues = groupResult.values;
    for (let k = 0; k < groupValues.length; k += 1) {
        const tabDetailResult = groupValues[k];

        //Handle toast details
        createToastDetails(tabDetailResult);

        //Handle tab details
        if (tabDetailResult.type === 'detail') {
            //Update table with detail data
            const tabDetailId = `tab-detail-${i}-${j}-${k}`;
            let tabDetail = tabContent.querySelector('#' + tabDetailId);
            if (tabDetail === null) {
                const tabDetailTemplate = document.querySelector('#tab-detail-template').content.cloneNode(true);
                tabDetailTemplate.querySelector('tr').id = tabDetailId;
                tabContent.querySelector('.card-detail table tbody').appendChild(tabDetailTemplate);
                tabDetail = tabContent.querySelector('#' + tabDetailId);
            }
            tabDetail.querySelector('strong').innerHTML = _(tabDetailResult.title);
            tabDetail.querySelector('span').innerHTML = tabDetailResult.value;
        } else if (tabDetailResult.type === 'search') {
            createSearchDetails(tabContent, tabDetailResult, i, j, k);
        } else if (tabDetailResult.type === 'chart') {
            createChartDetails(tabContent, tabDetailResult, i, j, k);
        } else {
            //Skip the tab
        }
    }
};

const init = function () {
    //Initialize materialize js features every time
    M.AutoInit();

    //Set event listener on tabs to resize charts
    document.querySelectorAll('.tab a').forEach(function (element) {
        element.addEventListener('click', function () {
            setTimeout(function () {
                resizeCharts();
            }, 10);
        });
    });

    //Set event listener on clear search button to clear search table
    document.querySelectorAll('.search').forEach(function (element) {
        element.addEventListener('keyup', searchThis);
    });

    //Set event listener on search button to search table
    document.querySelectorAll('.clear-search').forEach(function (element) {
        element.addEventListener('click', clearSearch);
        element.addEventListener('keypress', clearSearch);
    });

    if (!initialized) {
        //Initialize materialize js sidenavs features once
        const navs = document.querySelectorAll('.sidenav');
        M.Sidenav.init(navs, {});

        //Initialize materialize js modals features every time
        const elems = document.querySelectorAll('.modal');
        M.Modal.init(elems, {});

        //Hide progress bar
        document.getElementsByClassName('progress')[0].style.display = 'none';
    }
    initialized = true;
};

const createTabs = function (json, i) {
    const tabResult = json.results[i];
    const tabId = 'tab-' + i;
    const tabTitleId = 'tab-title-' + i;
    let tab = document.querySelector('#' + tabId);
    if (tab === null) {
        const tabTitleTemplate = document.querySelector('#tab-title-template').content.cloneNode(true);
        tabTitleTemplate.querySelector('a').id = tabTitleId;
        if (i === 0) {
            tabTitleTemplate.querySelector('a').class = 'active';
        }
        document.querySelector('#tab-title-list').appendChild(tabTitleTemplate);

        const tabContainerTemplate = document.querySelector('#tab-container-template').content.cloneNode(true);
        tabContainerTemplate.querySelector('div').id = tabId;
        document.querySelector('main').appendChild(tabContainerTemplate);
        tab = document.querySelector('#' + tabId);
    }
    const tabTitle = document.querySelector('#' + tabTitleId);
    tabTitle.innerHTML = _(tabResult.title);
    tabTitle.href = '#' + tabId;

    const tabValues = tabResult.values;
    for (let j = 0; j < tabValues.length; j += 1) {
        const groupResult = tabValues[j];
        const tabContentId = `tab-content-${i}-${j}`;
        let tabContent = tab.querySelector('#' + tabContentId);
        if (tabContent === null) {
            const tabContentTemplate = document.querySelector('#tab-content-template').content.cloneNode(true);
            tabContentTemplate.querySelector('div').id = tabContentId;
            tab.appendChild(tabContentTemplate);
            tabContent = tab.querySelector('#' + tabContentId);
        }
        tabContent.querySelector('.card-title').innerHTML = _(groupResult.title);

        if (groupResult.type === 'chart') {
            tabContent.querySelector('.card-chart').style.display = '';
            tabContent.querySelector('.card').classList.remove('small');
        } else if (groupResult.type === 'search') {
            tabContent.querySelector('.card-search').style.display = '';
            tabContent.querySelector('.card').classList.remove('small');
            tabContent.querySelector('.card').classList.add('large');
        } else {
            //Skip the group
        }
        createDetails(groupResult, tabContent, i, j);
    }
};

//Parse json method
const parseJsonResults = function (json) {
    for (let i = 0; i < json.results.length; i += 1) {
        createTabs(json, i);
    }
    init();
};

const start = function (websocketServerLocation) {
    const socket = new WebSocket(websocketServerLocation);

    socket.onopen = function () {
        if (timerID) {
            clearInterval(timerID);
            timerID = 0;
        }
        socket.send('gimme');
    };

    socket.onclose = function () {
        if (!timerID) {
            timerID = setInterval(function () {
                start(websocketServerLocation);
            }, 5000);
        }
    };

    socket.onmessage = function (event) {
        try {
            const json = JSON.parse(event.data);
            parseJsonResults(json);
        }
        catch (err) {
            console.error('Issue parsing json: ' + err);
        }
        socket.send('gimme');
    };
};

if (window) {
    window.addEventListener('DOMContentLoaded', function () {
        //Start websocket connection
        const host = window.location.host;
        if(window.location.protocol === 'https:') {
            start(`wss://${host}/websocket`);
        } else {
            start(`ws://${host}/websocket`);
        }

        //Handle resizing charts when window is resized
        window.onresize = function () {
            resizeCharts();
        };
    });
}

if (typeof exports !== 'undefined') {
    exports.escapeHTML = escapeHTML;
}
