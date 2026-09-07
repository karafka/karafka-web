// code for handling the message publish form interactions
class MessagePublishManager {
  constructor() {
    this.init();
  }

  init() {
    // Check if the message publish form exists on the current page
    const form = document.getElementById('message-publish-form');
    if (!form) { return false; }

    // Get references to the relevant elements
    const tombstone = form.querySelector('input[type="checkbox"][name="tombstone"]');
    const payload = document.getElementById('payload');
    const payloadFile = document.getElementById('payload_file');

    if (!tombstone || !payload || !payloadFile) { return false; }

    const update = () => this.updateState(tombstone, payload, payloadFile);

    // Initial setup when the page loads (the tombstone checkbox may be pre-checked on a re-render)
    update();

    // A tombstone has a null payload, and an uploaded file takes precedence over the textarea, so
    // in both cases the affected payload inputs become irrelevant
    tombstone.addEventListener('change', update);
    payloadFile.addEventListener('change', update);
  }

  updateState(tombstone, payload, payloadFile) {
    const tombstoneChecked = tombstone.checked;
    const fileSelected = payloadFile.files && payloadFile.files.length > 0;

    // Tombstone disables both payload inputs; a selected file disables only the textarea
    payloadFile.disabled = tombstoneChecked;
    payload.disabled = tombstoneChecked || fileSelected;
  }
}
