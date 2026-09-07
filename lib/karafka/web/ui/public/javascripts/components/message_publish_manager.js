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

    // Initial setup when the page loads (the checkbox may be pre-checked on a re-render)
    this.togglePayloadInputs(tombstone, payload, payloadFile);

    // A tombstone has a null payload, so the payload inputs are irrelevant when it is selected
    tombstone.addEventListener('change', () => {
      this.togglePayloadInputs(tombstone, payload, payloadFile);
    });
  }

  togglePayloadInputs(tombstone, payload, payloadFile) {
    const disabled = tombstone.checked;

    payload.disabled = disabled;
    payloadFile.disabled = disabled;
  }
}
