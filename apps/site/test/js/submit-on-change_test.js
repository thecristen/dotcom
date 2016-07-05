import { assert } from 'chai';
import jsdom from 'mocha-jsdom';
import submitOnChange from '../../web/static/js/submit-on-change';

describe('submit-on-change', () => {

  var $;
  jsdom();

  beforeEach(() => {
    $ = require('jquery');
    $('body').append('<div id=test></div>');
    $('#test').html('<form data-submit-on-change><input type=text><select><option value=1>1</select><button type=submit>Submit</button></form>');
    submitOnChange($);
  });

  afterEach(() => {
    $('#test').remove();
    $ = undefined;
  });

  it('hides submit button', () => {
    assert.equal($('#test button').css('display'), 'none');
  });

  it('submits the form if the input changes', (done) => {
    $('#test form').submit(() => done());
    $('#test input').change();
  });

  it('submits the form if the select is changed', (done) => {
    $('#test form').submit(() => done());
    $('#test select').change();
  });
});
