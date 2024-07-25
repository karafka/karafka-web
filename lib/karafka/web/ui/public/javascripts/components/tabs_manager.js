class TabsManager {
  constructor() {
    this.storageKey = 'karafkaActiveTabsv2';
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
    const activeTabs = document.querySelectorAll('.inline-tabs > .active');
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
    var activeTabs = allTabs[url];

    if (!activeTabs) {
      activeTabs = Array.from(document.querySelectorAll('.inline-tabs > .active')).map(tab => tab.id);
    }

    if (activeTabs) {
      activeTabs.forEach(activeTabId => {
        const tabElement = document.getElementById(activeTabId);

        if (tabElement) {
          const parent = tabElement.parentElement;

          // Remove 'active' class from all sibling elements
          parent.querySelectorAll('.custom-tab').forEach(function(sibling) {
            sibling.classList.remove('active');
          });

          tabElement.classList.add('active')
          var content = document.getElementById(tabElement.getAttribute('data-target'))
          content.classList.remove('hidden')
        }
      });
    }
  }

  // Initializes tab management and event listeners
  manageTabs() {
    this.setActiveTabs();
    var self = this;

    document.querySelectorAll('.inline-tabs > .custom-tab').forEach(function(button) {
      button.addEventListener('click', function(event) {
        const parent = this.parentElement;

        // Remove 'active' class from all sibling elements
        parent.querySelectorAll('.custom-tab').forEach(function(sibling) {
          sibling.classList.remove('active');
          var target = sibling.getAttribute('data-target')
          document.getElementById(target).classList.add('hidden')
        });

        this.classList.add('active');
        self.saveCurrentActiveTabs();
        self.setActiveTabs()
      });
    });
  }
}
