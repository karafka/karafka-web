// Nicer display of time distance from a given event
function updateTimeAgo() {
  var selection = document.querySelectorAll('time');

  if (selection.length != 0) {
    timeago.render(selection);
    timeago.cancel()
  }

  var selection = document.getElementsByClassName('time-title')
  var title = null

  for (var i = 0; i < selection.length; i++) {
    let element = selection[i]

    title = element.getAttribute('title')
    element.setAttribute('title', timeago.format(title))
  }
}

// Cheap way to do breadcrumbs
function refreshTitle() {
  const breadcrumbs = document.querySelectorAll('.breadcrumbs a');
  let breadcrumbTexts = Array.from(breadcrumbs).slice(1).map(crumb => crumb.textContent.trim());

  if (breadcrumbTexts.length > 0) {
    document.title = breadcrumbTexts.join(' > ') + ' - Karafka Web UI';
  } else {
    document.title = 'Karafka Web UI';
  }
}

// When using explorer, we can select the desired partition. This code redirects without having
// to press a button after a select
function redirectToPartition() {
  var selector = document.getElementById('current-partition');

  if (selector == null) { return }

  selector.addEventListener('change', function(){
    Turbo.visit(this.value);
  });
}

// Binds to links and forms to make sure action is what user wants
function bindActionsConfirmations() {
  var elements = document.getElementsByClassName('confirm-action')
  var confirmation = 'Are you sure?'

  for (var i = 0; i < elements.length; i++) {
    let element = elements[i]
    let action = 'click'

    if (element.nodeName === 'FORM') {
      action = 'submit'
    }

    element.addEventListener(action, function(event) {
      if (!window.confirm(confirmation)) {
        event.preventDefault();
      }
    })
  }
}

function bindLockableButtons() {
  document.querySelectorAll('.btn-lockable').forEach(function(button) {
    button.addEventListener('click', function(event) {
      // Find the form element the button is within
      const form = button.closest('form');

      // If the button is part of a form, add a submit event listener to the form
      if (form) {
        form.addEventListener('submit', function() {
          button.disabled = true;
          button.textContent += '...';
          // also lock any modal that is open as the form is submitted
          var modals = document.querySelectorAll('.modal');

          // Add 'modal-locked' class to each modal
          modals.forEach(function (modal) {
            modal.classList.add('modal-locked');
          });
        }, { once: true });
      } else {
        // If the button is not part of a form, disable it immediately
        button.disabled = true;
        button.textContent += '...';
      }
    });
  });
}

function addListeners() {
  initLivePolling();
  bindPollingButtonClick();
  bindLockableButtons();
  setLivePollButton();
  setPollingListener();

  hljs.highlightAll();
  updateTimeAgo();
  redirectToPartition();

  const tabsManager = new TabsManager();
  tabsManager.manageTabs();

  manageCharts();
  bindActionsConfirmations();
  loadOffsetLookupDatePicker();

  new BtnToggleManager();
  new BtnToggleManager('.btn-toggle-nav-collapsed', 'collapsed');
  new ThemeManager();

  refreshTitle()
  new SearchMetadataVisibilityManager();
  new SearchModalManager();
}

document.addEventListener('turbo:load', addListeners);

Turbo.setProgressBarDelay(100)
