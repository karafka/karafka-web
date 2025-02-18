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
      const form = button.closest('form');

      const lockButton = () => {
        button.disabled = true;

        const hasText = Array.from(button.childNodes).some(node =>
          node.nodeType === Node.TEXT_NODE && node.textContent.trim().length > 0
        );

        if (hasText) {
          button.insertAdjacentText('beforeend', '...');
        }

        // Keep button disabled through the entire Turbo visit cycle
        document.addEventListener('turbo:before-visit', () => {
          button.disabled = true;
        }, { once: true });

        document.querySelectorAll('.modal').forEach(function(modal) {
          modal.classList.add('modal-locked');
        });
      };

      if (form) {
        form.addEventListener('submit', lockButton, { once: true });

        // Add this to ensure button stays disabled after form submission
        form.addEventListener('turbo:submit-end', () => {
          button.disabled = true;
        }, { once: true });
      } else {
        lockButton();
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
  new TimestampSelector();
  new AlertsManager();
}

document.addEventListener('turbo:load', addListeners);

Turbo.setProgressBarDelay(100)
