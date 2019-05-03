// let assert = require('assert');
// let websocket = require('../../main/resources/static/js/websocket.js')

// describe('Escape HTML', function() {
//   describe('when escapeHTML is called', function() {
//     it('should convert all the unsafe HTML characters into HTML entities', function() {
//       assert.equal('&amp;&lt;&gt;&quot;&apos;', websocket.escapeHTML('&<>"\''));
//     });
//   });
// });

const websocket = require('../../main/resources/static/js/websocket')

test('should convert all the unsafe HTML characters into HTML entities', function() {
    expect(websocket.escapeHTML('&<>"\'')).toBe('&amp;&lt;&gt;&quot;&apos;');
});