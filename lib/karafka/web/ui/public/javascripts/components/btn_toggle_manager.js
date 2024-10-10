/*
  This class allows buttons to toggle visibility classes on target elements.
  It also saves the visibility state in local storage so that it persists across page loads.

  By default, it will look for elements with class 'btn-toggle' and toggle the
  'hidden' class on their target elements (defined by the data attribute `data-toggle-target`)
  when clicked.
*/

class BtnToggleManager {
  constructor(btnClass = '.btn-toggle', visibilityClass = 'hidden') {
    this.btnClass = btnClass;
    this.visibilityClass = visibilityClass;
    this.init();
  }

  init() {
    document.querySelectorAll(this.btnClass).forEach(button => {
      const targetId = button.getAttribute('data-toggle-target');
      const targetElement = document.getElementById(targetId);

      if (!targetElement) return;

      // Establish initial state from local storage or based on visibility
      this.restoreVisibility(button, targetElement);

      // Check if the event listener has already been added
      if (!button._isClickListenerAdded) {
        // Define the event handler and store the flag to prevent duplicate listeners
        const handleClick = () => {
          const isVisible = !targetElement.classList.contains(this.visibilityClass);
          targetElement.classList.toggle(this.visibilityClass);
          button.classList.toggle('active', !isVisible);
          this.saveVisibility(targetId, !isVisible);
        };

        // Add the event listener
        button.addEventListener('click', handleClick);

        // Set flag to indicate the listener has been added
        button._isClickListenerAdded = true;
      }
    });
  }

  saveVisibility(targetId, isVisible) {
    localStorage.setItem(targetId + '_visibility', isVisible);
  }

  restoreVisibility(button, targetElement) {
    const storedVisibility = localStorage.getItem(targetElement.id + '_visibility');
    const isVisible = storedVisibility ? (storedVisibility === 'true') : !targetElement.classList.contains(this.visibilityClass);

    targetElement.classList.toggle(this.visibilityClass, !isVisible);
    button.classList.toggle('active', isVisible);
  }
}
