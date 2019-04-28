
// var toastInterval, emailInterval, smsInterval, chatInterval, notificationInterval;

// // Loop through localStorage to get thresholds
// Object.keys(localStorage).forEach(function(key) {
//     console.log(key, ' = ', localStorage[key]);
//     if(key.indexOf("threshold") !== -1) {
//         var threshold = localStorage[key];
//         var frequency = localStorage[key.replace("threshold", "frequency")];

//         notifications.forEach(function(notification) {
//             var interval = setInterval(function() {

//             }, frequency * 60 * 1000);
//         });
//     }
//  });

// var toastInterval = setInterval(handleToast, ); 

var intervalMap = new Map();

self.showNotification('Hello', {body : 'hey!'});

self.addEventListener('message', function (e) {
    var data = e.data;
    var text = "High " + data.title + " - " + data.value;
    var frequency = Number.isInteger(parseInt(data.frequency)) ? parseInt(data.frequency) : 15;
    var elaspedMinutes = (Math.abs(new Date() - new Date(data.notifiedDate)) / 1000) / 60;
    if(frequency < elaspedMinutes) {
        if (data.email) {
            // var content = '{"sender":{"email":"clucius08@gmail.com"},"to":[{"email":"clucius08@gmail.com"}],"htmlContent":"<h1>' + text + '</h1><br><br><span>Good luck!</span><br><span>Linux Dashboard</span>","subject":"' + text + '"}';
            // var xhr = new XMLHttpRequest();
    
            // xhr.withCredentials = true;
            // xhr.onreadystatechange = function () {
            //     if (this.readyState == 4 && this.status == 200) {
            //         console.log(this.responseText);
            //     }
            // };
            // xhr.open("POST", "https://api.sendinblue.com/v3/smtp/email");
            // xhr.setRequestHeader("Content-Type", "application/json");
            // xhr.setRequestHeader("api-key", "");
            // xhr.send(content);
    
            self.postMessage({'key' : data.key + "-notified-date"});
        }
    }
}, false);