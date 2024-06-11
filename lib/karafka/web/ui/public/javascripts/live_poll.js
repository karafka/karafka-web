// Inspired by https://github.com/mperham/sidekiq JS code
//
// Live polls changes but won't refresh DOM if the payload is the same and will stop polling if
// user is selecting anything.
//
// In case of pages with charts, DOM won't be refreshed but charts will be updated

var livePollTimer = null;
var oldDOM = null;
var datePicker = null;

// Enable live polling by default on the first visit
function initLivePolling() {
  var polling = localStorage.karafkaLivePoll;

  if (polling != undefined) { return }

  localStorage.karafkaLivePoll = "enabled"
}

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
function isPollingPossible(){
  if (isAnyTextSelected()) { return false }
  if (isOffsetLookupCalendarVisible()) { return false }
  if (isAnyModalOpen()) { return false }
  if (isCollapsingHappening()) { return false }

  return true
}

// We should not poll and update when a modal is open. Otherwise it would be replaced and hidden.
function isAnyModalOpen(){
  return document.querySelector('.modal.show') !== null;
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

  selector.classList.remove("d-none");

  if (localStorage.karafkaLivePoll == "enabled") {
    selector.textContent = selector.dataset.on;
    selector.classList.add("btn-success");
    selector.classList.remove("btn-secondary");
  } else {
    selector.textContent = selector.dataset.off;
    selector.classList.add("btn-secondary");
    selector.classList.remove("btn-success");
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

  if (!isPollingPossible()) {
    setPollingListener();
    return;
  }

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
