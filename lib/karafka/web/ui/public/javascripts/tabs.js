function readAllActiveTabs() {
  let raw_active_tabs = localStorage.karafkaActiveTabs

  if (raw_active_tabs == undefined) {
    return {}
  } else {
    return JSON.parse(raw_active_tabs)
  }
}

function saveAllActiveTabs(data) {
  localStorage.karafkaActiveTabs = JSON.stringify(data)
}

function saveCurrentActiveTabs() {
  let active_tabs = document.querySelectorAll('.tab-content > .active')
  let url = window.location.href.split('?')[0]
  let current = []
  let tabs = readAllActiveTabs()

  for (var i = 0; i < active_tabs.length; i++) {
    var active_tab = active_tabs[i]
    current.push(active_tab.id)
  }

  tabs[url] = current
  saveAllActiveTabs(tabs)
}

function setActiveTabs() {
  let url = window.location.href.split('?')[0]
  let tabs = readAllActiveTabs()
  let active_tabs = tabs[url]

  if (tabs[url] == undefined) { return }

  for (var i = 0; i < active_tabs.length; i++) {
    var active_tab = active_tabs[i]
    var tab = document.getElementById(active_tab + '-tab')

    if (tab != undefined) {
      var bsTab = new bootstrap.Tab(tab)
      bsTab.show()
    }
  }
}

function manageTabs() {
  setActiveTabs()

  document.addEventListener('shown.bs.tab', function (event) {
    saveCurrentActiveTabs()
  })
}
