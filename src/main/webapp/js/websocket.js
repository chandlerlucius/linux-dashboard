//Initialize socket timeout
let socketTimeout;
let url;

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

// const populateHidden = function (element) {
//     element.innerHTML = '<a class="waves-effect waves-light btn-small" onclick="populateRow(this.parentElement);">Click to Populate -></a>';
// };

// const populateRow = function (element) {
//     const title = element.closest('.card').querySelector('.card-title').innerHTML;
//     const tr = element.closest('tr');
//     if (title === _('Connections')) {
//         const ip = element.previousSibling.innerHTML;
//         const xhr = new XMLHttpRequest();
//         xhr.onreadystatechange = function () {
//             if (this.readyState === 4 && this.status === 200) {
//                 const json = JSON.parse(xhr.responseText);
//                 const array = [json.city, json.region, json.country, json.postal];
//                 element.innerHTML = json.org;
//                 for (let i = 0; i < 4; i += 1) {
//                     const td = tr.insertCell(i + 3);
//                     td.innerHTML = array[i];
//                 }
//             }
//         };
//         xhr.open('GET', `https://ipapi.co/${ip}/json/`, true);
//         xhr.send();
//     }
// };

const drawChart = function (chart, xAxisData, seriesData) {
    chart.setOption({
        animation: false,
        grid: {
            top: 0,
            left: 0,
            right: 0,
            bottom: 20,
            containLabel: true
        },
        tooltip: {
            trigger: 'axis',
            formatter(params) {
                let result;
                params.forEach(function (item) {
                    result = `<p>` +
                        `<span style="display:inline-block;margin-right:5px;border-radius:10px;width:9px;height:9px;background-color:${item.color}">` +
                        `</span> ${item.seriesName}: ${item.data}% </p>`;
                });
                return result;
            },
        },
        xAxis: {
            boundaryGap: false,
            data: xAxisData,
            axisLabel: {
                color: 'white',
                align: 'left',
                interval: function(index) {
                    return index == 0 || index == 60 ? true : false;
                }
            },
        },
        yAxis: {
            min: 0,
            max: 100,
            axisLabel: {
                show: false
            },
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

// const createSearchRow = function (rows, tabContent, table, json) {
//     const row = rows[l];
//     const key = json.key;
//     const tabSearchTrId = `tab-search-${key}`;
//     let tabSearchTr = tabContent.querySelector(`#${tabSearchTrId}`);
//     if (tabSearchTr === null) {
//         tabSearchTr = table.getElementsByTagName('tbody')[0].insertRow();
//         tabSearchTr.id = tabSearchTrId;
//     }
//     if (l === 0) {
//         tabSearchTr.classList.add('white-text');
//     }

//     const cols = row.split('|');
//     for (let m = 0; m < cols.length; m += 1) {
//         const col = cols[m];
//         const tabSearchTdId = `tab-search-${key}`;
//         let tabSearchTd = tabContent.querySelector(`#${tabSearchTdId}`);
//         if (tabSearchTd === null) {
//             tabSearchTd = tabSearchTr.insertCell(m);
//             tabSearchTd.id = tabSearchTdId;
//             if (col === '[hidden]') {
//                 populateHidden(tabSearchTd);
//             } else if (col === '[client-request]') {
//                 populateRow(tabSearchTd);
//             } else {
//                 //Skip the row
//             }
//         }
//         if (tabSearchTd != null && col !== '[hidden]' && col !== '[client-request]') {
//             tabSearchTd.innerHTML = escapeHTML(col);
//         }
//     }
// };

const handleGroups = function (groups) {
    groups.forEach(function (group) {
        const id = group.id;
        const title = group.title;
        const subgroups = group.subgroups;

        const tabId = `tab-${id}`;
        const tabTitleId = `tab-title-${id}`;
        let tab = document.querySelector(`#${tabId}`);
        if (tab === null) {
            const tabTitleTemplate = document.querySelector('#tab-title-template').content.cloneNode(true);
            tabTitleTemplate.querySelector('a').id = tabTitleId;
            // if (i === 0) {
            //     tabTitleTemplate.querySelector('a').class = 'active';
            // }
            document.querySelector('#tab-title-list').appendChild(tabTitleTemplate);

            const tabContainerTemplate = document.querySelector('#tab-container-template').content.cloneNode(true);
            tabContainerTemplate.querySelector('div').id = tabId;
            document.querySelector('main').appendChild(tabContainerTemplate);
            tab = document.querySelector(`#${tabId}`);
        }
        const tabTitle = document.querySelector(`#${tabTitleId}`);
        tabTitle.innerHTML = _(title);
        tabTitle.href = `#${tabId}`;

        handleSubgroups(id, subgroups);
    });
};

const handleSubgroups = function (groupId, subgroups) {
    subgroups.forEach(function (subgroup) {
        const id = subgroup.id;
        const title = subgroup.title;
        const type = subgroup.type;
        const properties = subgroup.properties;

        const tab = document.querySelector(`#tab-${groupId}`);
        const tabContentId = `tab-content-${id}`;
        let tabContent = tab.querySelector(`#${tabContentId}`);
        if (tabContent === null) {
            const tabContentTemplate = document.querySelector('#tab-content-template').content.cloneNode(true);
            tabContentTemplate.querySelector('div').id = tabContentId;
            tab.appendChild(tabContentTemplate);
            tabContent = tab.querySelector(`#${tabContentId}`);
        }
        tabContent.querySelector('.card-title').innerHTML = _(title);

        if (type === 'chart') {
            tabContent.querySelector('.card-chart').style.display = '';
            tabContent.querySelector('.card').classList.remove('small');
        } else if (type === 'search') {
            tabContent.querySelector('.card-search').style.display = '';
            tabContent.querySelector('.card').classList.remove('small');
            tabContent.querySelector('.card').classList.add('large');
        } else {
            //Skip the group
        }

        handleProperties(id, properties);
    });
};

const handleProperties = function (subgroupId, properties) {
    properties.forEach(function (property) {
        const id = property.id;
        const type = property.type;

        const tabContentId = `tab-content-${subgroupId}`;
        const tabContent = document.querySelector(`#${tabContentId}`);

        //Handle tab details
        if (type === 'detail') {
            handleDetailProperty(`${id}_detail`, tabContent);
        } else if (type === 'chart') {
            // handleDetailProperty(`${id}_detail`, tabContent);
            handleChartProperty(`${id}_chart`, tabContent);
        } else if (type === 'search') {
            // handleSearchProperty(tabContent);
        } else {
            //Skip the tab
        }
        // socket.send(id);
    });
};

const handleDetailProperty = function (id, tabContent) {
    let count = 0;
    let tabDetailTableId = `tab-detail-table-0`;
    let tabDetailTable = tabContent.querySelector(`#${tabDetailTableId}`);
    if (tabDetailTable != null) {
        count = Math.floor((tabDetailTable.rows.length - 1) / 4);
        tabDetailTableId = `tab-detail-table-${count}`;
        tabDetailTable = tabContent.querySelector(`#${tabDetailTableId}`);
    }
    if (tabDetailTable === null) {
        const tabDetailTableTemplate = document.querySelector('#tab-detail-table-template').content.cloneNode(true);
        tabDetailTableTemplate.querySelector('table').id = tabDetailTableId;
        tabContent.querySelector('.card-detail').appendChild(tabDetailTableTemplate);
        tabDetailTable = tabContent.querySelector(`#${tabDetailTableId}`);
    }
    if (count > 0) {
        for (let i = 0; i <= count; i++) {
            const tmpId = `tab-detail-table-${i}`;
            const tmpTable = tabContent.querySelector(`#${tmpId}`);
            tmpTable.style.width = '50%';
            tmpTable.style.float = 'left';
        }
    }

    const tabDetailId = `tab-detail-${id}`;
    const tabDetail = tabContent.querySelector(`#${tabDetailId}`);
    if (tabDetail === null) {
        const tabDetailTemplate = document.querySelector('#tab-detail-template').content.cloneNode(true);
        tabDetailTemplate.querySelector('tr').id = tabDetailId;
        tabDetailTable.querySelector('tbody').appendChild(tabDetailTemplate);
    }
};

const handleChartProperty = function (id, tabContent) {
    //Show chart and remove height restriction on card
    tabContent.querySelector('.card-chart').style.display = '';
    tabContent.querySelector('.card').classList.remove('small');
    tabContent.querySelector('.card').classList.add('large');

    //Update data within chart
    const tabChartId = `tab-chart-${id}`;
    let tabChart = tabContent.querySelector(`#${tabChartId}`);
    const total = 300;
    if (tabChart === null) {
        tabChart = tabContent.querySelector('.card-chart');
        tabChart.id = tabChartId;

        const origXAxisData = [];
        for (let l = total; l > 0; l--) {
            origXAxisData.push(l);
        }

        const seriesData = [];
        for (let l = total; l > 0; l--) {
            seriesData.push(0);
        }

        const origChart = echarts.init(tabChart, null, {});
        chartMap.set(`${id}`, tabChart);
        drawChart(origChart, origXAxisData, seriesData);
    }
};

// const handleSearchProperty = function (tabContent) {
//     //Show search and make card large
//     tabContent.querySelector('.card-search').style.display = '';
//     tabContent.querySelector('.card').classList.remove('small');
//     tabContent.querySelector('.card').classList.add('large');
//     tabContent.querySelector('.card-detail').classList.add('search-table');

//     //Update table with searchable data
//     const table = tabContent.querySelector('table');
//     const rows = json.value.split('#');
//     for (let l = 0; l < rows.length - 1; l += 1) {
//         createSearchRow(rows, tabContent, table, json);
//     }

//     const rowCount = table.querySelectorAll('tr').length - 1;
//     for (let l = rows.length; l < rowCount; l += 1) {
//         table.deleteRow(l);
//     }
//     search(tabContent.querySelector('.search'));
// };

const createDetails = function (json) {
    const type = json.type;

    //Handle toast details
    createToastDetails(json);

    //Handle tab details
    if (type === 'detail') {
        createDetailDetails(json);
    } else if (type === 'chart') {
        // createDetailDetails(json);
        createChartDetails(json);
    } else if (type === 'search') {
        // createSearchDetails(json, tabContent);
    } else {
        //Skip the tab
    }
};

const createDetailDetails = function (json) {
    const id = `${json.id}_detail`;
    const title = json.title;
    const value = json.value;

    const tabDetailId = `tab-detail-${id}`;
    const tabDetail = document.querySelector(`#${tabDetailId}`);
    tabDetail.querySelector('strong').innerHTML = _(title);
    tabDetail.querySelector('span').innerHTML = value;
};

const createChartDetails = function (json) {
    const id = `${json.id}_chart`;
    const title = json.title;
    const xAxisData = json.value[0];
    const seriesData = json.value[1];

    //Update data within chart
    const tabChartId = `tab-chart-${id}`;
    const tabChart = document.querySelector(`#${tabChartId}`);

    const chart = echarts.getInstanceByDom(tabChart);
    // const xAxisData = chart.getOption().xAxis[0].data;
    // const seriesData = chart.getOption().series[0].data;

    // seriesData.shift();
    // seriesData[total - 1] = value;
    chart.setOption({
        xAxis: {
            data: xAxisData,
        },
        series: [{
            name: _(title),
            data: seriesData,
        }],
    });
};

// const createSearchDetails = function (json, tabContent) {
//     //Show search and make card large
//     tabContent.querySelector('.card-search').style.display = '';
//     tabContent.querySelector('.card').classList.remove('small');
//     tabContent.querySelector('.card').classList.add('large');
//     tabContent.querySelector('.card-detail').classList.add('search-table');

//     //Update table with searchable data
//     const table = tabContent.querySelector('table');
//     const rows = json.value.split('#');
//     for (let l = 0; l < rows.length - 1; l += 1) {
//         createSearchRow(rows, tabContent, table, json);
//     }

//     const rowCount = table.querySelectorAll('tr').length - 1;
//     for (let l = rows.length; l < rowCount; l += 1) {
//         table.deleteRow(l);
//     }
//     search(tabContent.querySelector('.search'));
// };

const createToastDetails = function (json) {
    const title = json.title;
    const value = json.value;
    const threshold = json.threshold;

    //Handle toasts for thresholds
    const key = title.toLowerCase().replace(/ /g, '_');
    const thresholdKey = `${key}-threshold`;
    let storedThreshold = localStorage.getItem(thresholdKey);

    if (threshold !== '' && threshold === null) {
        storedThreshold = threshold;
        localStorage.setItem(thresholdKey, threshold);
    }
    if (storedThreshold !== null) {
        const exceededThreshold = parseFloat(value) > parseFloat(storedThreshold);
        const toastTitleElement = document.querySelector(`#${thresholdKey}_title`);
        const toastValueElement = document.querySelector(`#${thresholdKey}_value`);
        const toastTitle = _(`High ${title}`);
        const toastValue = `${value}%`;
        if (toastTitleElement === null && exceededThreshold) {
            const toastHTML =
                `<span id='${thresholdKey}_title'>${toastTitle}</span>` +
                `<span id='${thresholdKey}_value' class='lime-text accent-2-text'>${toastValue}</span>` +
                `<button class='btn-flat toast-action modal-trigger' href='#menu'>Edit</button>`;
            M.toast({
                html: toastHTML,
                displayLength: Infinity
            });
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

const clearSocketTimeout = function () {
    if (socketTimeout) {
        clearTimeout(socketTimeout);
    }
};

const setSocketTimeout = function () {
    console.log('Socket closed. Attempting reconnect in 5 seconds.');
    socketTimeout = setTimeout(function () {
        start();
    }, 5000);
};

const start = function () {
    try {
        const socket = new WebSocket(url);
        socket.onopen = function () {
            clearSocketTimeout();
        };

        socket.onclose = function () {
            setSocketTimeout();
        };

        socket.onerror = function () {
            socket.close();
        };

        socket.onmessage = function (event) {
            const json = JSON.parse(event.data);
            if (json.groups) {
                handleGroups(json.groups);
                init();
            } else {
                createDetails(json);
            }
        };
    } catch (error) {
        //Ignore error on purpose
    }
};

if (window) {
    window.addEventListener('DOMContentLoaded', function () {
        //Start websocket connection
        const host = window.location.host;
        if (window.location.protocol === 'https:') {
            url = `wss://${host}/websocket`;
        } else {
            url = `ws://${host}/websocket`;
        }
        start();

        //Handle resizing charts when window is resized
        window.onresize = function () {
            resizeCharts();
        };
    });
}

if (typeof exports !== 'undefined') {
    exports.escapeHTML = escapeHTML;
}