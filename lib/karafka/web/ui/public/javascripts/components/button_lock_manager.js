// Manages button locking functionality to prevent multiple submissions
class ButtonLockManager {
  constructor() {
    this.init();
  }

  init() {
    this.bindLockableButtons();
  }

  bindLockableButtons() {
    document.querySelectorAll('.btn-lockable').forEach((button) => {
      button.addEventListener('click', (event) => {
        const form = button.closest('form');

        const lockButton = () => {
          button.disabled = true;

          const hasText = Array.from(button.childNodes).some(node =>
            node.nodeType === Node.TEXT_NODE && node.textContent.trim().length > 0
          );

          if (hasText) {
            button.insertAdjacentText('beforeend', '...');
          }

          // Keep button disabled through the entire Turbo visit cycle
          document.addEventListener('turbo:before-visit', () => {
            button.disabled = true;
          }, { once: true });

          document.querySelectorAll('.modal').forEach((modal) => {
            modal.classList.add('modal-locked');
          });
        };

        if (form) {
          form.addEventListener('submit', lockButton, { once: true });

          // Add this to ensure button stays disabled after form submission
          form.addEventListener('turbo:submit-end', () => {
            button.disabled = true;
          }, { once: true });
        } else {
          lockButton();
        }
      });
    });
  }
}
