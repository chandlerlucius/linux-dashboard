
self.showNotification('Hello', {body : 'hey!'});

self.addEventListener('message', function (e) {
    var data = e.data;
    // var text = 'High ' + data.title + ' - ' + data.value;
    var frequency = Number.isInteger(parseInt(data.frequency, 10)) ? parseInt(data.frequency, 10) : 15;
    var elaspedMinutes = (Math.abs(new Date() - new Date(data.notifiedDate)) / 1000) / 60;
    if(frequency < elaspedMinutes) {
        if (data.email) {
            // var content = '{"sender":{"email":"clucius08@gmail.com"},"to":[{"email":"clucius08@gmail.com"}], \
            //     "htmlContent":"<h1>' + text + '</h1><br><br><span>Good luck!</span><br><span>Linux Dashboard</span>","subject":"' + text + '"}';
            // var xhr = new XMLHttpRequest();
    
            // xhr.withCredentials = true;
            // xhr.onreadystatechange = function () {
            //     if (this.readyState == 4 && this.status == 200) {
            //         console.log(this.responseText);
            //     }
            // };
            // xhr.open('POST', 'https://api.sendinblue.com/v3/smtp/email');
            // xhr.setRequestHeader('Content-Type', 'application/json');
            // xhr.setRequestHeader('api-key', '');
            // xhr.send(content);
    
            self.postMessage({'key' : data.key + '-notified-date'});
        }
    }
}, false);