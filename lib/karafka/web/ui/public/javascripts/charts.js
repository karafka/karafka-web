function readAllDisabledDatasets() {
  let raw_disabled_datasets = localStorage.karafkaDisabledDatasets

  if (raw_disabled_datasets == undefined) {
    return {}
  } else {
    return JSON.parse(raw_disabled_datasets)
  }
}

function saveAllDisabledDatasets(data) {
  localStorage.karafkaDisabledDatasets = JSON.stringify(data)
}

function saveCurrentDisabledDatasets() {
  let charts = document.querySelectorAll('.chartjs')
  let url = window.location.href.split('?')[0]
  let current = {}
  let tabs = readAllDisabledDatasets()

  for (var i = 0; i < charts.length; i++) {
    let chart_id = charts[i].id
    let chart = Chart.getChart(chart_id)
    let items = chart.legend.legendItems
    current[chart_id] = []

    for (var y = 0; y < items.length; y++) {
      if (items[y].hidden) {
        current[chart_id].push(y)
      }
    }
  }

  tabs[url] = current
  saveAllDisabledDatasets(tabs)
}

function getCurrentChartDisabledDatasets(chart_id) {
  let all_disabled = readAllDisabledDatasets()
  let url = window.location.href.split('?')[0]
  let current = all_disabled[url]

  if (current == undefined) { return [] }

  var disabled_indexes = current[chart_id]

  if (disabled_indexes != undefined) {
    return disabled_indexes
  } else {
     return []
  }
}

function formatLabel(value, type) {
  switch (type) {
    case 'date':
      let date = new Date(value * 1000)
      let date_str =
        ("00" + (date.getMonth() + 1)).slice(-2) + "/" +
        ("00" + date.getDate()).slice(-2) + "/" +
        date.getFullYear() + " " +
        ("00" + date.getHours()).slice(-2) + ":" +
        ("00" + date.getMinutes()).slice(-2) + ":" +
        ("00" + date.getSeconds()).slice(-2);

      return date_str
    default:
      return value
  }
}

function isFractialPrecision(value) {
  return value === +value && value !== (value|0)
}

function refreshCharts(new_doc) {
  var charts = new_doc.querySelectorAll('.chartjs')

  for (var i = 0; i < charts.length; i++) {
    var chart = Chart.getChart(charts[i].id)
    var chart_id = charts[i].id
    var chartn = new_doc.getElementById(chart_id)
    var chart_data = chartn.dataset.datasets

    let datasets = JSON.parse(chart_data)
    let data = []
    let labels = []
    let label_type = chartn.dataset.label_type
    // by default assume integer values
    let y_precision = 0
    let disabled_sets = getCurrentChartDisabledDatasets(chart_id)

    Object.keys(datasets).forEach(function(key, i) {
      var current_set = datasets[key]

      let y = 0;

      while (y < current_set.length) {
        let current_value = current_set[y][1]
        let current_label = current_set[y][0]

        if (i == 0) {
          labels.push(formatLabel(current_label, label_type))
        }

        if (isFractialPrecision(current_value)) {
          y_precision = 2
        }

        y++
      }

      chart.data.datasets[i].data = datasets[key]
    })

    chart.data.labels = labels

    chart.update()
  }
}

function renderChart(handler, labels, data, y_precision) {
  let chart = Chart.getChart(handler.id)

  if (chart == undefined) {
    new Chart(handler, {
      type : 'line',
      data : {
        labels : labels,
        datasets : data
      },
      options : {
        responsive: true,
        aspectRatio: 5,
        title : {
          display : false
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
            onClick: function(e, legendItem, legend) {
                const index = legendItem.datasetIndex;
                const ci = legend.chart;
                if (ci.isDatasetVisible(index)) {
                    ci.hide(index);
                    legendItem.hidden = true;
                } else {
                    ci.show(index);
                    legendItem.hidden = false;
                }

                saveCurrentDisabledDatasets()
            }
          }
        },
        scales:{
            x: {
                display: false,
            },
            y: {
              ticks: {
                // forces step size to be 50 units
                count: 5,
                 callback: function(label, index, labels) {
                     if (Math.floor(label) === label) {
                         return label
                     } else {
                       return Math.round(label * 100) / 100
                     }
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
            radius: 0
          }
        },
        hover: {
          mode: 'index',
          intersect: false,
        },
      }
    })
  } else {
    alert('jest')
  }
}

function renderCharts() {
  var charts = document.getElementsByClassName('chartjs');

  for (let i = 0; i < charts.length; i++) {
    let chart = charts.item(i)
    let chart_id = chart.id
    let raw_data = chart.dataset.datasets
    let datasets = JSON.parse(raw_data)
    let data = []
    let labels = []
    let label_type = chart.dataset.label_type
    // by default assume integer values
    let y_precision = 0
    let disabled_sets = getCurrentChartDisabledDatasets(chart_id)

    Object.keys(datasets).forEach(function(key, i) {
      var current_set = datasets[key]

      let y = 0;

      while (y < current_set.length) {
        let current_value = current_set[y][1]
        let current_label = current_set[y][0]

        if (i == 0) {
          labels.push(formatLabel(current_label, label_type))
        }

        if (isFractialPrecision(current_value)) {
          y_precision = 2
        }

        y++
      }

      data.push(
        {
          data: datasets[key],
          label: key,
          hidden: disabled_sets.includes(i)
        }
      )
    })

    renderChart(chart, labels, data, y_precision)
  }
}

function manageCharts() {
  renderCharts()
}
