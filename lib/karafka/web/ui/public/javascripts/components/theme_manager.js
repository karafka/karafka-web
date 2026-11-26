class ThemeManager {
  // Theme the user picked, if any
  static storedTheme() {
    try {
      return localStorage.getItem('theme');
    } catch (_) {
      // Storage may be unavailable (privacy settings), then we follow the system color scheme
      return null;
    }
  }

  // Theme picked by the user or, when none, the one matching the system color scheme
  static preferredTheme() {
    const storedTheme = ThemeManager.storedTheme();

    if (storedTheme) { return storedTheme }

    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'corporate';
  }

  // Sets the theme on <html> before the page is painted, so it never renders with the default
  // theme first. Code highlighting follows it through the theme scoped highlight.js stylesheet.
  static applyPreferredTheme() {
    document.documentElement.setAttribute('data-theme', ThemeManager.preferredTheme());
  }

  constructor() {
    this.themeSelectorButton = document.getElementById('theme-selector');
    this.themeSelectorLight = document.getElementById('theme-selector-light');
    this.themeSelectorDark = document.getElementById('theme-selector-dark');
    this.init();
  }

  init() {
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

    // Pages without the navigation (errors) have no theme selector
    if (this.themeSelectorLight && this.themeSelectorDark) {
      this.themeSelectorLight.classList.toggle('hidden', theme === 'dark');
      this.themeSelectorDark.classList.toggle('hidden', theme !== 'dark');
    }
  }

  toggleTheme() {
    const currentTheme = document.documentElement.getAttribute('data-theme');
    const newTheme = currentTheme === 'dark' ? 'corporate' : 'dark';
    this.setTheme(newTheme);
    this.storeTheme(newTheme);
  }

  // Only a theme the user picks is stored, so without one the UI keeps following the system
  storeTheme(theme) {
    try {
      localStorage.setItem('theme', theme);
    } catch (_) {
      // Without storage the theme still applies, it is just not remembered
    }
  }

  restoreTheme() {
    this.setTheme(ThemeManager.preferredTheme());

    // A new manager is created on each Turbo visit, so the system color scheme listener is bound
    // only once and uses the latest manager. Binding it per manager would keep all of them and
    // the elements of every visited page they reference alive.
    ThemeManager.current = this;

    if (ThemeManager.systemSchemeListenerBound) { return }

    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', e => {
      if (!ThemeManager.storedTheme()) {
        ThemeManager.current.setTheme(e.matches ? 'dark' : 'corporate');
      }
    });

    ThemeManager.systemSchemeListenerBound = true;
  }
}

// This script loads synchronously in <head>, so this runs before the body is rendered
ThemeManager.applyPreferredTheme();
