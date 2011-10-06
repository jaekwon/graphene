exports.template = ->

  div '#chart.gallary', ->

  link type: "text/css", rel: "stylesheet", href: "/static/colorbrewer.css"
  style type: "text/css", ->
    '''
#chart {
  font: 10px sans-serif;
}

.day {
  fill: #fff;
  stroke: #ccc;
  shape-rendering: crispEdges;
}

.month {
  fill: none;
  stroke: #000;
  stroke-width: 2px;
  shape-rendering: crispEdges;
}
'''
  script type: "text/javascript", src: "/static/d3.js"
  script type: "text/javascript", src: "/static/d3.time.js"
  script type: "text/javascript", src: "/static/d3.csv.js"
  script type: "text/javascript", ->
    '''
var calendar = {

  format: d3.time.format("%Y-%m-%d"),

  dates: function(year) {
    var dates = [],
        date = new Date(year, 0, 1),
        week = 0,
        day;
    do {
      dates.push({
        day: day = date.getDay(),
        week: week,
        month: date.getMonth(),
        Date: calendar.format(date)
      });
      date.setDate(date.getDate() + 1);
      if (day === 6) week++;
    } while (date.getFullYear() === year);
    return dates;
  },

  months: function(year) {
    var months = [],
        date = new Date(year, 0, 1),
        month,
        firstDay,
        firstWeek,
        day,
        week = 0;
    do {
      firstDay = date.getDay();
      firstWeek = week;
      month = date.getMonth();
      do {
        day = date.getDay();
        if (day === 6) week++;
        date.setDate(date.getDate() + 1);
      } while (date.getMonth() === month);
      months.push({
        firstDay: firstDay,
        firstWeek: firstWeek,
        lastDay: day,
        lastWeek: day === 6 ? week - 1 : week
      });
    } while (date.getFullYear() === year);
    return months;
  }

};


var w = 960,
    pw = 14,
    z = ~~((w - pw * 2) / 53),
    ph = z >> 1,
    h = z * 7;

var vis = d3.select("#chart")
  .selectAll("svg")
    .data(d3.range(1990, 2011))
  .enter().append("svg:svg")
    .attr("width", w)
    .attr("height", h + ph * 2)
    .attr("class", "RdYlGn")
  .append("svg:g")
    .attr("transform", "translate(" + pw + "," + ph + ")");

vis.append("svg:text")
    .attr("transform", "translate(-6," + h / 2 + ")rotate(-90)")
    .attr("text-anchor", "middle")
    .text(function(d) { return d; });

vis.selectAll("rect.day")
    .data(calendar.dates)
  .enter().append("svg:rect")
    .attr("x", function(d) { return d.week * z; })
    .attr("y", function(d) { return d.day * z; })
    .attr("class", "day")
    .attr("width", z)
    .attr("height", z);

vis.selectAll("path.month")
    .data(calendar.months)
  .enter().append("svg:path")
    .attr("class", "month")
    .attr("d", function(d) {
      return "M" + (d.firstWeek + 1) * z + "," + d.firstDay * z
          + "H" + d.firstWeek * z
          + "V" + 7 * z
          + "H" + d.lastWeek * z
          + "V" + (d.lastDay + 1) * z
          + "H" + (d.lastWeek + 1) * z
          + "V" + 0
          + "H" + (d.firstWeek + 1) * z
          + "Z";
    });

d3.csv("/static/dji.csv", function(csv) {
  var data = d3.nest()
      .key(function(d) { return d.Date; })
      .rollup(function(d) { return (d[0].Close - d[0].Open) / d[0].Open; })
      .map(csv);

  var color = d3.scale.quantize()
      .domain([-.05, .05])
      .range(d3.range(9));

  vis.selectAll("rect.day")
      .attr("class", function(d) { return "day q" + color(data[d.Date]) + "-9"; })
    .append("svg:title")
      .text(function(d) { return d.Date + ": " + (data[d.Date] * 100).toFixed(1) + "%"; });
});


'''
  div '.foo', ->
    "tis working!"

exports.coffeescript = ->
  console.log "tis working!"
