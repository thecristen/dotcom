import { assert } from 'chai';
import jsdom from 'mocha-jsdom';
import { dataFromSelect,
         optionsFromSelect,
         $newModal,
         renderModal,
         filterData } from '../../web/static/js/select-modal';

describe('selectModal', () => {
  const data = [
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
      assert.deepEqual(dataFromSelect($("#test select"), $), data);
    });
  });

  describe('optionsFromSelect', () => {
    beforeEach(() => {
      $('body').append('<div id=test />');
      $('#test').html(`
<label for='sel'>Label</label>
<select id='sel'></select>
`);
    });

    afterEach(() => {
      $('#test').remove();
    });

    it('generates configuration data', () => {
      assert.deepEqual(optionsFromSelect($("#test select"), $), {
        label: 'Label'
      });
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
    const options = {
      label: '<h1>Label</h1>'
    };

    beforeEach(() => {
      $('body').append('<div id=modal />');
      $modal = $('#modal');
      renderModal($modal, data, options);
    });

    afterEach(() => {
      $modal.remove();
    });

    it('renders the label', () => {
      assert.equal($modal.find('.select-modal-label h1').text(), 'Label');
    });

    it('creates a search input', () => {
      assert.lengthOf($modal.find('input[type=search]'), 1);
    });

    it('creates a modal-select-option for each option', () => {
      const $data = $modal.find('.select-modal-option') ;
      assert.lengthOf($data, 3);
    });

    it('sets modal-select-option-selected on the selection data', () => {
      const $data = $modal.find('.select-modal-option') ;
      assert.deepEqual($data
                       .map((_index, el) => $(el).hasClass('select-modal-option-selected'))
                       .get(),
                       [true, false, false]);
    });

    it('sets modal-select-option-disabled on the selection data', () => {
      const $data = $modal.find('.select-modal-option') ;
      assert.deepEqual($data
                       .map((_index, el) => $(el).hasClass('select-modal-option-disabled'))
                       .get(),
                       [false, true, false]);
    });

    it('sets text on the selection data', () => {
      const $data = $modal.find('.select-modal-option') ;
      assert.deepEqual($data
                       .map((_index, el) => $(el).text().trim())
                       .get(),
                       ['Selected', 'Disabled', 'Regular']);
    });

    it('sets value on the selection data', () => {
      const $data = $modal.find('.select-modal-option');
      // jQuery converts the values, but it's not a big deal #javascript -ps
      assert.deepEqual($data
                       .map((_index, el) => $(el).data('value'))
                       .get(),
                       [1, 0, 'reg']);
    });
  });

  describe('filterData', () => {
    it('returns the items which match the query string', () => {
      const result = filterData(data, 'reg');
      assert.deepEqual(result, [data[2]]);
    });

    it('keeps the items in order regardless of score', () => {
      var result = filterData(data, 'ed');
      assert.deepEqual(result, [data[0], data[1]]);

      result = filterData(data, 'l');
      assert.deepEqual(result, data);
    });
  });
});
