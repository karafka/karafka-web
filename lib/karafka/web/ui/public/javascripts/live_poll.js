// inspired by https://github.com/mperham/sidekiq JS code
//
// Live polls changes but won't refresh DOM if the payload is the same and will stop polling if
// user is selecting anything.

var livePollTimer = null;
var oldDOM = null;

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
    throw response.error();
  }
  return resp
}

function refreshPage(text) {
  var parser = new DOMParser();
  var new_doc = parser.parseFromString(text, "text/html");
  var new_content = new_doc.getElementById('content');

  // Do not modify if exactly the same content
  if (oldDOM == new_content.innerHTML) { return }

  // if there are any charts, we will not replace the whole page but only counters
  // and we will use graphs data and update this as well
  // this will prevent us from leaking the charts references and overloading the memory
  // ChartsJS does not free all the resources when dom is replaced which causes problems after
  // the charts run for a long period of time without page reload
  if (new_content.querySelectorAll('.chartjs').length == 0) {
    document.getElementById("content").replaceWith(new_content)
    addListeners()
  } else {
    let new_counters = new_doc.getElementById('counters');
    document.getElementById('counters').replaceWith(new_counters)
    refreshCharts(new_doc)
  }

  oldDOM = new_content.innerHTML
}

function showError(error) {
  console.error(error)
}

function scheduleLivePoll() {
  if (oldDOM == null) {
    oldDOM = document.getElementById("content").innerHTML;
  }

  let ti = parseInt(localStorage.karafkaTimeInterval) || 5000;
  livePollTimer = setTimeout(livePollCallback, ti);
}

function livePollCallback() {
  clearTimeout(livePollTimer);
  livePollTimer = null;

  if (isAnyTextSelected()) {
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
  selector = document.getElementById("live-poll");

  if (localStorage.karafkaLivePoll == "disabled" || selector == null) {
    clearTimeout(livePollTimer);
    livePollTimer = null;
  } else {
    clearTimeout(livePollTimer);
    scheduleLivePoll();
  }
}
