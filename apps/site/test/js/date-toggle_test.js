import { assert } from 'chai';
import jsdom from 'mocha-jsdom';
import dateToggle from '../../web/static/js/date-toggle';

describe('date-toggle', () => {
  var $;
  jsdom();

  beforeEach(() => {
    $ = require('jquery');
    $('body').append('<div id=test/>');
    $('#test').html(`
<form>
<span class='date-toggle'><input type=date></span>
<span class='date-toggle date-toggle-enabled'>not input</span>
<span class='date-toggle-edit'>edit</span>
</form>
`);
  dateToggle($);
  });

  afterEach(() => {
    $('#test').remove();
  });

  it('switches which element is enabled when edit is clicked', () => {
    assert.lengthOf($('#test .date-toggle-enabled input'), 0);
    $('#test .date-toggle-edit').click();
    assert.lengthOf($('#test .date-toggle-enabled input'), 1);
    $('#test .date-toggle-edit').click();
    assert.lengthOf($('#test .date-toggle-enabled input'), 0);
  });

  it('focuses/clicks the date input', (done) => {
    $('#test input').click(() => {
      assert.isTrue($('#test input').is(':focus'));
      done();
    });
    $('#test .date-toggle-edit').click();
  });

  it('switches back to its initial state when the input is blurred', () => {
    $('#test .date-toggle-edit').click();
    assert.lengthOf($('#test .date-toggle-enabled input'), 1);
    $('#test .date-toggle-enabled input').blur();
    assert.lengthOf($('#test .date-toggle-enabled input'), 0);
  });
});
