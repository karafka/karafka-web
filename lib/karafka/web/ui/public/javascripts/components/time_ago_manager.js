// Manages time display formatting across the UI
class TimeAgoManager {
  constructor() {
    this.init();
  }

  init() {
    this.updateTimeAgo();
  }

  updateTimeAgo() {
    const timeElements = document.querySelectorAll('time');
    if (timeElements.length != 0) {
      timeago.render(timeElements);
      timeago.cancel();
    }

    const timeTitleElements = document.getElementsByClassName('time-title');
    for (let i = 0; i < timeTitleElements.length; i++) {
      let element = timeTitleElements[i];
      let title = element.getAttribute('title');
      element.setAttribute('title', timeago.format(title));
    }
  }
}
