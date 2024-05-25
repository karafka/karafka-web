// code for handling the search modal

class SearchModalManager {
  constructor() {
    this.init();
  }

  init() {
    var offsetValueInput = document.getElementById('offset-input');

    // do not manage anything when we are not in the search page
    if (!offsetValueInput) { return false }

    var offsetTimestampInput = document.getElementById('offset-timestamp-input');
    var offsetRadios = document.querySelectorAll('input[name="search[offset_type]"]');
    var noSearchCriteria = document.getElementById('no-search-criteria');
    var searchFormErrors = document.getElementById('search-form-errors');

    // When user selects appropriate offset lookup setting, make proper inputs editable or not
    offsetRadios.forEach(function(radio) {
      radio.addEventListener('change', function() {
        offsetValueInput.disabled = !document.getElementById('offset-value').checked;
        offsetValueInput.required = document.getElementById('offset-value').checked;
        offsetTimestampInput.disabled = !document.getElementById('offset-timestamp').checked;
        offsetTimestampInput.required = document.getElementById('offset-timestamp').checked
      });
    });

    offsetValueInput.disabled = !document.getElementById('offset-value').checked;
    offsetValueInput.required = document.getElementById('offset-value').checked;
    offsetTimestampInput.disabled = !document.getElementById('offset-timestamp').checked;
    offsetTimestampInput.required = document.getElementById('offset-timestamp').checked

    if (noSearchCriteria || searchFormErrors) {
      var searchModal = new bootstrap.Modal(document.getElementById('messages-search-modal'));

      document.getElementById('messages-search-modal').addEventListener('shown.bs.modal', function () {
        var firstTextInput = document.querySelector('#messages-search-modal input[type="text"]');
        if (firstTextInput) {
          firstTextInput.focus();
        }
      });

      searchModal.show();
    }
  }
}

class SearchMetadataVisibilityManager {
  constructor() {
    this.storageKey = 'karafkaSearchMetadataVisibility';
    this.metadataElement = document.getElementById('search-metadata-details');
    this.toggleButton = document.getElementById('toggle-search-metadata-btn');

    // do nothing if search metadata is not present
    if (!this.metadataElement) { return }

    this.init();
  }

  init() {
    this.restoreVisibility();
    this.metadataElement.addEventListener('shown.bs.collapse', () => this.saveVisibility(true));
    this.metadataElement.addEventListener('hidden.bs.collapse', () => this.saveVisibility(false));
  }

  readVisibility() {
    return localStorage.getItem(this.storageKey) === 'true';
  }

  saveVisibility(isVisible) {
    localStorage.setItem(this.storageKey, isVisible);
  }

  restoreVisibility() {
    const isVisible = this.readVisibility();

    if (isVisible) {
      this.metadataElement.classList.add('show');
    }
  }
}
