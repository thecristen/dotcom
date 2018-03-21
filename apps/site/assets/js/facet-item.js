import hogan from 'hogan.js';

export class FacetItem {
  get selectors() {
    return {
      textDisplay: `facet-text-${this._id}`,
      checkbox: `checkbox-item-${this._id}`,
      counter: `facet-item-counter-${this._id}`,
      childrenDiv: `facet-children-${this._id}`,
      checkboxLabel: `facet-label-${this._id}`,
      icon: `facet-icon-${this._id}`,
      expansionContainer: `expansion-container-${this._id}`,
      checkboxControlContainer: `checkbox-container-${this._id}`,
    }
  }

  get templates() {
    return {
      facetItem: hogan.compile(`
        <div class="{{class}}">
          <div id="${this.selectors.expansionContainer}" class="c-facets__flex-container--normal">
            <div class="c-facets__icon">
              {{#iconClass}}
                {{{iconClass}}}
              {{/iconClass}}
            </div>
            <div id="${this.selectors.textDisplay}" class="c-facets__title">{{text}}</div>
          </div>
          <div id="${this.selectors.checkboxControlContainer}" class="c-facets__flex-container--wide">
            <div class="c-facets__facet-item" id="${this.selectors.counter}"></div>
            <div class="c-facets__facet-checkbox">
              <input id="${this.selectors.checkbox}" class="c-facets__checkbox--input" type="checkbox">
              <label id="${this.selectors.checkboxLabel}" for="${this.selectors.checkbox}"></label>
            </div>
          </div>
        </div>
        <div id="${this.selectors.childrenDiv}"></div>
      `),
    }
  }

  constructor(data, parent) {
    this._id = data.id;
    this._name = data.name;
    this._parent = parent;
    this._iconHTML = data.icon;
    this._facets = data.facets || [];
    this._prefix = data.prefix;
    this._count = 0;
    this._facets = this._facets.map(facet => { return `${this._prefix}:${facet}`; });
    if (this._facets.length > 0) {
      this.addToMap(this._facets, this);
    }

    this._checkbox = null;
    this._counter = null;
    this._textDisplay = null;
    this._childrenDiv = null;
    this._icon = null;
    this._children = [];
    if (data.items) {
      this._iconHTML = this._triangleRightIcon(this._id);
      this._children = data.items.map(item => {
        if (!item.prefix) {
          item.prefix = this._prefix;
        }
        return new FacetItem(item, this);
      });
    }
  }

  addToMap(facets, facetItem) {
    this._parent.addToMap(facets, facetItem);
  }

  getActiveFacets() {
    const children = [].concat.apply([], this._children.map(child => child.getActiveFacets()));
    if (this.isChecked()) {
      return this._facets.concat(children);
    }
    return children;
  }

  isChecked() {
    return this._checkbox.checked;
  }

  _triangleRightIcon(id) {
    return  `<span id="${this.selectors.icon}" class="c-facets__triangle--right"></span>`;
  }

  toggleExpansion() {
    if (this._childrenDiv.style.display == "none") {
      this._childrenDiv.style.display = "block";
      this._icon.classList.remove("c-facets__triangle--right");
      this._icon.classList.add("c-facets__triangle--down");
    } else {
      this._childrenDiv.style.display = "none";
      this._icon.classList.remove("c-facets__triangle--down");
      this._icon.classList.add("c-facets__triangle--right");
    }
  }

  gatherElements() {
    this._textDisplay = document.getElementById(this.selectors.textDisplay);
    this._checkbox = document.getElementById(this.selectors.checkbox);
    this._counter = document.getElementById(this.selectors.counter);
    this._childrenDiv = document.getElementById(this.selectors.childrenDiv);
    this._checkboxLabel = document.getElementById(this.selectors.checkboxLabel);
    this._icon = document.getElementById(this.selectors.icon);
    this._checkboxLabel.classList.add("c-facets__checkbox--unchecked");
    this._checkbox.checked = false;
    this.setupListeners();
  }

  check() {
    this._checkbox.checked = true;
    this._checkboxLabel.classList.remove("c-facets__checkbox--unchecked");
    this._checkboxLabel.classList.add("c-facets__checkbox--checked");
    this._children.forEach(child => {
      child.check();
    });
  }

  uncheckUI() {
    this._checkbox.checked = false;
    this._checkboxLabel.classList.remove("c-facets__checkbox--checked");
    this._checkboxLabel.classList.add("c-facets__checkbox--unchecked");
  }

  uncheck() {
    this.uncheckUI();
    this._children.forEach(child => {
      child.uncheck();
    });
  }

  isChecked() {
    return this._checkbox.checked;
  }

  toggleCheck() {
    if (this._checkbox.checked) {
      this.uncheck();
    } else {
      this.check();
    }
    this._parent.update();
  }

  update() {
    if (this.allChildrenStatus(true)) {
      this.check();
    } else {
      this.uncheckUI();
    }
    this._parent.update();
  }

  allChildrenStatus(status) {
    if (this._children.length == 0) {
      return this._checkbox.checked == status;
    }
    return this._children.every(child => {
      return child.allChildrenStatus(status);
    });
  }

  updateCount(count) {
    if (count === undefined) {
      count = 0;
    }
    this._count = count;
    this._counter.innerHTML = count;
    this._parent.updateCount(this._parent.sumChildren());
  }

  sumChildren(count) {
    if (this._children.length == 0) {
      return this._count;
    }
    return this._children.map(child => {
      return child.sumChildren();
    }).reduce(function(total, num) {
      return total + num;
    }, 0);
  }

  render(container, itemStyle) {
    const div = document.createElement("div");
    div.id = `facet-item-${this._id}`;
    div.innerHTML = this.templates.facetItem.render({
      class: itemStyle,
      text: this._name,
      iconClass: this._iconHTML
    });
    container.appendChild(div);
    this.gatherElements();
    this._childrenDiv.style.display = "none";
    this._childrenDiv = document.getElementById(`facet-children-${this._id}`);
    this._children.forEach(child => {
      child.render(this._childrenDiv, "c-facets__search-facet-child");
    })
  }

  setupListeners() {
    const expansionContainer = document.getElementById(this.selectors.expansionContainer);
    const checkboxControlContainer = document.getElementById(this.selectors.checkboxControlContainer);
    checkboxControlContainer.addEventListener("click", () => {
      this.toggleCheck();
    });
    expansionContainer.addEventListener("click", () => {
      if (this._children.length > 0) {
        this.toggleExpansion();
      } else {
        this.toggleCheck();
      }
    });
  }

  setupAllListeners() {
    this.setupListeners();
    this._children.forEach(function(child) {
      child.setupAllListeners();
    });
  }
}
