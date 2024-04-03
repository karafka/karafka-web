class BarChartManager {
  constructor() {
    this.datasetStateManager = new DatasetStateManager();
  }

  refreshAndRenderBarCharts(doc, isRefresh = false) {
    const charts = (isRefresh ? doc : document).querySelectorAll('.chartjs-bar');

    charts.forEach((chartElement) => {
      const chartId = chartElement.id;
      const chartn = (isRefresh ? doc : document).getElementById(chartId);
      const chartData = JSON.parse(chartn.dataset.datasets);
      let labels = [],
        data = [],
        allDataPoints = [];
      const labelTypeY = chartn.dataset.label_type_y;
      const labelTypeX = chartn.dataset.label_type_x;
      const disabledSets = this.datasetStateManager.getCurrentChart(chartId);
      Object.entries(chartData).forEach(([key, value], index) => {
        value.forEach(([label, dataPoint]) => {
          allDataPoints.push(dataPoint);
          if (index === 0) {
            labels.push(DataFormattingUtils.formatLabelX(label, labelTypeX));
          }
        });
        data.push({
          data: value.map(([, dataPoint]) => dataPoint),
          label: key,
          hidden: disabledSets.includes(index),
          borderWidth: 2.5
        });
      });
      const minYValue = Math.min(...allDataPoints);
      const maxYValue = Math.max(...allDataPoints);
      const adjustedMinYValue = Math.round(minYValue - (0.1 * minYValue));
      const adjustedMaxYValue = Math.round(maxYValue + (0.005 * maxYValue));
      const average = Math.round(allDataPoints.reduce((sum, current) => sum + current, 0) / allDataPoints.length);

      data.push({
        type: 'line',
        label: 'Average',
        data: new Array(labels.length).fill(average),
        borderWidth: 2,
        fill: false,
        pointRadius: 0,
        hoverBorderWidth: 3, // Makes the line slightly thicker on hover, making it easier to hover over
        pointHitRadius: 20 // Increases the radius around the invisible points that will detect a hover
      });

      if (isRefresh) {
        const chart = Chart.getChart(chartId);
        chart.data.datasets = data;
        chart.data.labels = labels;
        chart.options.scales.y.min = adjustedMinYValue;
        chart.options.scales.y.max = adjustedMaxYValue;
        chart.update('none');
      } else {
        this.renderBarChart(chartElement, labels, data, adjustedMinYValue, adjustedMaxYValue, labelTypeY);
      }
    });
  }

  renderBarChart(handler, labels, data, minYValue, maxYValue, labelTypeY) {
    new Chart(handler, {
      type: 'bar',
      data: {
        labels: labels,
        datasets: data
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        aspectRatio: 5,
        scales: {
          x: {
            display: true,
          },
          y: {
            beginAtZero: false,
            min: minYValue,
            max: maxYValue,
            ticks: {
              maxTicksLimit: 8,
              callback: function(label, index, labels) {
                return DataFormattingUtils.formatLabelY(labelTypeY, label, index, labels);
              }
            }
          }
        },
        animation: false,
        animations: {
          colors: false,
          x: false
        },
        transitions: {
          active: {
            animation: {
              duration: false
            }
          }
        },
        plugins: {
          legend: {
            position: 'hidden'
          },
          tooltip: {
            callbacks: {
              label: function(context) {
                let label = context.dataset.label || '';
                if (label === 'Average') {
                  label += ': ' + context.formattedValue;
                } else {
                  return DataFormattingUtils.formatTooltip(labelTypeY, context);
                }
                return label;
              }
            }
          }
        },
      }
    });
  }
}
