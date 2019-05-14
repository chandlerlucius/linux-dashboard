'use strict';

//Handle reconnecting websocket
let timerID = 0;

//Handle initiliazation features
let initialized = false;

//Handle resizing charts with window
const chartMap = new Map();

//Run web worker to handle notifications
// const worker = new Worker('js/notifications.js');
// worker.addEventListener('message', function (e) {
//     localStorage.setItem(e.data.key, new Date());
// }, false);

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

    for (let i = 1; i < trs.length; i++) {
        let found = false;
        const tr = trs[i];
        const tds = tr.getElementsByTagName('td');
        for (let j = 0; j < tds.length; j++) {
            const td = tds[j];
            if (td) {
                const text = td.textContent || td.innerText;
                if (text.toUpperCase().indexOf(filter) > -1) {
                    found = true;
                }
            }
        }
        if (found) {
            tr.style.display = '';
        } else {
            tr.style.display = 'none';
        }
    }
};

const clearSearch = function (element) {
    const parentElement = element.parentElement;
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
    if (title === 'Connections') {
        const ip = element.previousSibling.innerHTML;
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (this.readyState === 4 && this.status === 200) {
                const json = JSON.parse(xhr.responseText);
                const array = [json.city, json.region, json.country, json.postal];
                element.innerHTML = json.org;
                for (let i = 0; i < 4; i++) {
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
            formatter: function(params) {
                let result;
                params.forEach(function (item) {
                    result = '<p>' + '<span style="display:inline-block;margin-right:5px;border-radius:10px;width:9px;height:9px;background-color:'
                        + item.color + '"></span>' + ' ' + item.seriesName + ': ' + item.data + '%' + '</p>';
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

//Parse json method
const parseJsonResults = function (json) {
    for (let i = 0; i < json.results.length; i++) {
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
        tabTitle.innerHTML = tabResult.title;
        tabTitle.href = '#' + tabId;

        const tabValues = tabResult.values;
        for (let j = 0; j < tabValues.length; j++) {
            const groupResult = tabValues[j];
            const tabContentId = `tab-content-${i}-${j}`;
            let tabContent = tab.querySelector('#' + tabContentId);
            if (tabContent === null) {
                const tabContentTemplate = document.querySelector('#tab-content-template').content.cloneNode(true);
                tabContentTemplate.querySelector('div').id = tabContentId;
                tab.appendChild(tabContentTemplate);
                tabContent = tab.querySelector('#' + tabContentId);
            }
            tabContent.querySelector('.card-title').innerHTML = groupResult.title;

            if (groupResult.type === 'chart') {
                tabContent.querySelector('.card-chart').style.display = '';
                tabContent.querySelector('.card').classList.remove('small');
            } else if (groupResult.type === 'search') {
                tabContent.querySelector('.card-search').style.display = '';
                tabContent.querySelector('.card').classList.remove('small');
                tabContent.querySelector('.card').classList.add('large');
            } else {
            }

            const groupValues = groupResult.values;
            for (let k = 0; k < groupValues.length; k++) {
                const tabDetailResult = groupValues[k];

                //Handle toasts for thresholds
                const key = tabDetailResult.title.toLowerCase().replace(/ /g, '_');
                const thresholdKey = key + '-threshold';
                let threshold = localStorage.getItem(thresholdKey);

                if (tabDetailResult.threshold !== '' && threshold === null) {
                    threshold = tabDetailResult.threshold;
                    localStorage.setItem(thresholdKey, threshold);
                }
                if (threshold !== null) {
                    //Setup notifications tab and values
                    if (!initialized || document.querySelector('#menu').style.display === 'none') {
                        const notificationTabId = 'notifications-tab-' + i + '-' + j + '-' + k;
                        let notificationTab = document.querySelector('#' + notificationTabId);
                        if (notificationTab === null) {
                            const notificationTabTemplate = document.querySelector('#notification-tab-template').content.cloneNode(true);
                            notificationTabTemplate.querySelector('div').id = notificationTabId;
                            document.querySelector('#notifications form').appendChild(notificationTabTemplate);
                            notificationTab = document.querySelector('#' + notificationTabId);
                        }

                        //Set local storage values dealing with notifications
                        notificationTab.querySelector('#notification-title').innerHTML = tabDetailResult.title;

                        const thresholdTitle = 'threshold';
                        const thresholdId = key + '-' + thresholdTitle;
                        const thresholdElement = notificationTab.querySelector('input.' + thresholdTitle);
                        thresholdElement.id = thresholdId;
                        thresholdElement.value = threshold;
                        thresholdElement.parentElement.querySelector('label.' + thresholdTitle).htmlFor = thresholdId;

                        const frequencyTitle = 'frequency';
                        const frequencyId = key + '-' + frequencyTitle;
                        let frequencyVal = localStorage.getItem(frequencyId);
                        if (frequencyVal === null) {
                            localStorage.setItem(frequencyId, '15');
                        }
                        frequencyVal = localStorage.getItem(frequencyId);
                        const frequencyElement = notificationTab.querySelector('input.' + frequencyTitle);
                        frequencyElement.id = frequencyId;
                        frequencyElement.value = frequencyVal;
                        frequencyElement.parentElement.querySelector('label.' + frequencyTitle).htmlFor = frequencyId;

                        const snoozeTitle = 'snooze';
                        const snoozeId = key + '-' + snoozeTitle;
                        let snoozeVal = localStorage.getItem(snoozeId);
                        if (snoozeVal === null) {
                            localStorage.setItem(snoozeId, '0');
                        }
                        snoozeVal = localStorage.getItem(snoozeId);
                        const snoozeElement = notificationTab.querySelector('input.' + snoozeTitle);
                        snoozeElement.id = snoozeId;
                        snoozeElement.value = snoozeVal;
                        snoozeElement.parentElement.querySelector('label.' + snoozeTitle).htmlFor = snoozeId;

                        const notifications = ['toast', 'email', 'sms', 'chat', 'notification'];
                        notifications.forEach(function (title) {
                            const id = key + '-' + title;
                            let val = localStorage.getItem(id);
                            if (val === null) {
                                localStorage.setItem(id, 'true');
                            }
                            val = localStorage.getItem(id);
                            if (val === 'true') {
                                const element = notificationTab.querySelector('input.' + title);
                                element.id = id;
                                element.checked = 'checked';
                            }
                        });
                    }

                    const exceededThreshold = parseFloat(tabDetailResult.value) > parseFloat(threshold);
                    if (exceededThreshold) {
                        // worker.postMessage({
                        //     'key': key, 'title': tabDetailResult.title, 'value': tabDetailResult.value,
                        //     'frequency': localStorage.getItem(key + '-frequency'), 'notifiedDate': localStorage.getItem(key + '-notified-date'),
                        //     'toast': localStorage.getItem(key + '-toast'), 'email': localStorage.getItem(key + '-email'),
                        //     'sms': localStorage.getItem(key + '-sms'), 'chat': localStorage.getItem(key + '-chat'),
                        //     'notification': localStorage.getItem(key + '-notification')
                        // });
                    }

                    const toastTitleElement = document.querySelector(`#${thresholdKey}_title`);
                    const toastValueElement = document.querySelector(`#${thresholdKey}_value`);
                    const toastTitle = 'High ' + tabDetailResult.title;
                    const toastValue = tabDetailResult.value + '%' + '<br>' + new Date().toLocaleString();
                    if (toastTitleElement === null && exceededThreshold) {
                        const toastHTML =
                            '<span id="' + thresholdKey + '_title">' + toastTitle + '</span>' +
                            '<span id="' + thresholdKey + '_value" class="lime-text accent-2-text">' + toastValue + '</span>' +
                            '<button class="btn-flat toast-action modal-trigger" href="#menu">Edit</button>';
                        M.toast({ html: toastHTML, displayLength: Infinity });
                    } else if (exceededThreshold) {
                        toastTitleElement.innerHTML = toastTitle;
                        toastValueElement.innerHTML = toastValue;
                    } else if (toastTitleElement !== null) {
                        const toastInstance = M.Toast.getInstance(toastTitleElement.parentElement);
                        toastInstance.dismiss();
                    } else {
                    }
                }

                //Handle tab details
                if (tabDetailResult.type === 'detail') {
                    //Update table with detail data
                    const tabDetailId = 'tab-detail-' + i + '-' + j + '-' + k;
                    let tabDetail = tabContent.querySelector('#' + tabDetailId);
                    if (tabDetail === null) {
                        const tabDetailTemplate = document.querySelector('#tab-detail-template').content.cloneNode(true);
                        tabDetailTemplate.querySelector('tr').id = tabDetailId;
                        tabContent.querySelector('.card-detail table').appendChild(tabDetailTemplate);
                        tabDetail = tabContent.querySelector('#' + tabDetailId);
                    }
                    tabDetail.querySelector('strong').innerHTML = tabDetailResult.title;
                    tabDetail.querySelector('span').innerHTML = tabDetailResult.value;

                } else if (tabDetailResult.type === 'search') {
                    //Show search and make card large
                    tabContent.querySelector('.card-search').style.display = '';
                    tabContent.querySelector('.card').classList.remove('small');
                    tabContent.querySelector('.card').classList.add('large');
                    tabContent.querySelector('.card-detail').classList.add('search-table');

                    //Update table with searchable data
                    const table = tabContent.querySelector('table');
                    const rows = tabDetailResult.value.split('#');
                    for (let l = 0; l < rows.length - 1; l++) {
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
                        for (let m = 0; m < cols.length; m++) {
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
                                }
                            }
                            if (col !== '[hidden]' && col !== '[client-request]') {
                                tabSearchTd.innerHTML = escapeHTML(col);
                            }
                        }

                        const rowCount = table.querySelectorAll('tr').length - 1;
                        for (let m = rows.length; m < rowCount; m++) {
                            table.deleteRow(m);
                        }
                    }
                    search(tabContent.querySelector('.search'));

                } else if (tabDetailResult.type === 'chart') {
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
                            name: tabDetailResult.title,
                            data: seriesData,
                        }],
                    });
                }
            }
        }

        //Initialize materialize js tabs features every time
        const tabs = document.querySelectorAll('.tabs');
        M.Tabs.init(tabs, {});

        //Updated materialize js text fields every time
        M.updateTextFields();

        //Set event listener on tabs to resize charts
        document.querySelectorAll('.tab a').forEach(function (element) {
            element.addEventListener('click', function () {
                setTimeout(function () {
                    resizeCharts();
                }, 10);
            });
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
    }
};

const start = function (websocketServerLocation) {
    const socket = new WebSocket(websocketServerLocation);

    socket.onopen = function () {
        if (window.timerID) {
            window.clearInterval(window.timerID);
            window.timerID = 0;
        }
        socket.send('gimme');
    };

    socket.onclose = function () {
        if (!window.timerID) {
            window.timerID = setInterval(function () {
                start(websocketServerLocation);
            }, 5000);
        }
    };

    socket.onmessage = function (event) {
        console.log(new Date());
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
        start(`ws://${host}/websocket`);

        //Handle resizing charts when window is resized
        window.onresize = function () {
            resizeCharts();
        };

        //Handle menu saving
        document.querySelector('#menu-save').addEventListener('click', function () {
            const notificationInputs = document.querySelectorAll('#menu #notifications input');
            notificationInputs.forEach(function (input) {
                if (input.type === 'checkbox') {
                    localStorage.setItem(input.id, input.checked);
                } else {
                    localStorage.setItem(input.id, input.value);
                }
            });
        });
    });
}