class ThemeManager {
  constructor() {
    this.themeSelectorButton = document.getElementById('theme-selector');
    this.themeSelectorLight = document.getElementById('theme-selector-light');
    this.themeSelectorDark = document.getElementById('theme-selector-dark');
    this.init();
  }

  init() {
    this.lightThemeLink = document.querySelector('.highlight-light');
    this.darkThemeLink = document.querySelector('.highlight-dark');

    if (!this.lightThemeLink || !this.darkThemeLink || !this.themeSelectorButton) {
      console.error('Theme CSS links or theme selector button not found');
      return;
    }

    this.restoreTheme();

    this.bindThemeSelectorButton();
  }

  bindThemeSelectorButton() {
    if (this.themeSelectorButton && !this.themeSelectorButton.dataset.bound) {
      this.themeSelectorButton.addEventListener('click', () => {
        this.toggleTheme();
      });
      this.themeSelectorButton.dataset.bound = 'true'; // Mark the button as bound
    }
  }

  setTheme(theme) {
    document.documentElement.setAttribute('data-theme', theme);
    if (theme === 'dark') {
      this.lightThemeLink.disabled = true;
      this.darkThemeLink.disabled = false;
      this.themeSelectorLight.classList.add('hidden');
      this.themeSelectorDark.classList.remove('hidden');
    } else {
      this.lightThemeLink.disabled = false;
      this.darkThemeLink.disabled = true;
      this.themeSelectorLight.classList.remove('hidden');
      this.themeSelectorDark.classList.add('hidden');
    }
    localStorage.setItem('theme', theme);
  }

  toggleTheme() {
    const currentTheme = document.documentElement.getAttribute('data-theme');
    const newTheme = currentTheme === 'dark' ? 'corporate' : 'dark';
    this.setTheme(newTheme);
  }

  restoreTheme() {
    const storedTheme = localStorage.getItem('theme');
    const theme = storedTheme ? storedTheme : (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'corporate');
    this.setTheme(theme);

    // Listen for system color scheme changes
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', e => {
      if (!localStorage.getItem('theme')) {
        this.setTheme(e.matches ? 'dark' : 'corporate');
      }
    });
  }
}
