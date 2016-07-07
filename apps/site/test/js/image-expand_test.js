import { assert } from 'chai';
import jsdom from 'mocha-jsdom';
import imageExpand from '../../web/static/js/image-expand';

describe('image-expand', () => {
    var $;
    jsdom();

    beforeEach(() => {
        $ = require('jquery');
        $('body').append('<div><div class="expandable"></div><div class="other"></div></div>');
        imageExpand($);
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
