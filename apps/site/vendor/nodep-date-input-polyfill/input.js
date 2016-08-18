import Picker from './picker.js';
import locales from './locales.js';

export default class Input {
  constructor(input) {
    this.element = input;
    this.element.setAttribute(`type`, `text`);
    this.element.setAttribute(`data-has-picker`, ``);

    let langEl = this.element,
        lang = ``;

    while(langEl.parentNode) {
      lang = langEl.getAttribute(`lang`);

      if(lang) {
        break;
      }

      langEl = langEl.parentNode;
    }

    this.locale = lang || `en`;

    this.localeText = this.getLocaleText();

    Object.defineProperties(
      this.element,
      {
        'valueAsDate': {
          get: ()=> {
            if(!this.element.value) {
              return null;
            }

            const val = this.element.value.split(/\D/);
            return new Date(`${val[0]}-${`0${val[1]}`.slice(-2)}-${`0${val[2]}`.slice(-2)}`);
          },
          set: val=> {
            this.element.value = val.toISOString().slice(0,10);
          }
        },
        'valueAsNumber': {
          get: ()=> {
            if(!this.element.value) {
              return NaN;
            }

            return this.element.valueAsDate.getTime();
          },
          set: val=> {
            this.element.valueAsDate = new Date(val);
          }
        }
      }
    );

    // Open the picker when the input get focus,
    // also on various click events to capture it in all corner cases.
    const showPicker = ()=> {
      // make sure the Picker is created
      const picker = new Picker();
      picker.attachTo(this);
    };
    this.element.addEventListener(`showPicker`, showPicker);
    this.element.addEventListener(`focus`, showPicker);
    this.element.addEventListener(`mousedown`, showPicker);
    this.element.addEventListener(`mouseup`, showPicker);

    // Update the picker if the date changed manually in the input.
    this.element.addEventListener(`keyup`, e=> {
      const date = new Date();

      switch(e.keyCode) {
        case 27:
          Picker.instance.hide();
          break;
        case 38:
          if(this.element.valueAsDate) {
            date.setDate(this.element.valueAsDate.getDate() + 1);
            this.element.valueAsDate = date;
            Picker.instance.pingInput();
          }
          break;
        case 40:
          if(this.element.valueAsDate) {
            date.setDate(this.element.valueAsDate.getDate() - 1);
            this.element.valueAsDate = date;
            Picker.instance.pingInput();
          }
          break;
        default:
          break;
      }

      Picker.instance.sync();
    });
  }

  getLocaleText() {
    const locale = this.locale.toLowerCase();

    for(const localeSet in locales) {
      const localeList = localeSet.split(`_`);
      localeList.map(el=>el.toLowerCase());

      if(
        !!~localeList.indexOf(locale)
        || !!~localeList.indexOf(locale.substr(0,2))
      ) {
        return locales[localeSet];
      }
    }
  }

  static shouldRun() {
    return (this.inDebugMode() ||
            !this.supportsDateInput() ||
            !this.supportsTouch());
  }

  static inDebugMode() {
    return (
      document.currentScript
        && document.currentScript.hasAttribute(`data-nodep-date-input-polyfill-debug`)
    );
  }

  // Return false if the browser does not support input[type="date"].
  static supportsDateInput() {
    const input = document.createElement(`input`);
    input.setAttribute(`type`, `date`);

    const notADateValue = `not-a-date`;
    input.setAttribute(`value`, notADateValue);

    return input.value !== notADateValue;
  }

  // Return false if the browser does not support touch events
  static supportsTouch() {
    return !!(('ontouchstart' in window) || window.DocumentTouch && document instanceof DocumentTouch);
  }

  // Will add the Picker to all inputs in the page.
  static addPickerToDateInputs() {
    // Get and loop all the input[type="date"]s in the page that do not have `[data-has-picker]` yet.
    const dateInputs = document.querySelectorAll(`input[type="date"]:not([data-has-picker])`);
    const length = dateInputs.length;

    if(!length) {
      return false;
    }

    for(let i = 0; i < length; ++i) {
      new Input(dateInputs[i]);
    }
  }
}
