import Sifter from 'sifter';

export default function($ = window.jQuery) {
  convertSelects($);

  // create the modal when we click on the fake select
  $(document).on("click", "[data-select-modal]",
                 (ev) => openModal(ev, $));

  $(document).on('keyup', '.select-modal-search input',
                 (ev) => searchChanged(ev, $));

  $(document).on('submit', '.select-modal',
                 (ev) => searchSubmitted(ev, $));

  $(document).on("click", ".select-modal .select-modal-option",
                 (ev) => optionSelected(ev, $));

  $(document).on('shown.bs.modal', '.select-modal',
                 (ev) => modalShown(ev, $));

  $(document).on("hidden.bs.modal", ".select-modal",
                 (ev) => modalHidden(ev, $));
}

function openModal(ev, $) {
  ev.preventDefault();
  ev.stopPropagation();
  const $target = $(ev.currentTarget);
  const $parent = $target.data('select-modal-select');
  const selectData = dataFromSelect($parent, $);
  const options = optionsFromSelect($parent, $);
  const $modal = $newModal($parent.attr('name'), $);
  renderModal($modal, selectData, options);
  $modal
    .data('select-modal-button', $target)
    .data('select-modal-select', $parent)
    .modal({
      keyboard: true,
      show: true
    });
  return false;
}

function searchChanged(ev, $) {
  const $target = $(ev.currentTarget);
  const $modal = $target.parents('.select-modal');
  const data = $modal.data('select-modal-data');
  const sifter = $modal.data('select-modal-sifter');

  // filter the data and re-render those options
  const newData = filterData(data, $target.val(), sifter);
  $modal.find('.select-modal-options').html(
    newData.map(renderOption).join('')
  );
}

function searchSubmitted(ev, $) {
  // find the first non-disabled button and click it
  ev.preventDefault();
  ev.stopPropagation();
  $(ev.currentTarget).find('.select-modal-option:first-child:not(.select-modal-option-disabled)').click();
}

function optionSelected(ev, $) {
  // update the original select and the fake select when we click on an option
  ev.preventDefault();
  ev.stopPropagation();

  const $target = $(ev.currentTarget),
  $parent = $target.parents(".select-modal"),
  value = $target.data('value');

  $parent.data('select-modal-button').text($target.text());
  $parent.data('select-modal-select').val(value).change();
  $parent.modal('hide');
  return false;
}

function modalShown(ev, $) {
  // focus search when the modal is open
  $(ev.currentTarget).find('.select-modal-search input').focus();
}

function modalHidden(ev, $) {
  // remove the generated modal once it's closed
  $(ev.currentTarget).remove();
}

// public so that it can be re-run separately from the global event handlers
export function convertSelects($) {
  $("select[data-select-modal]").each((_index, el) => {
    const $el = $(el),
          $newDiv = $("<button data-select-modal/>")
      .addClass(el.className)
      .text(el.options[el.selectedIndex].text)
      .data('select-modal-select', $el);
    $el.hide()
      .removeAttr('data-select-modal')
      .after($newDiv);
  });
}

export function dataFromSelect($el, $) {
  return $el
    .children('option')
    .map(dataFromOption($))
    .get()
    .filter(({value: value}) => value !== "");
}

export function optionsFromSelect($el, $) {
  return {
    label: $(`label[for=${$el.attr('id')}]`).html()
  };
}

export function $newModal(id, $) {
  const modalId = id + 'Modal';
  const $existing = $('#' + modalId);
  if ($existing.length > 0) {
    return $existing;
  }

  const $div = $(`<div
class='modal select-modal'
id='${modalId}'
tabindex="-1"
role="dialog"
aria-hidden="true"
data-original-id='#${id}'>
</div>`);
  $('body').append($div);
  return $div;
}

export function renderModal($modal, data, options) {
  $modal.html(`
<div class='modal-dialog modal-sm modal-transparent role='document'>
  <div class="modal-content">
    <div class="modal-header">
      <button type="button" class="close btn btn-link pull-right" data-dismiss="modal" aria-label="Close">
        <i class="fa fa-close" aria-hidden="true"/> Close
        </button>
      </div>
    </div>
    <div class="modal-body">
      <form class="select-modal-search">${renderSearch(data, options)}</form>
      <div class="select-modal-options list-group list-group-flush">${data.map(renderOption).join('')}</div>
    </div>
  </div>
</div>
`)
    .data('select-modal-data', data)
    .data('select-modal-sifter', new Sifter(data));
}


function dataFromOption($) {
  return (_index, option) => {
    const $option = $(option);
    const data = {
      name: $option.text(),
      value: $option.val()
    };
    if ($option.attr('selected')) {
      data.selected = true;
    }
    if ($option.attr('disabled')) {
      data.disabled = true;
    }
    return data;
  };
}

function renderSearch(data, options) {
  return `
<label for="select-modal-search" class="select-modal-label">${options.label}</label>
<input id="select-modal-search" class="form-control" type=search placeholder='Ex ${data[0].name}'/>
`;
}

function renderOption(option) {
  const className = [
    'select-modal-option',
    'list-group-item',
    option.selected ? 'selected' : '',
    option.disabled ? 'disabled' : ''
  ].join(' ');
  return `
<button class='${className}' data-value='${option.value}' ${option.disabled ? 'disabled' : ''}>
  <div class='select-modal-option-name'>${option.name}</div>
</button>
`;
}

export function filterData(data, query, sifter) {
  if (typeof sifter === 'undefined') {
    sifter = new Sifter(data);
  }
  const search = sifter.search(query, {
    fields: ['name'],
  });

  // sort the items by ID
  search.items.sort((first, second) => first.id - second.id);

  return search.items.map(({id: id}) => data[id]);
}
