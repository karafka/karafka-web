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

function niceBytes(x){
  let units = ['bytes', 'KiB', 'MiB', 'GiB', 'TiB', 'PiB', 'EiB', 'ZiB', 'YiB'];

  let l = 0, n = parseInt(x, 10) || 0;

  while(n >= 1024 && ++l){
      n = n/1024;
  }

  return(n.toFixed(n < 10 && l > 0 ? 1 : 0) + ' ' + units[l]);
}

function formatLabelX(value, type) {
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

function formatLabelY(type, label, index, labels) {
  switch(type) {
  case 'percentage':
    if (Math.floor(label) === label) {
      return label + '%'
    } else {
      return (Math.round(label * 100) / 100) + '%'
    }
  case 'memory':
    return niceBytes(label * 1024)
  default:
    if (Math.floor(label) === label) {
      return label
    } else {
      return Math.round(label * 100) / 100
    }
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
    let label_type_y = chartn.dataset.label_type_y
    let label_type_x = chartn.dataset.label_type_x
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
          labels.push(formatLabelX(current_label, label_type_x))
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

    chart.data.datasets = data
    chart.data.labels = labels

    chart.update()
  }
}

function renderChart(handler, labels, data, y_precision, label_type_y) {
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
              precision: y_precision,
              // forces step size to be 50 units
              count: 5,
              callback: function(label, index, labels) {
                return formatLabelY(label_type_y, label, index, labels)
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
      },
    }
  })
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
    let label_type_y = chart.dataset.label_type_y
    let label_type_x = chart.dataset.label_type_x
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
          labels.push(formatLabelX(current_label, label_type_x))
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

    renderChart(chart, labels, data, y_precision, label_type_y)
  }
}

function manageCharts() {
  renderCharts()
}
