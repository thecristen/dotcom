import { assert } from 'chai';
import jsdom from 'mocha-jsdom';
import { File } from 'file-api';
import 'custom-event-autopolyfill';
import sinon from 'sinon';
import { clearFallbacks,
         handleUploadedPhoto,
         setupTextArea,
         handleSubmitClick } from '../../web/static/js/support-form';

describe('support form', () => {
  let $;
  jsdom();

  beforeEach(() => {
    $ = jsdom.rerequire('jquery');
    $('body').append('<div id="test"></div>');
  });

  afterEach(() => {
    $('#test').remove();
  });

  describe('clearFallbacks', () => {
    beforeEach(() => {
      $('#test').html(`
        <button class="upload-photo-button" tabindex="-1"><label for="photo" tabindex="0"></label></button>
        <input type="file" id="photo" name="photo" />
        <div class="support-form-expanded"></div>
      `);
      clearFallbacks($);
    });

    it('resets tabindex attributes in the photo section to their defaults', () => {
      assert.equal($('.upload-photo-button').prop('tabindex'), 0);
      assert.equal($('label[for=photo]').prop('tabindex'), -1);
    });

    it('forwards a click on the button to the input', (done) => {
      $('#photo').click(() => done());
      $('.upload-photo-button').click();
    });
  });

  describe('handleUploadedPhoto', () => {
    beforeEach(() => {
      $('#test').html(`
     <div class="photo-preview-container hidden-xs-up" tabindex="-1">
       <strong></strong>
       <div class="photo-preview"></div>
     </div>
     <input type="file" id="photo" name="photo" />
     <button class="upload-photo-button hidden-xs-up"></button>
     `);
      handleUploadedPhoto(
        $,
        new File({name: 'test-file', buffer: new Buffer("this is a 24 byte string"), type: "image/png"}),
        $('.photo-preview'),
        $('.photo-preview-container')
      );
    });

    it('displays a preview of uploaded files', () => {
      const $preview = $('.photo-preview')
      assert.equal($preview.length, 1);
      assert.include($preview.html(), 'test-file');
      assert.include($preview.html(), '24 B');
    });

    it('hides the upload button', () => {
      assert.isTrue($('.upload-photo-button').hasClass('hidden-xs-up'));
    });

    it('adds a clear button which clears the photo', () => {
      $('.clear-photo').click();
      assert.equal($('#photo').val(), '');
    });
  });

  describe('setupTextArea', () => {
    function enterComment(comment) {
      const $textarea = $('#comments');
      $textarea.val(comment);
      $textarea.blur();
    };

    beforeEach(() => {
      $('#test').html(`
        <div class="form-group">
          <textarea id="comments"></textarea>
          <small class="form-text"></small>
        </div>
        <button class="edit-comments"></button>
      `);
      setupTextArea();
    });

    it('tracks the number of characters entered', () => {
      const $textarea = $('#comments');
      $textarea.val('12345');
      const event = document.createEvent("HTMLEvents");
      event.initEvent("keyup", true, true);
      $textarea[0].dispatchEvent(event);
      assert.equal($('.form-text').text(), '5/3000 characters');
    });
  });

  describe('handleSubmitClick', () => {
    var spy;

    beforeEach(() => {
      spy = sinon.spy($, 'ajax');
      $('#test').html(`
        <div class="form-container">
          <form id="support-form" action="/customer-support">
            <textarea id="comments"></textarea>
            <div class="support-comments-error-container hidden-xs-up" tabindex="-1"><div class="support-comments-error"></div></div>
            <input id="photo" type="file" />
            <input id="request_response" type="checkbox" />
            <input id="name" />
            <input id="phone" />
            <input id="email" />
            <div class="support-name-error-container hidden-xs-up" tabindex="-1"><div class="support-name-error"></div></div>
            <div class="support-contacts-error-container hidden-xs-up" tabindex="-1"><div class="support-contacts-error"></div></div>
            <input id="privacy" type="checkbox" />
            <div class="support-privacy-error-container hidden-xs-up" tabindex="-1"><div class="support-privacy-error"></div></div>
            <div class="support-form-expanded" style="display: none"></div>
            <button id="support-submit"></button>
          </form>
        </div>
        <div class="support-thank-you hidden-xs-up"></div>
      `);
      handleSubmitClick($);
    });

    afterEach(() => {
      $.ajax.restore();
    });

    it('expands the form if it is hidden', () => {
      $('#support-submit').click();
      assert.isFalse($('.support-form-expanded').hasClass('hidden-xs-up'));
      assert.isTrue($('.support-thank-you').hasClass('hidden-xs-up'));
    });

    it('requires text in the main textarea', () => {
      $('#support-submit').click();
      assert.isFalse($('.support-comments-error-container').hasClass('hidden-xs-up'));
    });

    it('requires the privacy box to be checked if the customer wants a response', () => {
      $('#request_response').click();
      $('#support-submit').click();
      assert.isFalse($('.support-privacy-error-container').hasClass('hidden-xs-up'));
    });

    it('does not require the privacy box to be checked if the customer does not want a response', () => {
      $('#support-submit').click();
      assert.isTrue($('.support-privacy-error-container').hasClass('hidden-xs-up'));
    });

    it('requires a name if the customer wants a response', () => {
      $('#request_response').click();
      $('#support-submit').click();
      assert.isFalse($('.support-name-error-container').hasClass('hidden-xs-up'));
    });

    it('requires either a phone number or an email when the customer wants a response', () => {
      $('#request_response').click();
      $('#support-submit').click();
      assert.isFalse($('.support-contacts-error-container').hasClass('hidden-xs-up'));
    });

    it('does not require a phone number or an email when the customer does not want a response', () => {
      $('#support-submit').click();
      assert.isTrue($('.support-contacts-error-container').hasClass('hidden-xs-up'));
    });

    it('requires a valid email', () => {
      $('#email').val('not an email');
      $('#request_response').click();
      $('#support-submit').click();
      assert.isFalse($('.support-contacts-error-container').hasClass('hidden-xs-up'));
      $('#email').val('test@email.com');
      $('#support-submit').click();
      assert.isTrue($('.support-contacts-error-container').hasClass('hidden-xs-up'));
    });

    it('focuses to the highest error message on the page', () => {
      $('#request_response').click();
      $('#support-submit').click();
      assert.equal(document.activeElement, $('.support-comments-error-container')[0]);
      $('#comments').val('A comment');
      $('#support-submit').click();
      assert.equal(document.activeElement, $('.support-name-error-container')[0]);
      $('#name').val('tom brady');
      $('#support-submit').click();
      assert.equal(document.activeElement, $('.support-contacts-error-container')[0]);
      $('#email').val('test@email.com');
      $('#support-submit').click();
      assert.equal(document.activeElement, $('.support-privacy-error-container')[0]);
    });

    it('hides the form and shows a message on success', () => {
      $('#email').val('test@email.com');
      $('#name').val('tom brady');
      $('#comments').val('A comment');
      $('#privacy').prop('checked', 'checked');
      $('#support-submit').click();
      assert.equal(spy.callCount, 1);
      const ajaxArgs = spy.firstCall.args[0];
      assert.propertyVal(ajaxArgs, 'method', 'POST');
      assert.propertyVal(ajaxArgs, 'url', '/customer-support');
      ajaxArgs.success();
      assert.equal($('.form-container').length, 0);
      assert.isFalse($('.support-thank-you').hasClass('hidden-xs-up'));
    });

    it('shows a message on error', () => {
      $('#email').val('test@email.com');
      $('#name').val('tom brady');
      $('#comments').val('A comment');
      $('#privacy').prop('checked', 'checked');
      $('#support-submit').click();
      spy.firstCall.args[0].error();
      assert.isFalse($('.support-form-error').hasClass('hidden-xs-up'));
    });

    it('shows comment validation when other fields provided', () => {
      $('#email').val('test@email.com');
      $('#name').val('tom brady');
      $('#privacy').prop('checked', 'checked');
      $('#support-submit').click();
      assert.isFalse($('.support-comments-error-container').hasClass('hidden-xs-up'));
    });
  });
});
