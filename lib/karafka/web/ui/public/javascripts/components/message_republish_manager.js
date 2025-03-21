// code for handling message republishing functionality
class MessageRepublishManager {
  constructor() {
    this.init();
  }

  init() {
    // Check if the message republish form exists on the current page
    const form = document.getElementById('message-republish-form');
    if (!form) { return false; }

    // Get references to the relevant elements
    const topicSelect = form.querySelector('select[name="target_topic"]');
    const partitionInput = document.getElementById('target_partition');

    if (!topicSelect || !partitionInput) { return false; }

    // Initial setup when the page loads
    this.updatePartitionValidation(topicSelect, partitionInput);

    // Add event listener for topic selection changes
    topicSelect.addEventListener('change', () => {
      this.updatePartitionValidation(topicSelect, partitionInput);
    });
  }

  updatePartitionValidation(topicSelect, partitionInput) {
    // Get the selected option
    const selectedOption = topicSelect.options[topicSelect.selectedIndex];

    // Get the partition count from the selected topic's data attribute
    const partitionCount = parseInt(selectedOption.getAttribute('data-partitions'), 10);

    if (!isNaN(partitionCount) && partitionCount > 0) {
      // Update the max attribute of the partition input
      partitionInput.setAttribute('max', (partitionCount - 1).toString());

      // Get the current partition value
      const currentPartitionValue = parseInt(partitionInput.value, 10);

      // If the current value exceeds the maximum allowed partitions, clear the input
      if (!isNaN(currentPartitionValue) && currentPartitionValue >= partitionCount) {
        partitionInput.value = '';
      }
    } else {
      // If there's no valid partition count, set a high default max
      partitionInput.setAttribute('max', '10000');
    }
  }
}
