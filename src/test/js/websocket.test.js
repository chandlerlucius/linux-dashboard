const websocket = require('../../main/resources/static/js/websocket')

describe('Escape HTML Function - escapeHTML()', function () {
    it('should convert all the unsafe HTML characters into HTML entities', function () {
        expect(websocket.escapeHTML('&<>"\'')).toBe('&amp;&lt;&gt;&quot;&apos;');
    });

    it('should leave all the safe HTML characters the way they are', function () {
        expect(websocket.escapeHTML('qwertyuiopasdfghjklzxcvbnm')).toBe('qwertyuiopasdfghjklzxcvbnm');
    });
});