// Tracks and updates page titles based on breadcrumbs
class PageTitleTracker {
  constructor() {
    this.init();
  }

  init() {
    this.refreshTitle();
  }

  refreshTitle() {
    const breadcrumbs = document.querySelectorAll('.breadcrumbs a');
    let breadcrumbTexts = Array.from(breadcrumbs).slice(1).map(crumb => crumb.textContent.trim());

    if (breadcrumbTexts.length > 0) {
      document.title = breadcrumbTexts.join(' > ') + ' - Karafka Web UI';
    } else {
      document.title = 'Karafka Web UI';
    }
  }
}
