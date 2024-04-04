const DataFormattingUtils = {
  niceBytes(x, precision = 2) {
    const units = ['bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    let l = 0, n = parseInt(x, 10) || 0;

    while (n >= 1024 && ++l) {
      n /= 1024;
    }

    return `${n.toFixed(n < 10 && l > 0 ? 1 : precision)} ${units[l]}`;
  },

  formatLabelX(value, type) {
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
  },

  formatTooltip(type, tooltipItem) {
    let value = tooltipItem.parsed.y;
    let label = tooltipItem.dataset.label;

    switch(type) {
    case 'percentage':
      if (Math.floor(value) === value) {
        return label + ': ' + value + ' %';
      } else {
        return label + ': ' + (Math.round(value * 100) / 100) + ' %';
      }
    case 'memory':
      return label + ': ' + DataFormattingUtils.niceBytes(value * 1024, 2);
    default:
      return tooltipItem.yLabel
    }
  },

  formatLabelY(type, label) {
    switch(type) {
    case 'percentage':
      if (Math.floor(label) === label) {
        return label + '%'
      } else {
        return (Math.round(label * 100) / 100) + '%'
      }
    case 'memory':
      return DataFormattingUtils.niceBytes(label * 1024, 1)
    default:
      if (Math.floor(label) === label) {
        return label
      } else {
        return Math.round(label * 100) / 100
      }
    }
  },

  isFractionalPrecision(value) {
    return value !== Math.floor(value);
  }
};
