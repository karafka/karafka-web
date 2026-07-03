// Opens a <dialog class="modal"> via a [data-modal-open] trigger, without inline handlers
// (inline onclick attributes are blocked by the app's Content-Security-Policy)
class ModalOpener {
  constructor() {
    this.init();
  }

  init() {
    document.querySelectorAll('[data-modal-open]').forEach((trigger) => {
      trigger.addEventListener('click', () => {
        const dialog = document.getElementById(trigger.dataset.modalOpen);

        if (dialog) {
          dialog.showModal();
        }
      });
    });
  }
}
