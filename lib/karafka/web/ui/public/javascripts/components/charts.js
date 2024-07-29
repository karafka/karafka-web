function refreshCharts(newDoc) {
  const lineChartsManager = new LineChartsManager();
  lineChartsManager.refreshAndRender(newDoc, true);

  const barChartManager = new BarChartManager();
  barChartManager.refreshAndRenderBarCharts(newDoc, true);
}

function manageCharts() {
  const lineChartsManager = new LineChartsManager();
  lineChartsManager.refreshAndRender(document, false);

  const barChartManager = new BarChartManager();
  barChartManager.refreshAndRenderBarCharts(document, false);
}
