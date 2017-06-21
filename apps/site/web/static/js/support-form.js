import email from 'email-validation';

export default function($ = window.jQuery) {
  document.addEventListener('turbolinks:load', () => {

    // TODO: create a way to run page-specific JS so that this hack isn't needed.
    if(!document.getElementById('support-form')) {
      return;
    }

    window.nextTick(() => {
      clearFallbacks($);

      setupPhotoPreviews($);
      setupTextArea();
      setupRequestResponse($);
      setupValidation($);

      handleSubmitClick($);
    });
  }, {passive: true});
};

// Set a few things since we know we don't need the no-JS fallbacks
export function clearFallbacks($) {
  const $photoLink = $('.upload-photo-link'),
        $photoInput = $('#photo');
  // Remove tabindex manipulation for screenreaders
  $photoLink.removeAttr('tabindex');
  // Forward clicks from the button to the input
  $photoLink.click(function (event) {
    event.preventDefault();
    $photoInput.click();
  });
};

// Adds the uploaded photo previews
function setupPhotoPreviews($) {
  const $container = $('.photo-preview-container');
  $('#photo').change(function () {
    if (this.files.length === 1) {
      handleUploadedPhoto($, this.files[0], $('.photo-preview'), $container);
    }
    else {
      $container.addClass('hidden-xs-up');
      $('.upload-photo-link').removeClass('hidden-xs-up');
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
      <p>
        ${file.name} &mdash; ${filesize(file.size)}
        <button class="btn btn-link clear-photo"><i class="fa fa-times-circle" aria-hidden="rue"></i><span class="sr-only">Clear Photo Upload</span></button>
      </p>
      <img height="100" class="m-r-1" alt="Uploaded image ${file.name} preview"></img>
    `),
          reader = new FileReader();
    reader.onloadend = () => { $imgPreview[2].src = reader.result; };
    reader.readAsDataURL(file);
    $previewDiv.append($imgPreview);
    $imgPreview.find('.clear-photo').click((event) => {
      event.preventDefault();
      $('#photo').val('').trigger('change');
    });
  }
  else {
    $previewDiv.append($(`
      <span>Error: ${file.name} <br /> The file you've selected is not valid for review. Please upload images only.</span>
    `));
  }
  $container.focus();
  $('.upload-photo-link').addClass('hidden-xs-up');
}

export function setupTextArea() {
  // Track the number of characters in the main <textarea>
  const commentsNode = document.getElementById("comments"),
        formTextNode = findSiblingWithClass(commentsNode, 'form-text');
  commentsNode.addEventListener('keyup', (ev) => {
    const commentLength = commentsNode.textLength;
    formTextNode.innerHTML = commentLength + '/3000 characters';
    if (commentLength > 0) {
      formTextNode.className += ' support-comment-success';
      formTextNode.parentNode.className += ' has-success';
    }
    else {
      removeClass(formTextNode, 'support-comment-success');
      removeClass(formTextNode.parentNode, 'has-success');
    }
  }, {passive: true});
};

function findSiblingWithClass(node, className) {
  node = node.nextElementSibling;
  while (node && node.className.indexOf(className) === -1) {
    node = node.nextElementSibling;
  }
  return node;
}
function removeClass(node, className) {
  node.className = node.className.replace(className, "");
}

export function setupRequestResponse($) {
  $('#request_response').click(function() {
    if($(this).is(":checked")) {
      showExpandedForm($);
    } else {
      hideExpandedForm($);
    }
  });
}

const validators = {
  comments: function ($) {
    return $('#comments').val().length !== 0;
  },
  name: function ($) {
    if(responseRequested($)) {
      return $('#name').val().length !== 0;
    }
    return true;
  },
  contacts: function ($) {
    if(responseRequested($)) {
      return email.valid($('#email').val()) || $('#phone').val() !== '';
    }
    return true;
  },
  privacy: function ($) {
    if(responseRequested($)) {
      return $('#privacy').prop('checked');
    }
    return true;
  }
};

function responseRequested($) {
  return $('#request_response')[0].checked;
}

function setupValidation($) {
  ['#privacy', '#comments', '.contacts', '#name'].forEach((selector) => {
    const $selector = $(selector);
    $selector.on('keyup blur input change', () => {
      if (validators[selector.slice(1)]($)) {
        displaySuccess($, selector);
      }
    });
  });
}

function displayError($, selector) {
  const rootSelector = selector.slice(1);
  $(`.support-${rootSelector}-error-container`).removeClass('hidden-xs-up');
  $(selector).parent().addClass('has-danger').removeClass('has-success');
}

function displaySuccess($, selector) {
  $(`.support-${selector.slice(1)}-error-container`).addClass('hidden-xs-up');
  $(selector).parent().removeClass('has-danger').addClass('has-success');
}

function validateForm($) {
  const privacy = '#privacy',
        comments = '#comments',
        contacts = '.contacts',
        name = '#name',
        errors = [];
  // Main textarea
  if(!validators.comments($)) {
    displayError($, comments);
    errors.push(comments);
  }
  else {
    displaySuccess($, comments);
  }
  // Name
  if(!validators.name($)) {
    displayError($, name);
    errors.push(name);
  }
  else {
    displaySuccess($, name);
  }
  // Phone and email
  if(!validators.contacts($)) {
    displayError($, contacts);
    errors.push(contacts);
  }
  else {
    displaySuccess($, contacts);
  }
  // Privacy checkbox
  if(!validators.privacy($)) {
    displayError($, privacy);
    errors.push(privacy);
  }
  else {
    displaySuccess($, privacy);
  }
  focusError($, errors);
  return errors.length === 0;
}

function focusError($, errors) {
  if (errors.length > 0) {
    $(`.support-${errors[0].slice(1)}-error-container`).focus();
  }
}

function deactivateSubmitButton($) {
  $('#support-submit').prop("disabled", true);
  $('.waiting').removeAttr("hidden");
  $('#support-submit').trigger('waiting:start');
}

function reactivateSubmitButton($) {
  $('#support-submit').prop("disabled", false);
  $('.waiting').attr("hidden", "hidden");
  $('#support-submit').trigger('waiting:end');
}

export function handleSubmitClick($) {
  $('#support-submit').click(function (event) {
    // Use an npm-installed library for testing
    const FormData = window.FormData ? window.FormData : require('form-data'),
          valid = validateForm($);
    event.preventDefault();
    if (valid) {
      deactivateSubmitButton($);
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
          $('.support-thank-you').removeClass('hidden-xs-up');
          $('.support-success').focus();
          $('.support-form-error').addClass('hidden-xs-up');
        },
        error: () => {
          $('.support-form-error').removeClass('hidden-xs-up').focus();
          reactivateSubmitButton($);
        }
      });
    }
  });
}

function showExpandedForm($) {
  $('.support-form-expanded').show();
}

function hideExpandedForm($) {
  $('.support-form-expanded').hide();
}
