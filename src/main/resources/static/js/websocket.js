//Handle reconnecting websocket
var timerID = 0;

//Handle initiliazation features
var init = false;

//Handle resizing charts with window
var chartMap = new Map();

window.addEventListener('DOMContentLoaded', (event) => {
    //Start websocket connection 
    var host = window.location.host;
    start("ws://" + host + "/websocket");

    //Handle resizing charts when window is resized
    window.onresize = function () {
        resizeCharts();
    };
});

function start(websocketServerLocation) {
    var socket = new WebSocket(websocketServerLocation);

    socket.onopen = function (event) {
        if (window.timerID) {
            window.clearInterval(window.timerID);
            window.timerID = 0;
        }
    }

    socket.onclose = function (event) {
        if (!window.timerID) {
            window.timerID = setInterval(function () {
                start(websocketServerLocation)
            }, 5000);
        }
    }

    socket.onmessage = function (event) {
        console.log(new Date());
        var json = JSON.parse(event.data);

        for (var i = 0; i < json.results.length; i++) {
            var tabResult = json.results[i];
            var tabId = "tab-" + i;
            var tabTitleId = "tab-title-" + i;
            var tab = document.querySelector("#" + tabId);
            if (tab === null) {
                var tabTitleTemplate = document.querySelector("#tab-title-template").content.cloneNode(true);
                tabTitleTemplate.querySelector("a").id = tabTitleId;
                if (i === 0) {
                    tabTitleTemplate.querySelector("a").class = "active";
                }
                document.querySelector("#tab-title-list").appendChild(tabTitleTemplate);

                var tabContainerTemplate = document.querySelector("#tab-container-template").content.cloneNode(true);
                tabContainerTemplate.querySelector("div").id = tabId;
                document.querySelector("main").appendChild(tabContainerTemplate);
                tab = document.querySelector("#" + tabId);
            }
            var tabTitle = document.querySelector("#" + tabTitleId);
            tabTitle.innerHTML = tabResult.title;
            tabTitle.href = "#" + tabId;

            var tabValues = tabResult.values;
            for (var j = 0; j < tabValues.length; j++) {
                var groupResult = tabValues[j];
                var tabContentId = "tab-content-" + i + "-" + j;
                var tabContent = tab.querySelector("#" + tabContentId);
                if (tabContent === null) {
                    var tabContentTemplate = document.querySelector("#tab-content-template").content.cloneNode(true);
                    tabContentTemplate.querySelector("div").id = tabContentId;
                    tab.appendChild(tabContentTemplate);
                    tabContent = tab.querySelector("#" + tabContentId);
                }
                tabContent.querySelector(".card-title").innerHTML = groupResult.title;

                if (groupResult.type === "chart") {
                    tabContent.querySelector(".card-chart").style.display = "";
                    tabContent.querySelector(".card").classList.remove("small");
                } else if (groupResult.type === "search") {
                    tabContent.querySelector(".card-search").style.display = "";
                    tabContent.querySelector(".card").classList.remove("small");
                    tabContent.querySelector(".card").classList.add("large");
                }

                var groupValues = groupResult.values;
                for (var k = 0; k < groupValues.length; k++) {
                    var tabDetailResult = groupValues[k];
                    if (tabDetailResult.type === "detail") {
                        //Update table with detail data
                        var tabDetailId = "tab-detail-" + i + "-" + j + "-" + k;
                        var tabDetail = tabContent.querySelector("#" + tabDetailId);
                        if (tabDetail === null) {
                            var tabDetailTemplate = document.querySelector("#tab-detail-template").content.cloneNode(true);
                            tabDetailTemplate.querySelector("tr").id = tabDetailId;
                            tabContent.querySelector(".card-detail table").appendChild(tabDetailTemplate);
                            tabDetail = tabContent.querySelector("#" + tabDetailId);
                        }
                        tabDetail.querySelector("b").innerHTML = tabDetailResult.title;
                        tabDetail.querySelector("span").innerHTML = tabDetailResult.value;

                    } else if (tabDetailResult.type === "search") {
                        //Show search and make card large
                        tabContent.querySelector(".card-search").style.display = "";
                        tabContent.querySelector(".card").classList.remove("small");
                        tabContent.querySelector(".card").classList.add("large");
                        tabContent.querySelector(".card-detail").classList.add("search-table")

                        //Update table with searchable data
                        var table = tabContent.querySelector("table");
                        var rows = tabDetailResult.value.split("#");
                        for (var l = 0; l < rows.length - 1; l++) {
                            var row = rows[l];
                            var tabSearchTrId = "tab-search-" + i + "-" + j + "-" + k + "-" + l;
                            var tabSearchTr = tabContent.querySelector("#" + tabSearchTrId);
                            if (tabSearchTr === null) {
                                tabSearchTr = table.insertRow(l);
                                tabSearchTr.id = tabSearchTrId;
                            }
                            if (l === 0) {
                                tabSearchTr.classList.add("white-text");
                            }

                            var cols = row.split("|");
                            for (var m = 0; m < cols.length; m++) {
                                var col = cols[m];
                                var tabSearchTdId = "tab-search-" + i + "-" + j + "-" + k + "-" + l + "-" + m;
                                var tabSearchTd = tabContent.querySelector("#" + tabSearchTdId);
                                if (tabSearchTd === null) {
                                    tabSearchTd = tabSearchTr.insertCell(m);
                                    tabSearchTd.id = tabSearchTdId;
                                    if (col === "[hidden]") {
                                        populateHidden(tabSearchTd);
                                    } else if(col === "[client-request]") {
                                        populateRow(tabSearchTd);
                                    }
                                }
                                if (col !== "[hidden]" && col !== "[client-request]") {
                                    tabSearchTd.innerHTML = escapeHtml(col);
                                }
                            }

                            var rowCount = table.querySelectorAll("tr").length - 1;
                            for (var m = rows.length; m < rowCount; m++) {
                                table.deleteRow(m);
                            }
                        }
                        search(tabContent.querySelector(".search"));

                    } else if (tabDetailResult.type === "chart") {
                        //Show chart and remove height restriction on card
                        tabContent.querySelector(".card-chart").style.display = "";
                        tabContent.querySelector(".card").classList.remove("small");
                        tabContent.querySelector(".card").classList.add("large");

                        //Update data within chart
                        var tabChartId = "tab-chart-" + i + "-" + j + "-" + k;
                        var tabChart = tabContent.querySelector("#" + tabChartId);
                        var total = 30;
                        if (tabChart === null) {
                            tabChart = tabContent.querySelector('.card-chart');
                            tabChart.id = tabChartId;

                            var xAxisData = [];
                            for (var k = total; k > 0; k--) {
                                xAxisData.push(k);
                            }

                            var seriesData = [];
                            for (var k = total; k > 0; k--) {
                                seriesData.push(0)
                            }

                            var chart = echarts.init(tabChart, null, {});
                            chartMap.set(i + "_" + j + "_" + k, tabChart);
                            drawChart(chart, xAxisData, seriesData);
                        }

                        var chart = echarts.getInstanceByDom(tabChart);
                        var xAxisData = chart.getOption().xAxis[0].data;
                        var seriesData = chart.getOption().series[0].data;

                        seriesData.shift();
                        seriesData[total - 1] = tabDetailResult.value;
                        chart.setOption({
                            xAxis: {
                                data: xAxisData
                            },
                            series: [{
                                name: tabDetailResult.title,
                                data: seriesData
                            }]
                        });
                    }
                }
            }

            //Initialize materialize js features every time
            var tabs = document.querySelectorAll('.tabs');
            M.Tabs.init(tabs, {});
    
            //Set event listener on tabs to resize charts
            document.querySelectorAll(".tab a").forEach(element => {
                element.addEventListener('click', function () {
                    setTimeout(function () {
                        resizeCharts();
                    }, 10);
                });
            });

            if(!init) {
                //Initialize materialize js features once
                var navs = document.querySelectorAll('.sidenav');
                M.Sidenav.init(navs, {});
    
                //Hide progress bar
                document.getElementsByClassName("progress")[0].style.display = "none";
            }
            init = true;
        }
    }
}

function drawChart(chart, xAxisData, data) {
    chart.setOption({
        animation: false,
        grid: {
            top: 0,
            left: 0,
            right: 0,
            bottom: 0
        },
        tooltip: {
            trigger: 'axis',
            formatter: function (params) {
                var colorSpan = color => '<span style="display:inline-block;margin-right:5px;border-radius:10px;width:9px;height:9px;background-color:' + color + '"></span>';
                var result;
                params.forEach(item => {
                    result = '<p>' + colorSpan(item.color) + ' ' + item.seriesName + ': ' + item.data + '%' + '</p>'
                });
                return result;
            }
        },
        xAxis: {
            axisLabel: {
                show: false
            },
            boundaryGap: false,
            data: xAxisData
        },
        yAxis: {
            axisLabel: {
                show: false
            },
            max: 100
        },
        series: [{
            type: 'line',
            data: data,
            itemStyle: {
                color: '#00bfa5'
            },
            symbolSize: 2,
            areaStyle: {}
        }]
    });
}

function resizeCharts() {
    chartMap.forEach(function (value, key, map) {
        if (value.closest(".row").style.display !== 'none') {
            window.echarts.getInstanceByDom(value).resize();
        }
    });
}

function search(element) {
    var filter = element.value.toUpperCase();
    var table = element.closest(".card").querySelector("table");
    var trs = table.getElementsByTagName("tr");

    for (var i = 1; i < trs.length; i++) {
        var found = false;
        var tr = trs[i];
        var tds = tr.getElementsByTagName("td");
        for (var j = 0; j < tds.length; j++) {
            var td = tds[j];
            if (td) {
                var text = td.textContent || td.innerText;
                if (text.toUpperCase().indexOf(filter) > -1) {
                    found = true;
                }
            }
        }
        if (found) {
            tr.style.display = "";
        } else {
            tr.style.display = "none";
        }
    }
}

function clearSearch(element) {
    var parentElement = element.parentElement;
    var searchElement = parentElement.querySelector(".search");
    searchElement.value = '';
    search(searchElement);
}

function populateHidden(element) {
    element.innerHTML = "<a class='waves-effect waves-light btn-small' onclick='populateRow(this.parentElement);'>Click to Populate -></a>";
}

function populateRow(element) {
    var title = element.closest(".card").querySelector(".card-title").innerHTML;
    var tr = element.closest("tr");
    if (title === "Connections") {
        var ip = element.previousSibling.innerHTML;
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (this.readyState == 4 && this.status == 200) {
                var json = JSON.parse(xhr.responseText);
                var array = [json.city, json.region, json.country, json.postal];
                element.innerHTML = json.org;
                for(var i = 0; i < 4; i++) {
                    var td = tr.insertCell(i + 3);
                    td.innerHTML = array[i];
                }
            }
        };
        xhr.open("GET", "https://ipapi.co/" + ip + "/json/ ", true);
        xhr.send();
    }
}

function escapeHtml(unsafe) {
    return unsafe
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#039;");
}