// Manages action confirmations for links and forms
class ActionConfirmationManager {
  constructor(confirmationMessage = 'Are you sure?') {
    this.confirmationMessage = confirmationMessage;
    this.init();
  }

  init() {
    this.bindActionsConfirmations();
  }

  bindActionsConfirmations() {
    const elements = document.getElementsByClassName('confirm-action');

    for (let i = 0; i < elements.length; i++) {
      let element = elements[i];
      let action = 'click';

      if (element.nodeName === 'FORM') {
        action = 'submit';
      }

      element.addEventListener(action, (event) => {
        if (!window.confirm(this.confirmationMessage)) {
          event.preventDefault();
        }
      });
    }
  }
}
