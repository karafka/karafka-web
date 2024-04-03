class DatasetStateManager {
  constructor() {
    this.storageKey = 'karafkaDisabledDatasets';
  }

  // Reads all disabled datasets from localStorage
  readAll() {
    const raw = localStorage.getItem(this.storageKey);
    return raw ? JSON.parse(raw) : {};
  }

  // Saves all disabled datasets to localStorage
  saveAll(data) {
    localStorage.setItem(this.storageKey, JSON.stringify(data));
  }

  // Saves the current disabled datasets for all '.chartjs-line' charts
  saveCurrent() {
    const charts = document.querySelectorAll('.chartjs');
    const url = window.location.href.split('?')[0];
    let currentDisabled = {};
    let allDisabled = this.readAll();

    charts.forEach(chart => {
      const chartId = chart.id;
      const chartInstance = Chart.getChart(chartId);
      if (!chartInstance || !chartInstance.legend || !chartInstance.legend.legendItems) return;

      let disabledIndices = chartInstance.legend.legendItems
        .map((item, index) => item.hidden ? index : null)
        .filter(index => index !== null);

      if (disabledIndices.length > 0) {
        currentDisabled[chartId] = disabledIndices;
      }
    });

    allDisabled[url] = currentDisabled;
    this.saveAll(allDisabled);
  }

  // Retrieves the disabled datasets for a specific chart ID
  getCurrentChart(chartId) {
    const url = window.location.href.split('?')[0];
    let allDisabled = this.readAll();
    let currentDisabled = allDisabled[url] || {};
    return currentDisabled[chartId] || [];
  }
}
