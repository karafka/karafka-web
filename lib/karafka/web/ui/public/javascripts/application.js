function addListeners() {
  initLivePolling();
  bindPollingButtonClick();
  setLivePollButton();
  setPollingListener();

  hljs.highlightAll();
  new TimeAgoManager();
  new PartitionRedirectManager();

  const tabsManager = new TabsManager();
  tabsManager.manageTabs();

  manageCharts();
  loadOffsetLookupDatePicker();

  new BtnToggleManager();
  new BtnToggleManager('.btn-toggle-nav-collapsed', 'collapsed');
  new ThemeManager();

  new ButtonLockManager();
  new ActionConfirmationManager();
  new PageTitleTracker();
  new SearchMetadataVisibilityManager();
  new SearchModalManager();
  new TimestampSelector();
  new AlertsManager();
  new MessageRepublishManager();
}

document.addEventListener('turbo:load', addListeners);

Turbo.setProgressBarDelay(100)
