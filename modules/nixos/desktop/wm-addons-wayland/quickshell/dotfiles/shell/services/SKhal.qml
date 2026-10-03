pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Calendar events from khal.
// khal only parses its own date formats on the command line, so a copy of the
// user config with an ISO `longdateformat` is used for every query.
Singleton {
  id: root

  readonly property int refreshInterval: 5 * 60 * 1000
  readonly property int upcomingDays: 30
  readonly property int upcomingCount: 3
  readonly property var fields: ["title", "start-date-long", "start-time", "end-date-long", "end-time", "all-day", "calendar-color"]

  // "yyyy-MM-dd" -> [color, ...] for the range passed to loadRange()
  property var eventsByDay: ({})
  // [{title, start: Date, allDay, color}]
  property var upcoming: []
  property date rangeStart: new Date()
  property date rangeEnd: new Date()
  property bool available: true

  function dayKey(date) {
    return Qt.formatDate(date, "yyyy-MM-dd");
  }

  function addDays(date, days) {
    const d = new Date(date.getFullYear(), date.getMonth(), date.getDate());
    d.setDate(d.getDate() + days);
    return d;
  }

  // Map an arbitrary calendar color onto the nearest palette accent by hue
  function paletteColor(raw) {
    const accents = ["red", "peach", "yellow", "green", "teal", "sky", "sapphire", "blue", "lavender", "mauve", "pink"];
    if (!raw || raw.length < 7)
      return Theme.options.blue;
    const hue = Qt.color(raw.slice(0, 7)).hslHue;
    if (hue < 0)
      return Theme.options.overlay1;
    let best = accents[0];
    let bestDistance = 2;
    for (const name of accents) {
      const h = Qt.color(Theme.options[name]).hslHue;
      const diff = Math.abs(h - hue);
      const distance = Math.min(diff, 1 - diff);
      if (distance < bestDistance) {
        bestDistance = distance;
        best = name;
      }
    }
    return Theme.options[best];
  }

  function parseDate(isoDate, time) {
    const [y, m, d] = isoDate.split("-").map(Number);
    const [hh, mm] = time ? time.split(":").map(Number) : [0, 0];
    return new Date(y, m - 1, d, hh, mm);
  }

  // khal prints one JSON array per day of the range, starting at `start`
  function parseDays(text, start, onEvent) {
    const lines = text.split("\n").filter(line => line.trim().length > 0);
    lines.forEach((line, i) => {
      let events = [];
      try {
        events = JSON.parse(line);
      } catch (e) {
        return;
      }
      const day = root.addDays(start, i);
      events.forEach(event => onEvent(day, event));
    });
  }

  function loadRange(start, end) {
    root.rangeStart = start;
    root.rangeEnd = end;
    rangeProcess.running = false;
    rangeProcess.command = root.command(start, end);
    rangeProcess.running = true;
  }

  function refresh() {
    const today = new Date();
    upcomingProcess.running = false;
    upcomingProcess.command = root.command(today, root.addDays(today, root.upcomingDays));
    upcomingProcess.running = true;
    root.loadRange(root.rangeStart, root.rangeEnd);
  }

  function command(start, end) {
    const json = [];
    root.fields.forEach(field => json.push("--json", field));
    const script = 'conf="$(mktemp)"; ' + "sed -E 's/^([[:space:]]*longdateformat[[:space:]]*=).*/\\1 %Y-%m-%d/' \"${XDG_CONFIG_HOME:-$HOME/.config}/khal/config\" > \"$conf\"; " + 'khal -c "$conf" list "$@"; status=$?; rm -f "$conf"; exit $status';
    return ["sh", "-c", script, "khal", ...json, root.dayKey(start), root.dayKey(end)];
  }

  Process {
    id: rangeProcess

    stdout: StdioCollector {
      id: rangeCollector

      onStreamFinished: {
        const byDay = {};
        root.parseDays(rangeCollector.text, root.rangeStart, (day, event) => {
          const key = root.dayKey(day);
          byDay[key] = byDay[key] ?? [];
          byDay[key].push(root.paletteColor(event["calendar-color"]));
        });
        root.eventsByDay = byDay;
      }
    }
    onExited: code => root.available = code === 0
  }

  Process {
    id: upcomingProcess

    stdout: StdioCollector {
      id: upcomingCollector

      onStreamFinished: {
        const now = new Date();
        const seen = new Set();
        const list = [];
        root.parseDays(upcomingCollector.text, now, (day, event) => {
          const allDay = event["all-day"] === "True";
          const start = root.parseDate(event["start-date-long"], allDay ? "" : event["start-time"]);
          const end = allDay ? root.addDays(root.parseDate(event["end-date-long"], ""), 1) : root.parseDate(event["end-date-long"], event["end-time"]);
          const id = `${event.title}_${event["start-date-long"]}_${event["start-time"]}`;
          if (end <= now || seen.has(id))
            return;
          seen.add(id);
          list.push({
            title: event.title,
            start,
            allDay,
            color: root.paletteColor(event["calendar-color"])
          });
        });
        root.upcoming = list.sort((a, b) => a.start - b.start).slice(0, root.upcomingCount);
      }
    }
  }

  Timer {
    interval: root.refreshInterval
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  // Event colors are derived from the palette
  Connections {
    target: Theme

    function onChanged() {
      root.refresh();
    }
  }
}
