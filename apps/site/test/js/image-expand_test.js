import { assert } from 'chai';
import jsdom from 'mocha-jsdom';
import imageExpand from '../../web/static/js/image-expand';

describe('image-expand', () => {
  var $;
  jsdom();

  before(() => {
    $ = jsdom.rerequire('jquery');
    imageExpand($);
  });

  beforeEach(() => {
    $('body').append('<div id="test"><div class="expandable"></div><div class="other"></div></div>');
  });

  afterEach(() => {
    $("#test").remove();
  });

  it('toggles the "expanded" class on click', () => {
    assert.lengthOf($('.expanded'), 0);
    $('.expandable').click();
    assert.lengthOf($('.expandable.expanded'), 1);
    assert.lengthOf($('.other.expanded'), 0);
    $('.expandable').click();
    assert.lengthOf($('.expanded'), 0);
  });
});
