class LineChartsManager {
  constructor() {
    this.datasetStateManager = new DatasetStateManager();
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
          borderWidth: 2.5
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
        hover: {
          intersect: false
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
      }
    });
  }
}
