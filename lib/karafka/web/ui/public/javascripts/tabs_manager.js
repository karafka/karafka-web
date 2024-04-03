class TabsManager {
  constructor() {
    this.storageKey = 'karafkaActiveTabs';
  }

  // Reads the active tabs from local storage
  readAllActiveTabs() {
    const rawActiveTabs = localStorage.getItem(this.storageKey);
    return rawActiveTabs ? JSON.parse(rawActiveTabs) : {};
  }

  // Saves the active tabs to local storage
  saveAllActiveTabs(data) {
    localStorage.setItem(this.storageKey, JSON.stringify(data));
  }

  // Saves the current state of active tabs
  saveCurrentActiveTabs() {
    const activeTabs = document.querySelectorAll('.tab-content > .active');
    const url = window.location.href.split('?')[0];
    let currentActiveTabs = [];
    let allTabs = this.readAllActiveTabs();

    activeTabs.forEach(activeTab => {
      currentActiveTabs.push(activeTab.id);
    });

    allTabs[url] = currentActiveTabs;
    this.saveAllActiveTabs(allTabs);
  }

  // Sets the active tabs based on stored data
  setActiveTabs() {
    const url = window.location.href.split('?')[0];
    const allTabs = this.readAllActiveTabs();
    const activeTabs = allTabs[url];

    if (!activeTabs) return;

    activeTabs.forEach(activeTabId => {
      const tabElement = document.getElementById(activeTabId + '-tab');
      if (tabElement) {
        const bsTab = new bootstrap.Tab(tabElement);
        bsTab.show();
      }
    });
  }

  // Initializes tab management and event listeners
  manageTabs() {
    this.setActiveTabs();

    document.addEventListener('shown.bs.tab', (event) => {
      this.saveCurrentActiveTabs();
    });
  }
}
