function refreshCharts(newDoc) {
  const lineChartsManager = new LineChartsManager();
  lineChartsManager.refreshAndRender(newDoc, true);

  const barChartManager = new BarChartManager();
  barChartManager.refreshAndRenderBarCharts(newDoc, true);
}

// Turbo visits and live poll refreshes replace the page content without destroying its charts.
// Chart.js keeps each chart registered (with its listeners) until destroyed, which would keep the
// elements of every page with charts alive, so we destroy those whose canvas is gone.
function destroyDetachedCharts() {
  Object.values(Chart.instances).forEach((chart) => {
    if (!chart.canvas || !chart.canvas.isConnected) {
      chart.destroy();
    }
  });
}

function manageCharts() {
  destroyDetachedCharts();

  const lineChartsManager = new LineChartsManager();
  lineChartsManager.refreshAndRender(document, false);

  const barChartManager = new BarChartManager();
  barChartManager.refreshAndRenderBarCharts(document, false);
}
