// Manages partition selection in explorer view
// When using explorer, we can select the desired partition. This code redirects without having
// to press a button after a select
class PartitionRedirectManager {
  constructor() {
    this.init();
  }

  init() {
    this.redirectToPartition();
  }

  redirectToPartition() {
    const selector = document.getElementById('current-partition');
    if (selector == null) { return; }

    selector.addEventListener('change', function() {
      Turbo.visit(this.value);
    });
  }
}
