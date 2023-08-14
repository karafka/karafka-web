// Nicer display of time distance from a given event
function updateTimeAgo() {
  var selection = document.querySelectorAll('time');

  if (selection.length != 0) {
    timeago.render(selection);
    timeago.cancel()
  }
}

// To prevent from flickering, the UI is initially hidden and visible when all the JS components
// are fully initialized
function displayUi() {
  var content = document.getElementById('content');
  content.style.display = 'inherit';
}

// When using explorer, we can select the desired partition. This code redirects without having
// to press a button after a select
function redirectToPartition() {
  var selector = document.getElementById('current-partition');

  if (selector == null) { return }

  selector.addEventListener('change', function(){
    location.href = this.value;
  });
}

function addListeners() {
  bindPollingButtonClick();
  setLivePollButton();
  setPollingListener();

  hljs.highlightAll();
  updateTimeAgo();
  redirectToPartition();
  manageTabs();
  manageCharts();
  displayUi();
}

var ready = (callback) => {
  if (document.readyState != 'loading') callback();
  else document.addEventListener('DOMContentLoaded', callback);
}

ready(addListeners)
