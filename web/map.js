// get element IDs needed later
var form = document.querySelector("form");
form.addEventListener("submit", function(evt) {
  map_update(evt);
  evt.preventDefault();
});
var titlerow = document.getElementById('titlerow');
var logTable = document.getElementById('log');

var type = document.getElementById('type');
var band = document.getElementById('band');
var call = document.getElementById('call');
var contest = document.getElementById('contest');
var color = document.getElementById('color');
var mode = document.getElementById('mode');
var mycall = document.getElementById('mycall');
var time = document.getElementById('time');

// populate drop-down menus ////////////////////////////////

var send_loginfo_request = function (main_callback) {
  request = new XMLHttpRequest;
  request.open('GET', 'loginfo.cgi', true);

  request.onload = function() {
    if (request.status >= 200 && request.status < 400){
      // Success!
      data = JSON.parse(request.responseText);
      main_callback(data);
      // ready to go now
    } else {
      // We reached our target server, but it returned an error
      alert('Could not load loginfo.cgi');
    }
  };

  request.onerror = function() {
    // There was a connection error of some sort
    alert('Could not load loginfo.cgi');
  };

  request.send();
};

var populate_dropdowns = function (data) {
  for (y of data['years']) {
    var option = document.createElement('option');
    option.text = y;
    time.appendChild(option);
  }
  for (b of data['bands']) {
    var option = document.createElement('option');
    option.text = b;
    band.appendChild(option);
  }
  for (m of data['modes']) {
    var option = document.createElement('option');
    option.text = m;
    mode.appendChild(option);
  }
  for (m of data['mycalls']) {
    var option = document.createElement('option');
    option.text = m;
    mycall.appendChild(option);
  }
  for (c of data['contests']) {
    var option = document.createElement('option');
    option.text = c['dayspan'] + ' ' + c['contest'];
    option.value = c['week'] + ' ' + c['contest'];
    contest.appendChild(option);
  }
};

// update menus from URL parameters //////////////////////////////

var update_select = function (select, value) {
  var selectOptions = select.options;
  for (var opt, j = 0; opt = selectOptions[j]; j++) {
    if (opt.value == value) {
      select.selectedIndex = j;
      break;
    }
  }
};

var update_select_from_params = function (params, select, param) {
  if (params.has('type')) {
    update_select(select, params.get(param));
  }
};

var update_menus_from_url = function () {
  var params = new URLSearchParams(window.location.search);
  update_select_from_params(params, type, 'type');
  update_select_from_params(params, band, 'band');
  call.value = params.get('call');
  update_select_from_params(params, contest, 'contest');
  update_select_from_params(params, color, 'color');
  update_select_from_params(params, mode, 'mode');
  update_select_from_params(params, mycall, 'mycall');
  update_select_from_params(params, time, 'time');
};

// get data from menus and update map and window title ///////////////

var url_from_menus = function () {
  var url = '?type=' + type.value + '&color=' + color.value;
  var title = 'DF7CB Logbook: ' + type.options[type.selectedIndex].text;

  if (band.value !== 'all') {
    url += '&band=' + band.value;
    title += ' ' + band.value;
  }
  if (call.value !== '') {
    url += '&call=' + call.value;
    title += ' ' + call.value;
  }
  if (contest.value !== '---') {
    url += '&contest=' + contest.value;
    title += ' ' + contest.options[contest.selectedIndex].text;
  }
  if (mode.value !== 'all') {
    url += '&mode=' + mode.value;
    title += ' ' + mode.value;
  }
  if (mycall.value !== 'all') {
    url += '&mycall=' + mycall.value;
    title += ' ' + mycall.value;
  }
  if (time.value !== 'all') {
    url += '&time=' + time.value;
    title += ' ' + time.options[time.selectedIndex].text;
  }

  return [url, title];
};

var map_update = function (evt) {
  var url_title = url_from_menus();
  var url = url_title[0];
  var title = url_title[1];

  window.history.pushState({}, title, url);
  titlerow.innerHTML = title;
  vectorSource.setUrl('geojson.cgi' + url);
  vectorSource.refresh();
};

// the map ////////////////////////////////////////////////////////////

var all_colors = [
  'rgba(0, 0, 200, 0.3)',
  'rgba(0, 200, 0, 0.3)',
  'rgba(200, 0, 0, 0.3)',
  'rgba(200, 200, 0, 0.3)',
  'rgba(200, 0, 200, 0.3)',
  'rgba(0, 200, 200, 0.3)',
];

// generate a striped canvasPattern
var pattern = function (n, colors) {
  const width = 12;
  var thickness = width / Math.sqrt(2);

  var canvas = document.createElement('canvas');
  canvas.width = n * width;
  canvas.height = n * width;
  var context = canvas.getContext('2d');
  //context.globalAlpha = 0.3;
  context.rotate(-Math.PI/4);

  for (var i = 0; i < n; i++) {
  context.fillStyle = colors[i];
    context.fillRect(-n*width,    i *thickness, 2*n*width, thickness);
    context.fillRect(-n*width, (i+n)*thickness, 2*n*width, thickness);
  }

  return context.createPattern(canvas, 'repeat');
};

var make_pattern = function (all_items, items) {
  let n = 0;
  let colors = [];
  for (let i = 0; i < all_items.length; i++) {
    if (items.includes(all_items[i])) {
      n++;
      colors.push(all_colors[i % all_colors.length]);
    }
  }
  if (n == 0) {
    return 'rgba(100, 100, 100, 0.3)';
  } else if (n == 1) {
    return colors[0];
  } else {
    return pattern(n, colors);
  }
};

var random_color = function() {
  let r = 0;
  let g = 0;
  let b = 0;
  while (r+g+b < 200 || r+g+b > 400) {
    r = Math.round(Math.random() * 255);
    g = Math.round(Math.random() * 255);
    b = Math.round(Math.random() * 255);
  }
  return `rgba(${r}, ${g}, ${b}, 0.3)`;
};

// main vector layer
var countryStyle = new ol.style.Style({
  fill: new ol.style.Fill({
    color: 'rgba(100, 100, 100, 0.3)',
  }),
  stroke: new ol.style.Stroke({
    color: '#319FD3',
    width: 1,
  }),
});
var labelStyle = new ol.style.Style({
  text: new ol.style.Text({
    font: '12px Calibri,sans-serif',
    fill: new ol.style.Fill({
      color: '#000',
    }),
    stroke: new ol.style.Stroke({
      color: '#fff',
      width: 3,
    }),
    overflow: true,
  }),
});
var style = [countryStyle, labelStyle];

var vectorSource = new ol.source.Vector({
  //url: 'geojson.cgi',
  format: new ol.format.GeoJSON(),
});
var vectorLayer = new ol.layer.Vector({
  source: vectorSource,
  style: function (feature) {
    // place label on biggest polygon only
    var geom = feature.getGeometry();
    if (geom.getType() == 'MultiPolygon') {
      var polys = geom.getPolygons().sort(function(a, b) {
        var areaA = a.getArea();
        var areaB = b.getArea();
        return areaA > areaB ? -1 : areaA < areaB ? 1 : 0;
      });
      labelStyle.setGeometry(polys[0]);
    } else {
      labelStyle.setGeometry(geom);
    }

    // actual label
    var id = feature.get('id');
    var count = feature.get('count');
    if (count > 1) id += "\n" + count;
    labelStyle.getText().setText(id);

    // shape style
    if (color.value == "qsl") {
      if (feature.get('qsl') && feature.get('lotw')) {
        countryStyle.getFill().setColor(pattern(2, all_colors));
      } else if (feature.get('qsl')) {
        countryStyle.getFill().setColor('rgba(0, 0, 200, 0.3)');
      } else if (feature.get('lotw')) {
        countryStyle.getFill().setColor('rgba(0, 200, 0, 0.3)');
      } else {
        countryStyle.getFill().setColor('rgba(100, 100, 100, 0.3)');
      }
    } else if (color.value == "bands") {
      let summaryfeature = vectorSource.getFeatureById('summary');
      let all_bands = summaryfeature.getProperties()['bands'];
      countryStyle.getFill().setColor(make_pattern(all_bands, feature.get('bands')));
    } else if (color.value == "modes") {
      let summaryfeature = vectorSource.getFeatureById('summary');
      let all_modes = summaryfeature.getProperties()['modes'];
      countryStyle.getFill().setColor(make_pattern(all_modes, feature.get('modes')));
    } else if (color.value == "qso_via") {
      let summaryfeature = vectorSource.getFeatureById('summary');
      let all_qso_via = summaryfeature.getProperties()['qso_via'];
      countryStyle.getFill().setColor(make_pattern(all_qso_via, feature.get('qso_via')));
    } else if (color.value == "random") {
      countryStyle.getFill().setColor(random_color());
    } else {
      countryStyle.getFill().setColor('rgba(100, 100, 100, 0.3)');
    }

    return style;
  },
});

// put a "DF7CB" label on the map
var df7cbFeature = new ol.Feature({
  geometry: new ol.geom.Point(ol.proj.fromLonLat([6.5955, 51.3724])),
  id: 'df7cb',
})
var df7cbStyle = new ol.style.Style({
  image: new ol.style.Icon({
    anchor: [2, 2],
    anchorXUnits: 'pixels',
    anchorYUnits: 'pixels',
    src: 'df7cb-marker.png',
  }),
});
df7cbFeature.setStyle(df7cbStyle);
var df7cbLayer = new ol.layer.Vector({
  source: new ol.source.Vector({
    features: [df7cbFeature],
  })
});

// the actual map
var OSMSource = new ol.source.OSM({
  url: 'https://{a-c}.tile.openstreetmap.de/{z}/{x}/{y}.png',
  attributions: [],
});
var map = new ol.Map({
  target: 'map',
  layers: [
    new ol.layer.Tile({ source: OSMSource, }),
    vectorLayer,
    df7cbLayer,
  ],
  view: new ol.View({
    center: ol.proj.fromLonLat([0, 0]),
    zoom: 0,
    projection: ol.proj.get("EPSG:4326"),
  })
});

// highlight on mouse over and click
var highlightCountryStyle = new ol.style.Style({
  stroke: new ol.style.Stroke({
    color: '#f00',
    width: 1,
  }),
  fill: new ol.style.Fill({
    color: 'rgba(255,0,0,0.1)',
  }),
});
var highlightLabelStyle = new ol.style.Style({
  text: new ol.style.Text({
    font: '12px Calibri,sans-serif',
    fill: new ol.style.Fill({
      color: '#000',
    }),
    stroke: new ol.style.Stroke({
      color: '#f00',
      width: 3,
    }),
  }),
});
var highlightStyle = [highlightCountryStyle, highlightLabelStyle];

var featureOverlay = new ol.layer.Vector({
  source: new ol.source.Vector(),
  map: map,
  style: function (feature) {
    var geom = feature.getGeometry();
    if (geom.getType() == 'MultiPolygon') {
      var polys = geom.getPolygons().sort(function(a, b) {
        var areaA = a.getArea();
        var areaB = b.getArea();
        return areaA > areaB ? -1 : areaA < areaB ? 1 : 0;
      });
      highlightLabelStyle.setGeometry(polys[0]);
    } else {
      highlightLabelStyle.setGeometry(geom);
    }

    var id = feature.get('id');
    var count = feature.get('count');
    if (count > 1) id += "\n" + count;
    highlightLabelStyle.getText().setText(id);

    return highlightStyle;
  },
});

var highlight;
var displayFeatureInfo = function (pixel) {
  var feature = map.forEachFeatureAtPixel(pixel, function (feature) {
    if (feature.get('id') !== 'df7cb')
      return feature;
  });

  var info = document.getElementById('info');
  if (feature) {
    var type = document.getElementById('type').value;
    var text = '<b>' + feature.get('id');
    if (feature.get('country')) text += ' ' + feature.get('country');
    text += '</b>: ' + feature.get('count') + ' QSO';
    if (feature.get('qsl')) text += ', confirmed by QSL';
    if (feature.get('lotw')) text += ', confirmed by LoTW';
    text += '<br />';

    if (feature.get('locs')) text += 'Locators: ' + feature.get('locs') + '<br />';
    if (feature.get('ctys')) text += 'Countries: ' + feature.get('ctys') + '<br />';
    text +=
      'Years: ' + feature.get('years') + '<br />' +
      'Modes: ' + feature.get('modes') + '<br />' +
      'Bands: ' + feature.get('bands') + '<br />' +
      'Calls: ' + feature.get('calls');
    if (feature.get('qso_via')) text += '<br />' + 'QSO via: ' + feature.get('qso_via');
    info.innerHTML = text; /*feature.getId() + ': ' +*/
  } else {
    info.innerHTML = '&nbsp;';
  }

  if (feature !== highlight) {
    if (highlight) {
      featureOverlay.getSource().removeFeature(highlight);
    }
    if (feature) {
      featureOverlay.getSource().addFeature(feature);
    }
    highlight = feature;
  }
};

map.on('pointermove', function (evt) {
  if (evt.dragging) {
    return;
  }
  var pixel = map.getEventPixel(evt.originalEvent);
  displayFeatureInfo(pixel);
});

var map_div = document.getElementById('map');
var on_window_resize = function () {
  map.updateSize();
};
new ResizeObserver(on_window_resize).observe(map_div);

//map.on('click', function (evt) {
//  vectorLayer.setSource(new ol.source.Vector({ url: 'geojson.cgi?band=30m', format: new ol.format.GeoJSON() }));
//  displayFeatureInfo(evt.pixel);
//});

// stats widgets /////////////////////////////

Chart.register(ChartDataLabels);
// no legend above the doughnuts
Chart.defaults.plugins.legend.display = false;

var label_formatter = function(value, context) {
  return context.chart.data.labels[context.dataIndex] + "\n" + value;
};

var qsl_config = {
  type: 'doughnut',
  plugins: [ChartDataLabels,
    {
      id: 'my-doughnut-text-plugin',
      afterDraw: function (chart, option) {
        let theCenterText = "QSL" ;
        const canvasBounds = document.getElementById('qsl_stats_canvas').getBoundingClientRect();
        const fontSz = Math.floor( canvasBounds.height * 0.10 ) ;
        chart.ctx.textBaseline = 'middle';
        chart.ctx.textAlign = 'center';
        chart.ctx.font = fontSz+'px Arial';
        chart.ctx.fillText(theCenterText, canvasBounds.width/2, canvasBounds.height*.5 )
      }
    }
  ],
  options: {
    responsive: false,
    plugins: {
      datalabels: {
        formatter: label_formatter,
      },
    },
  },
};
var qsl_stats_widget = new Chart(document.getElementById('qsl_stats_canvas'), qsl_config);

var band_config = {
  type: 'doughnut',
  plugins: [ChartDataLabels,
    {
      id: 'my-doughnut-text-plugin',
      afterDraw: function (chart, option) {
        let theCenterText = "Bands" ;
        const canvasBounds = document.getElementById('band_stats_canvas').getBoundingClientRect();
        const fontSz = Math.floor( canvasBounds.height * 0.10 ) ;
        chart.ctx.textBaseline = 'middle';
        chart.ctx.textAlign = 'center';
        chart.ctx.font = fontSz+'px Arial';
        chart.ctx.fillText(theCenterText, canvasBounds.width/2, canvasBounds.height*.5 )
      }
    }
  ],
  options: {
    responsive: false,
    plugins: {
      datalabels: {
        formatter: label_formatter,
      },
    },
  },
};
var band_stats_widget = new Chart(document.getElementById('band_stats_canvas'), band_config);

var mode_config = {
  type: 'doughnut',
  plugins: [ChartDataLabels,
    {
      id: 'my-doughnut-text-plugin',
      afterDraw: function (chart, option) {
        let theCenterText = "Modes" ;
        const canvasBounds = document.getElementById('mode_stats_canvas').getBoundingClientRect();
        const fontSz = Math.floor( canvasBounds.height * 0.10 ) ;
        chart.ctx.textBaseline = 'middle';
        chart.ctx.textAlign = 'center';
        chart.ctx.font = fontSz+'px Arial';
        chart.ctx.fillText(theCenterText, canvasBounds.width/2, canvasBounds.height*.5 )
      }
    }
  ],
  options: {
    responsive: false,
    plugins: {
      datalabels: {
        formatter: label_formatter,
      },
    },
  },
};
var mode_stats_widget = new Chart(document.getElementById('mode_stats_canvas'), mode_config);

var update_stats = function(stats) {
  const qsl_data = {
    labels: Object.keys(stats['qsls']),
    datasets: [{
      label: 'QSL',
      data: Object.values(stats['qsls']),
      backgroundColor: all_colors,
    }]
  };
  const band_data = {
    labels: Object.keys(stats['bands']),
    datasets: [{
      label: 'Bands',
      data: Object.values(stats['bands']),
      backgroundColor: all_colors,
    }]
  };
  const mode_data = {
    labels: Object.keys(stats['modes']),
    datasets: [{
      label: 'Modes',
      data: Object.values(stats['modes']),
      backgroundColor: all_colors,
    }]
  };
  qsl_stats_widget.data = qsl_data;
  qsl_stats_widget.update();
  band_stats_widget.data = band_data;
  band_stats_widget.update();
  mode_stats_widget.data = mode_data;
  mode_stats_widget.update();
}

// update log when geojson is received //////////////////////

var log_update = function (evt) {
  // summary /////////////////
  var summary = document.getElementById('summary');
  let summaryfeature = vectorSource.getFeatureById('summary');
  if (!summaryfeature) return;
  let properties = summaryfeature.getProperties();

  summary.innerHTML = "<b>Log:</b> " + properties['count'] + " QSO<br />\n";
  if (properties['countries']) {
    let c = properties['countries'].length;
    summary.innerHTML += c + " countries: " + properties['countries'].join(' ') + "<br />";
  }
  if (properties['locs']) {
    let c = properties['locs'].length;
    summary.innerHTML += c + " locators";
    if (c <= 100)
      summary.innerHTML += ": " + properties['locs'].join(' ');
    summary.innerHTML += "<br />";
  }
  summary.innerHTML +=
    "Years: " + properties['years'] + "<br />" +
    "Modes: " + properties['modes'] + "<br />" +
    "Bands: " + properties['bands'];
  if (properties['qso_via'])
    summary.innerHTML += "<br />" + "QSO via: " + properties['qso_via'].join(' ');

  // put legend into map attribution (bottom right corner)
  let attributions = [];
  let legend_items = [];
  if (color.value == "qsl") {
    attributions = ['Confirmed by'];
    legend_items = ['QSL', 'LoTW'];
  } else if (color.value == "bands" && properties['bands']) {
    attributions = ['Band'];
    legend_items = properties['bands'];
  } else if (color.value == "modes" && properties['modes']) {
    attributions = ['Mode'];
    legend_items = properties['modes'];
  } else if (color.value == "qso_via" && properties['qso_via']) {
    attributions = ['QSO via'];
    legend_items = properties['qso_via'];
  }
  for (let i = 0; i < legend_items.length; i++) {
    attributions.push('<span style="background: ' + all_colors[i % all_colors.length] + '">&nbsp;' + legend_items[i] + '&nbsp;</span>');
  }
  attributions.push(ol.source.OSM.ATTRIBUTION);
  OSMSource.setAttributions(attributions); // attach to OSMSource so we don't trigger infinite recursion on vectorSource

  // stats /////////////////
  let statsfeature = vectorSource.getFeatureById('stats');
  if (statsfeature) {
    let stats = statsfeature.getProperties();
    if (stats)
      update_stats(stats);
  }

  // log /////////////////
  let logfeature = vectorSource.getFeatureById('log');
  if (!logfeature)
    return;
  let qsos = logfeature.getProperties()['qso'];
  if (!qsos)
    return;

  while (logTable.rows.length > 1)
    logTable.deleteRow(1);

  for (qso of qsos) {
    let row = logTable.insertRow();
    for (field of ['mycall', 'start', 'call', 'cty', 'mode', 'qrg', 'rsttx', 'rstrx', 'loc', 'qsl', 'lotw', 'contest', 'qso_via']) {
      let cell = row.insertCell();
      let inner;
      if (qso[field]) {
        if (field == "loc") {
          inner = document.createElement('a')
          inner.innerHTML = qso[field];
          inner.href = "https://k7fry.com/grid/?qth=" + qso[field];
          inner.title = "Show locator grid on external map";
        } else {
          inner = document.createTextNode(qso[field]);
        }
      } else
        inner = document.createTextNode('');
      cell.appendChild(inner);
    }
  }
};
vectorSource.addEventListener('change', log_update);

// main //////////////////////////////////////////////////////

var start_notifier = function () {
  notifier = new WebSocket('wss://www.df7cb.de/df7cb/log/log_update');
  notifier.onmessage = map_update;
  notifier.onclose = start_notifier;
}

var main = function (data) { // called when log info has been received
  populate_dropdowns(data);
  update_menus_from_url();
  map_update();

  type.addEventListener('change', map_update);
  band.addEventListener('change', map_update);
  call.addEventListener('change', map_update);
  contest.addEventListener('change', map_update);
  color.addEventListener('change', map_update);
  mode.addEventListener('change', map_update);
  mycall.addEventListener('change', map_update);
  time.addEventListener('change', map_update);

  start_notifier();
};

send_loginfo_request(main);
