import { expect } from 'chai';
import jsdom from 'mocha-jsdom';
import sinon from 'sinon';
import * as TransitNearMe from '../../assets/js/transit-near-me';
import { TransitNearMeSearch } from '../../assets/js/transit-near-me/search';

describe('TransitNearMe', () => {
  jsdom();

  beforeEach(() => {
    window.navigator.geolocation = {
      getCurrentPosition: sinon.spy()
    };

    window.decodeURIComponent = (string) => {
      return string.replace(/\%20/g, ' ').replace(/\%26/g, '&');
    };

    window.autocomplete = jsdom.rerequire("autocomplete.js");
    window.jQuery = jsdom.rerequire("jquery");

    const {
      container,
      input,
      resetButton,
      goBtn
    } = TransitNearMeSearch.SELECTORS;

    document.body.innerHTML = `
      <div id='address-search-message'></div>
      <div id="${container}">
        <input id="${input}"></input>
        <div id="${resetButton}"></div>
        <button id ="${goBtn}"></button>
      </div>
    `;
  });

  describe('onLoad', () => {
    it('requests the user\'s location', () => {
      TransitNearMe.onLoad({
        data: {
          url: '/transit-near-me'
        }
      });
      expect(window.navigator.geolocation.getCurrentPosition.called).to.be.true;
    });

    it('does not request location if query includes "address"', () => {
      TransitNearMe.onLoad({
        data: {
          url: '/transit-near-me?location[address]=42,-71'
        }
      });
      expect(window.navigator.geolocation.getCurrentPosition.called).to.be.false;
    });
  });

  describe('onLocation', () => {
    it('sets lat/lng params and refreshes the page', () => {
      window.Turbolinks = {visit: sinon.spy()}
      TransitNearMe.onLocation({
        coords: {
          latitude: 42,
          longitude: -71
        }
      });
      expect(window.Turbolinks.visit.called).to.be.true;
      expect(window.Turbolinks.visit.args[0][0]).to.equal("about:?latitude=42&longitude=-71");
    });
  });
});
