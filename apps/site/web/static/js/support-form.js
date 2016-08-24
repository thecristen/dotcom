import email from 'email-validation';

export default function($ = window.jQuery) {
  $(document).on('turbolinks:load', () => {

    // TODO: create a way to run page-specific JS so that this hack isn't needed.
    if($('#support-form').length === 0) {
      return;
    }

    clearFallbacks($);

    setupPhotoPreviews($);
    setupTextArea($);
    setupValidation($);
    setupClearPhotoButton($);

    handleSubmitClick($);
  });
};

// Set a few things since we know we don't need the no-JS fallbacks
export function clearFallbacks($) {
  const $photoLabel = $('label[for=photo]'),
        $photoButton = $photoLabel.parent('button'),
        $photoInput = $('#photo');
  // Remove tabindex manipulation for screenreaders
  $photoLabel.removeAttr('tabindex');
  $photoButton.removeAttr('tabindex');
  // Forward clicks from the button to the input
  $photoButton.click(function (event) {
    event.preventDefault();
    $photoInput.click();
  });
};

export function setupClearPhotoButton($) {
  $('.clear-photo').removeClass('hidden-xs-up');
  $('.clear-photo').click((event) => {
    event.preventDefault();
    $('#photo').val('').trigger('change');
  });
}

// Adds the uploaded photo previews
function setupPhotoPreviews($) {
  const $container = $('.photo-preview-container');
  $('#photo').change(function () {
    if (this.files.length === 1) {
      handleUploadedPhoto($, this.files[0], $('.photo-preview'), $container);
    }
    else {
      $container.addClass('hidden-xs-up');
      $('.upload-photo-button').removeClass('hidden-xs-up');
    }
  });
};

// Split out for testing, since the content of a file input can't be
// changed programmatically for security reasons
export function handleUploadedPhoto($, file, $previewDiv, $container) {
  const filesize = require('filesize');
  $previewDiv.html('');
  $container.removeClass('hidden-xs-up');
  if (/image\//.test(file.type)) {
    const $imgPreview = $(`
      <img width="100" height="100" class="m-r-1" alt="Uploaded image ${file.name} preview"></img><span>${file.name} &mdash; ${filesize(file.size)}</span>
    `),
          reader = new FileReader();
    reader.onloadend = () => { $imgPreview[0].src = reader.result; };
    reader.readAsDataURL(file);
    $previewDiv.append($imgPreview);
    $previewDiv.append(`
      <div class="col-xs-12 support-success">
        <i class="fa fa-check-circle" aria-hidden="true"></i>
        Photo successfully uploaded.
      </div>`
    );
  }
  else {
    $previewDiv.append($(`
      <span>Error: ${file.name} <br /> The file you've selected is not valid for review. Please upload images only.</span>
    `));
  }
  showExpandedForm($);
  $container.focus();
  $('.upload-photo-button').addClass('hidden-xs-up');
}

export function setupTextArea($) {
  // Track the number of characters in the main <textarea>
  $('#comments').keyup(function () {
    const $textarea = $(this),
          $label = $textarea.siblings('.form-text');
    $label.text($textarea.val().length + '/3000 characters');
  }).one('focus', function () { // Once the user has clicked into the form, expand the whole thing
    showExpandedForm($);
  });
};

const validators = {
  'comments': function ($) {
    return $('#comments').val().length !== 0;
  },
  'contacts': function ($) {
    return email.valid($('#email').val()) || $('#phone').val() !== '';
  },
  'privacy': function ($) {
    return $('#privacy').prop('checked');
  }
}

function setupValidation($) {
  const privacy = '#privacy',
        comments = '#comments',
        contacts = '.contacts';
  ['#privacy', '#comments', '.contacts'].forEach((selector) => {
    const $selector = $(selector);
    $selector.on('keyup blur input change', () => {
      if ($selector.parent().hasClass('has-danger') && validators[selector.slice(1)]($)) {
        displaySuccess($, selector);
      }
    });
  });
}

function displayError($, selector, errorMessage) {
  const rootSelector = selector.slice(1);
  $(`.support-${rootSelector}-error-container`).removeClass('hidden-xs-up');
  $(selector).parent().addClass('has-danger').removeClass('has-success');
}

function displaySuccess($, selector) {
  $(`.support-${selector.slice(1)}-error-container`).addClass('hidden-xs-up');
  $(selector).parent().removeClass('has-danger').addClass('has-success');
}

function validateForm($) {
  const $privacy = $('#privacy'),
        $textarea = $('#comments'),
        $contacts = $('.contacts');
  var valid = true;
  // Main textarea
  if(!validators.comments($)) {
    displayError($, '#comments');
    valid = false;
  }
  else {
    displaySuccess($, '#comments');
  }
  // Phone and email
  if(!validators.contacts($)) {
    displayError($, '.contacts');
    valid = false;
  }
  else {
    displaySuccess($, '.contacts');
  }
  // Privacy checkbox
  if(!validators.privacy($)) {
    displayError($, '#privacy');
    valid = false;
  }
  else {
    displaySuccess($, '#privacy');
  }
  return valid;
}

export function handleSubmitClick($) {
  $('#support-submit').click(function (event) {
    // Use an npm-installed library for testing
    const FormData = window.FormData ? window.FormData : require('form-data'),
          valid = validateForm($);
    event.preventDefault();
    showExpandedForm($);
    if (valid) {
      const formData = new FormData(),
            photo = $('#photo')[0].files;
      $('#support-form').serializeArray().forEach(({name: name, value: value}) => {
        formData.append(name, value);
      });
      if (photo.length === 1) {
        formData.append('photo', photo[0]);
      }
      $.ajax({
        url: $('#support-form').attr('action'),
        method: "POST",
        processData: false,
        data: formData,
        contentType: false,
        success: () => {
          $('#support-form').parent().remove();
          $('.support-thank-you').removeClass('hidden-xs-up').focus();
          $('.support-form-error').addClass('hidden-xs-up');
        },
        error: () => {
          $('.support-form-error').removeClass('hidden-xs-up').focus();
        }
      });
    }
  });
}

function showExpandedForm($) {
  $('.support-form-expanded').show();
}
