'use strict';

self.addEventListener('message', function (e) {
    const data = e.data;
    const text = `High ${data.title} - ${data.value}`;
    const elaspedMinutes = (Math.abs(new Date() -
        new Date(data.notifiedDate)) / 1000) / 60;
    let frequency;
    if (Number.isInteger(parseInt(data.frequency, 10))) {
        frequency = parseInt(data.frequency, 10);
    } else {
        frequency = 15;
    }
    if (frequency < elaspedMinutes) {
        if (data.email) {
            const content =
                '{"sender":{"email":"clucius08@gmail.com"},' +
                '"to":[{"email":"clucius08@gmail.com"}],' +
                '"htmlContent":"<h1>' + text + '</h1>' +
                '<br><br><span>Good luck!</span><br>' +
                '<span>Linux Dashboard</span>",' +
                '"subject":"' + text + '"}';
            const xhr = new XMLHttpRequest();

            xhr.withCredentials = true;
            xhr.onreadystatechange = function () {
                if (this.readyState == 4 && this.status == 200) {
                    console.log(this.responseText);
                }
            };
            xhr.open('POST', 'https://api.sendinblue.com/v3/smtp/email');
            xhr.setRequestHeader('Content-Type', 'application/json');
            xhr.setRequestHeader('api-key', '');
            xhr.send(content);

            self.postMessage({ 'key': data.key + '-notified-date' });
        }
    }
}, false);
