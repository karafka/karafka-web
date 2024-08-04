class BtnToggleManager {
  constructor() {
    this.init();
  }

  init() {
    document.querySelectorAll('.btn-toggle').forEach(button => {
      const targetId = button.getAttribute('data-toggle-target');
      const targetElement = document.getElementById(targetId);

      if (!targetElement) return;

      // Establish initial state from local storage or based on visibility
      this.restoreVisibility(button, targetElement);

      // Add event listener to toggle visibility
      button.addEventListener('click', () => {
        const isVisible = !targetElement.classList.contains('hidden');
        targetElement.classList.toggle('hidden');
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
    const isVisible = storedVisibility ? (storedVisibility === 'true') : !targetElement.classList.contains('hidden');

    targetElement.classList.toggle('hidden', !isVisible);
    button.classList.toggle('active', isVisible);
  }
}
