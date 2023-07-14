function updateTimeAgo() {
  var selection = document.querySelectorAll('time');

  if (selection.length != 0) {
    timeago.render(selection);
    timeago.cancel()
  }
}

function displayUi() {
  var content = document.getElementById('content');
  content.style.display = 'inherit';
}

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
  displayUi();
  manageCharts();
}

var ready = (callback) => {
  if (document.readyState != 'loading') callback();
  else document.addEventListener('DOMContentLoaded', callback);
}

ready(addListeners)
