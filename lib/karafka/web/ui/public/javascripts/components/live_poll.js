// Inspired by https://github.com/mperham/sidekiq JS code
//
// Live polls changes but won't refresh DOM if the payload is the same and will stop polling if
// user is selecting anything.
//
// In case of pages with charts, DOM won't be refreshed but charts will be updated

var livePollTimer = null;
var oldDOM = null;
var datePicker = null;
var startURL = window.location.href;

// Enable live polling by default on the first visit
function initLivePolling() {
  var polling = localStorage.karafkaLivePoll;

  if (polling != undefined) { return }

  localStorage.karafkaLivePoll = "enabled"
}

function isFormActive() {
  // Get the currently focused element
  const activeElement = document.activeElement;

  // Check if the focused element is a form control
  const isFormControl = ['INPUT', 'TEXTAREA', 'SELECT', 'BUTTON', 'FIELDSET'].includes(activeElement.tagName);

  // For buttons that are NOT in a form, they should only count as active if being hovered over
  if (isFormControl && activeElement.tagName === 'BUTTON' && !activeElement.closest('form')) {
    // Get element under mouse
    const mouseX = window.mouseX || 0;
    const mouseY = window.mouseY || 0;
    const elementUnderMouse = document.elementFromPoint(mouseX, mouseY);

    // Only consider the button active if the mouse is over it
    return elementUnderMouse === activeElement;
  }

  // For form controls inside forms and other form controls, just check if they're active
  return isFormControl;
}

function isEditableFormVisible() {
  const forms = document.querySelectorAll('form');

  for (let form of forms) {
    // Skip if form is not visible
    if (!form ||
        window.getComputedStyle(form).display === 'none' ||
        window.getComputedStyle(form).visibility === 'hidden' ||
        form.offsetParent === null) {
      continue;
    }
    // Get visibly editable inputs
    const editableInputs = Array.from(form.querySelectorAll(
      'input:not([type="hidden"]):not([readonly]):not([disabled]), ' +
      'textarea:not([readonly]):not([disabled]), ' +
      'select:not([disabled])'
    )).filter(input => {
      const style = window.getComputedStyle(input);
      return input.offsetParent !== null &&
             style.display !== 'none' &&
             style.visibility !== 'hidden' &&  // Changed from !== 'visible' to !== 'hidden'
             !input.closest('[aria-hidden="true"]');  // Check for hidden ancestors
    });
    if (editableInputs.length > 0) {
      return true;
    }
  }
  return false;
}

function isElementClickable(element) {
  // Check for common clickable elements
  if (element.tagName === 'A' ||
    element.tagName === 'BUTTON' ||
    (element.tagName === 'INPUT' && (element.type === 'button' || element.type === 'submit')) ||
    element.hasAttribute('onclick') ||
    typeof element.onclick === 'function') {
    return true;
  }

  // Check if the element is a <span> inside a .tab-container
  if (element.tagName === 'SPAN' && element.closest('.tab-container')) {
    return true;
  }

  // Check if the element is wrapped in a <button>
  if (element.closest('button')) { return true }

  // Check if element is wrapped with a link
  if (element.closest('a')) { return true }

  return false;
}

function isUserHoveringOverClickable() {
  // Get last known mouse position from the window object
  const mouseX = window.mouseX || 0;
  const mouseY = window.mouseY || 0;

  const elementUnderMouse = document.elementFromPoint(mouseX, mouseY);
  return elementUnderMouse && isElementClickable(elementUnderMouse);
}

// Track mouse position globally
document.addEventListener('mousemove', function(event) {
  window.mouseX = event.clientX;
  window.mouseY = event.clientY;
});


// Check is there is any text selected in the Web-UI
// It drives me crazy when I'm selecting things in Sidekiq Web-UI and the page is refreshed
// This mitigates this problem for Karafka Web
function isAnyTextSelected() {
  var text = "";

  if (typeof window.getSelection != "undefined") {
      text = window.getSelection().toString();
  } else if (typeof document.selection != "undefined" && document.selection.type == "Text") {
      text = document.selection.createRange().text;
  }

  return(text != "");
}

// If anything is collapsing at a given moment we should not update because it would cause weird
// glitches in the UI
function isCollapsingHappening() {
  const collapsingElements = document.querySelectorAll('.collapsing');
  return collapsingElements.length > 0;
}

// We should not poll and update if we have any text selected and we should not do it as well, when
// datetime picker with time selection is present
function isPollingPossible(check_url = false){
  if (isFormActive()) { return false }
  if (isEditableFormVisible()) { return false }
  if (isUserHoveringOverClickable()) { return false }
  if (isAnyTextSelected()) { return false }
  if (isOffsetLookupCalendarVisible()) { return false }
  if (isAnyModalOpen()) { return false }
  if (isCollapsingHappening()) { return false }
  if (isTurboOperating()) { return false }
  if (check_url && (startURL != window.location.href)) { return false }

  return true
}

// We should not poll and update when a modal is open. Otherwise it would be replaced and hidden.
function isAnyModalOpen(){
  const modals = document.querySelectorAll('dialog'); // Select all <dialog> elements
  for (let modal of modals) {
    if (modal.open) {
      return true; // A modal is open
    }
  }
  return false; // No modals are open
}

function bindPollingButtonClick() {
  var selector = document.getElementById("live-poll");

  if (selector == null) { return }

  selector.addEventListener('click', handleLivePollingButtonClick);
}

function handleLivePollingButtonClick() {
  toggleLivePollState();
  setLivePollButton();
  setPollingListener();
}

function toggleLivePollState() {
  if (localStorage.karafkaLivePoll == "enabled") {
    localStorage.karafkaLivePoll = "disabled";
  } else {
    localStorage.karafkaLivePoll = "enabled"
  }
}

function setLivePollButton() {
  selector = document.getElementById("live-poll");

  if (selector == null) { return }

  if (localStorage.karafkaLivePoll == "enabled") {
    selector.classList.remove("!text-gray-500");
    selector.classList.remove("hover:!text-primary-content")
  } else {
    selector.classList.add("!text-gray-500")
    selector.classList.add("hover:!text-primary-content")
  }
}

function checkResponse(resp) {
  if (!resp.ok) {
    throw resp;
  }
  return resp
}

function refreshPage(text) {
  // Do not refresh page if during the request something has change that should prevent us from
  // refreshing.
  if (!isPollingPossible()) { return false }

  var parser = new DOMParser();
  var new_doc = parser.parseFromString(text, "text/html");
  var new_content = new_doc.getElementById('content');
  var new_header = new_doc.getElementById('content-header');
  var new_breadcrums = new_doc.getElementById('content-breadcrumbs')

  // Do not modify if exactly the same content
  if (oldDOM == new_content.innerHTML) { return }

  var old_charts_count = document.querySelectorAll('.chartjs').length
  var new_charts_count = new_content.querySelectorAll('.chartjs').length

  // if there are any charts, we will not replace the whole page but only refreshable part
  // and we will use graphs data and update this as well
  // this will prevent us from leaking the charts references and overloading the memory
  // ChartsJS does not free all the resources when dom is replaced which causes problems after
  // the charts run for a long period of time without page reload
  if (new_charts_count == 0 || old_charts_count == 0) {
    document.getElementById('content').replaceWith(new_content)
    document.getElementById('content-header').replaceWith(new_header)

    if (new_breadcrums != null) {
      document.getElementById('content-breadcrumbs').replaceWith(new_breadcrums)
    }

    addListeners()
  } else {
    let new_refreshable = new_doc.getElementById('refreshable');
    document.getElementById('refreshable').replaceWith(new_refreshable)
    refreshCharts(new_doc)
  }

  oldDOM = new_content.innerHTML
}

function showError(error) {
  console.error(error)
}

function scheduleLivePoll() {
  if (oldDOM == null) {
    oldDOM = document.getElementById('content').innerHTML;
  }

  let ti = parseInt(localStorage.karafkaTimeInterval) || 5000;

  // Ensure refresh frequency is not less than 1 second
  // Prevent a case where local storage could be modified in such a way, that would cause issues
  // due to too frequent refreshes
  if (ti < 1000) {
    localStorage.karafkaTimeInterval = 5000
    ti = 5000
  }

  livePollTimer = setTimeout(livePollCallback, ti);
}

function livePollCallback() {
  clearTimeout(livePollTimer);
  livePollTimer = null;

  if (!isPollingPossible(false)) {
    setPollingListener();
    return;
  }

  startURL = window.location.href

  fetch(window.location.href)
  .then(checkResponse)
  .then(resp => resp.text())
  .then(refreshPage)
  .catch(showError)
  .finally(setPollingListener)
}

function setPollingListener()  {
  var selector = document.getElementById("live-poll");

  var polling = localStorage.karafkaLivePoll

  if (polling == "disabled" || polling == undefined || selector == null) {
    clearTimeout(livePollTimer);
    livePollTimer = null;
  } else {
    clearTimeout(livePollTimer);
    scheduleLivePoll();
  }
}
