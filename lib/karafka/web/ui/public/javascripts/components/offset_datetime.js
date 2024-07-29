// JS code for calendar that allows us to select moment in time for which we should find
// the offset via our closest url

offsetLookupDatePicker = null;

function loadOffsetLookupDatePicker() {
  let options = {
    locale: {
      days: ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
      daysShort: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
      daysMin: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'],
      months: ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
      monthsShort: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
      today: 'Today',
      clear: 'Clear',
      dateFormat: 'yyyy-MM-dd',
      timeFormat: 'HH:mm',
      firstDay: 1
    },
    timepicker: true,
    onSelect: ({ date, datepicker, formattedDate }) => {
      // Make sure that date-time selection does not fill the picker button value
      // we want to preserve this
      document.getElementById('offset-lookup-datepicker').value = ""
    },
    onShow: function(){
      offsetLookupDatePicker.selectDate((new Date).getTime())
      offsetLookupDatePicker.maxDate = new Date
    },
    onHide: function(){
      offsetLookupDatePicker.selectDate((new Date).getTime())
    },
    buttons: [
      {
        content(dp) {
          return 'Go to offset'
        },
        onClick(dp) {
          let viewDate = dp.selectedDates[0] || new Date;
          let target = dp.$el.dataset.target
          dp.hide()
          location.href = target + '/' + formatRedirectDateTime(viewDate)
        }
      }
    ]
  };

  // do not leak calendars between reloads
  if (offsetLookupDatePicker != undefined) { offsetLookupDatePicker.destroy() }

  if (document.getElementById('offset-lookup-datepicker') == null) { return }

  offsetLookupDatePicker = new AirDatepicker('#offset-lookup-datepicker', options);

  offsetLookupDatePicker.maxDate = new Date
  offsetLookupDatePicker.selectDate(new Date().getTime())
}

function formatRedirectDateTime(date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0'); // Month is 0-based
  const day = String(date.getDate()).padStart(2, '0');
  const hour = String(date.getHours()).padStart(2, '0');
  const minute = String(date.getMinutes()).padStart(2, '0');

  return `${year}-${month}-${day}/${hour}:${minute}`;
}

// Informs if calendar is open. We do not refresh UI if it is open
function isOffsetLookupCalendarVisible() {
  if (offsetLookupDatePicker == undefined) { return false }

  return offsetLookupDatePicker.visible
}
