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

    document.getElementById('show-search-modal').addEventListener('click', function () {
      var searchModal = document.getElementById('messages_search_modal');

      searchModal.showModal();

      var firstTextInput = document.querySelector('#messages_search_modal input[type="text"]');
      if (firstTextInput) {
        firstTextInput.focus();
      }
    });

    if (noSearchCriteria || searchFormErrors) {
      var searchModal = document.getElementById('messages_search_modal');

      searchModal.showModal();
      var firstTextInput = document.querySelector('#messages_search_modal input[type="text"]');
      if (firstTextInput) {
        firstTextInput.focus();
      }
    }
  }
}

class SearchMetadataVisibilityManager {
  constructor() {
    this.storageKey = 'karafkaSearchMetadataVisibility';
    this.metadataElement = document.getElementById('search-metadata-details');
    this.toggleButton = document.getElementById('toggle-search-metadata');

    // do nothing if search metadata is not present
    if (!this.metadataElement) { return }

    this.init();
  }

  init() {
    this.restoreVisibility();

    self = this;

    var toggleButton = document.getElementById('toggle-search-metadata');

    toggleButton.addEventListener('click', function () {
      var metadata = document.getElementById('search-metadata-details')
      metadata.classList.toggle('hidden');
      toggleButton.classList.toggle('active')

      self.saveVisibility(!metadata.classList.contains('hidden'))
    });
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
      document.getElementById('toggle-search-metadata').classList.add('active')
      document.getElementById('search-metadata-details').classList.remove('hidden');
    }
  }
}
