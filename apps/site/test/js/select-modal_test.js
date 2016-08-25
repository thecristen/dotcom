import { assert } from 'chai';
import jsdom from 'mocha-jsdom';
import { dataFromSelect, $newModal, renderModal, filterData } from '../../web/static/js/select-modal';

describe('selectModal', () => {
  const options = [
    {name: 'Selected', value: '1', selected: true},
    {name: 'Disabled', value: '0', disabled: true},
    {name: 'Regular', value: 'reg'}
  ];

  var $;
  jsdom();

  beforeEach(() => {
    $ = jsdom.rerequire('jquery');
  });

  describe('dataFromSelect', () => {

    beforeEach(() => {
      $('body').append('<div id=test />');
      $('#test').html(`
<select>
<option value="">Make a selection</option>
<option value=1 selected>Selected</option>
<option value=0 disabled>Disabled</option>
<option value="reg">Regular</option>
</select>
`);
    });

    afterEach(() => {
      $('#test').remove();
    });

    it('generates a list of objects', () => {
      assert.deepEqual(dataFromSelect($("#test select"), $), options);
    });
  });

  describe('$newModal', () => {
    afterEach(() => {
      $('body').empty();
    });

    it('creates a new modal with a different ID', () => {
      $newModal('test', $);
      assert.lengthOf($('#test'), 0);
      assert.lengthOf($('body').find('.modal'), 1);
    });

    it('does not create the name element if it exists', () => {
      const $el = $newModal('test', $);
      const $el2 = $newModal('test', $);
      assert.equal($el[0], $el2[0]);
      assert.lengthOf($('body').find('.modal'), 1);
    });

    it('remembers the original ID', () => {
      const $el = $newModal('test', $);
      assert.equal($el.data('originalId'), '#test');
    });
  });

  describe('renderModal', () => {
    var $modal;

    beforeEach(() => {
      $('body').append('<div id=modal />');
      $modal = $('#modal');
      renderModal($modal, options);
    });

    afterEach(() => {
      $modal.remove();
    });

    it('creates a search input', () => {
      assert.lengthOf($modal.find('input[type=search]'), 1);
    });

    it('creates a modal-select-option for each option', () => {
      const $options = $modal.find('.select-modal-option') ;
      assert.lengthOf($options, 3);
    });

    it('sets modal-select-option-selected on the selection options', () => {
      const $options = $modal.find('.select-modal-option') ;
      assert.deepEqual($options
                       .map((_index, el) => $(el).hasClass('select-modal-option-selected'))
                       .get(),
                       [true, false, false]);
    });

    it('sets modal-select-option-disabled on the selection options', () => {
      const $options = $modal.find('.select-modal-option') ;
      assert.deepEqual($options
                       .map((_index, el) => $(el).hasClass('select-modal-option-disabled'))
                       .get(),
                       [false, true, false]);
    });

    it('sets text on the selection options', () => {
      const $options = $modal.find('.select-modal-option') ;
      assert.deepEqual($options
                       .map((_index, el) => $(el).text().trim())
                       .get(),
                       ['Selected', 'Disabled', 'Regular']);
    });

    it('sets value on the selection options', () => {
      const $options = $modal.find('.select-modal-option');
      // jQuery converts the values, but it's not a big deal #javascript -ps
      assert.deepEqual($options
                       .map((_index, el) => $(el).data('value'))
                       .get(),
                       [1, 0, 'reg']);
    });
  });

  describe('filterData', () => {
    it('returns the items which match the query string', () => {
      const result = filterData(options, 'reg');
      assert.deepEqual(result, [options[2]]);
    });

    it('keeps the items in order regardless of score', () => {
      var result = filterData(options, 'ed');
      assert.deepEqual(result, [options[0], options[1]]);

      result = filterData(options, 'l');
      assert.deepEqual(result, options);
    });
  });
});
