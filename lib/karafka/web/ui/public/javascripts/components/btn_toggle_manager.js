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

      // Add event listener to toggle visibility
      button.addEventListener('click', () => {
        const isVisible = !targetElement.classList.contains(this.visibilityClass);
        targetElement.classList.toggle(this.visibilityClass);
        button.classList.toggle('active', !isVisible);
        this.saveVisibility(targetId, !isVisible);
      });
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
