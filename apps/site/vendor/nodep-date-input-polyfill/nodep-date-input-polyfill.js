import './nodep-date-input-polyfill.scss';
import Picker from './picker.js';
import Input from './input.js';

// Check if type="date" is supported.
if(Input.shouldRun()) {
  const init = ()=> {
    // Run the above code on any <input type="date"> in the document, also on dynamically created ones.
    Input.addPickerToDateInputs();

    // This is also on mousedown event so it will capture new inputs that might
    // be added to the DOM dynamically.
    document.addEventListener(`mousedown`, ()=> {
      Input.addPickerToDateInputs();
    });
  };

  let DOMContentLoaded = false;

  document.addEventListener(`DOMContentLoaded`, ()=> {
    DOMContentLoaded = true;

    init();
  });

  window.addEventListener(`load`, ()=> {
    if(!DOMContentLoaded) {
      init();
    }
  });
}
