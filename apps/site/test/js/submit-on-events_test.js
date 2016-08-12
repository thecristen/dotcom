import { assert } from 'chai';
import jsdom from 'mocha-jsdom';
import submitOnEvents from '../../web/static/js/submit-on-events';

describe('submit-on-event', () => {

  var $;
  jsdom();

  beforeEach(() => {
    $ = require('jquery');
    $('body').append('<div id=test></div>');
    $('#test').html('<form data-submit-on-change><input type=text><label><i class="loading-indicator hidden-xs-up"></i></label><select><option value=1>1</select><button type=submit>Submit</button></form>');
    submitOnEvents(["change"], $);
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

  it('displays a loading indicator', () => {
    assert($('.loading-indicator').hasClass('hidden-xs-up'));
    $('#test select').change();
    assert.isNotTrue($('.loading-indicator').hasClass('hidden-xs-up'));
  });
});
