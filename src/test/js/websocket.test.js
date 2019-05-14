const rewire = require('rewire');
const websocket = rewire('../../main/resources/com/utils/dashboard/js/websocket.js');

describe('Escape HTML Function - escapeHTML()', function () {
    const escapeHTML = websocket.__get__('escapeHTML');

    it('should convert all the unsafe HTML characters into HTML entities', function () {
        expect(escapeHTML('&<>"\'')).toBe('&amp;&lt;&gt;&quot;&apos;');
    });

    it('should leave all the safe HTML characters the way they are', function () {
        expect(escapeHTML('qwertyuiopasdfghjklzxcvbnm')).toBe('qwertyuiopasdfghjklzxcvbnm');
    });
});
