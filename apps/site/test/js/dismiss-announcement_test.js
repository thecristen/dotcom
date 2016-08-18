import { assert } from 'chai';
import jsdom from 'mocha-jsdom';
import dismissAnnouncement from '../../web/static/js/dismiss-announcement';

describe('dismiss-announcement', () => {
  var $;
  jsdom();

  before(() => {
    $ = jsdom.rerequire('jquery');
    dismissAnnouncement($);
  });

  beforeEach(() => {
    $('body').append(
      '<div class="alert-container">Message<a data-cookie-name="test-cookie" id="beta-announcement-dismiss">Dismiss</a></div>'
    );
  });

  afterEach(() => {
    // Clear out the beta announcement cookie between tests
    document.cookie = 'test-cookie=; expires=Thu, 01 Jan 1970 00:00:01 GMT';
    $(".alert-container").remove();
  });

  it('hides the announcement on click', () => {
    assert.lengthOf($('.alert-container'), 1);
    $('#beta-announcement-dismiss').click();
    assert.lengthOf($('.alert-container'), 0);
  });

  it('drops a cookie on click', () => {
    assert.equal(document.cookie, '');
    $('#beta-announcement-dismiss').click();
    assert.equal(document.cookie, 'test-cookie=true');
  });
});
