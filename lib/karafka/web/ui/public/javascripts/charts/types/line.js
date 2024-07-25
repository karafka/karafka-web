class LineChartsManager {
  constructor() {
    this.datasetStateManager = new DatasetStateManager();
  }

  getLegendHeightPercentage(chart) {
    const chartArea = chart.chartArea;
    const chartHeight = chart.height;
    const legendHeight = chartHeight - (chartArea.bottom - chartArea.top);
    const legendHeightPercentage = (legendHeight / chartHeight) * 100;
    return Math.round(legendHeightPercentage);
  }

  afterRenderPlugin() {
    const self = this

    return {
      id: 'afterRender',
      afterRender: function(chart) {
        var legendHeightPercentage = self.getLegendHeightPercentage(chart);
        const element = document.getElementById(chart.canvas.id);

        if (legendHeightPercentage > 50 && element.parentElement.style.height == '') {
          element.parentElement.style.height = '400px'
        }
      }
    }
  }

  refreshAndRender(doc, isRefresh = false) {
    const charts = (isRefresh ? doc : document).querySelectorAll('.chartjs-line');

    charts.forEach((chartElement) => {
      const chartId = chartElement.id;
      const chartn = (isRefresh ? doc : document).getElementById(chartId);
      const chartData = JSON.parse(chartn.dataset.datasets);
      let labels = [],
        data = [],
        yPrecision = 0;
      const labelTypeY = chartn.dataset.label_type_y;
      const labelTypeX = chartn.dataset.label_type_x;
      const disabledSets = this.datasetStateManager.getCurrentChart(chartId);

      Object.entries(chartData).forEach(([key, value], index) => {
        value.forEach(([label, dataPoint]) => {
          if (index === 0) {
            labels.push(DataFormattingUtils.formatLabelX(label, labelTypeX));
          }
          if (DataFormattingUtils.isFractionalPrecision(dataPoint)) {
            yPrecision = 2;
          }
        });

        data.push({
          data: value,
          label: key,
          hidden: disabledSets.includes(index),
          borderWidth: 2.5,
          pointHitRadius: 10
        });
      });

      if (isRefresh) {
        const chart = Chart.getChart(chartId);
        chart.data.datasets = data;
        chart.data.labels = labels;
        chart.update('none');
      } else {
        this.render(chartElement, labels, data, yPrecision, labelTypeY);
      }
    });
  }

  render(handler, labels, data, yPrecision, labelTypeY) {
    var tooltip_mode = null

    if (data.length > 10) {
      tooltip_mode = 'point'
    } else {
      tooltip_mode = 'x'
    }

    new Chart(handler, {
      type: 'line',
      data: {
        labels: labels,
        datasets: data
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        aspectRatio: 5,
        title: {
          display: false
        },
        interaction: {
          mode: 'nearest',
          axis: 'x',
          intersect: false
        },
        animation: false,
        transitions: {
          active: {
            animation: {
              duration: false
            }
          }
        },
        plugins: {
          legend: {
            position: 'bottom',
            labels: {
              padding: 20
            },
            onClick: (e, legendItem, legend) => {
              const index = legendItem.datasetIndex;
              const ci = legend.chart;
              if (ci.isDatasetVisible(index)) {
                ci.hide(index);
                legendItem.hidden = true;
              } else {
                ci.show(index);
                legendItem.hidden = false;
              }

              this.datasetStateManager.saveCurrent();
            }
          },
          tooltip: {
            mode: tooltip_mode,
            filter: function (tooltipItem, currentIndex, tooltipItems) {
              // Display at most 10 elements in the legend
              return currentIndex < 10
            },
            callbacks: {
              label: function(tooltipItem) {
                return DataFormattingUtils.formatTooltip(labelTypeY, tooltipItem);
              }
            }
          }
        },
        scales: {
          x: {
            display: false,
          },
          y: {
            ticks: {
              precision: yPrecision,
              count: 5,
              callback: function(label, index, labels) {
                return DataFormattingUtils.formatLabelY(labelTypeY, label, index, labels);
              }
            }
          }
        },
        elements: {
          point: {
            radius: 0,
            style: false
          },
          line: {
            style: 'star',
            radius: 0,
            spanGaps: false
          }
        },
        hover: {
          mode: 'index',
          intersect: false,
        }
      },
      plugins: [this.afterRenderPlugin()]
    });
  }
}
