pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Weather from open-meteo.com.
// Location comes from the sops secret `personal-weather-location` ("lat,lon,City"),
// otherwise from IP geolocation (cached for 24h).
Singleton {
  id: root

  readonly property string secretPath: "/run/secrets/personal-weather-location"
  readonly property string weatherCachePath: `${Paths.strip(Paths.cache)}/weather.json`
  readonly property string locationCachePath: `${Paths.strip(Paths.cache)}/weather-location.json`
  readonly property int refreshInterval: 15 * 60 * 1000
  readonly property int locationMaxAge: 24 * 60 * 60 * 1000
  readonly property int forecastDays: 5

  // {lat, lon, city, source: "secret" | "ip"}
  property var location: null
  // {temperature, feelsLike, code, isDay, humidity, precipitation, wind, icon, iconColor, description}
  property var current: null
  // [{date, code, max, min, icon, iconColor}]
  property var daily: []
  property double fetchedAt: 0
  property bool loading: false
  property string error: ""
  readonly property bool available: root.current !== null
  readonly property string city: (root.location ?? root.cachedLocation)?.city ?? ""

  property int failures: 0
  property bool secretChecked: false
  // location the cached weather was fetched for
  property var cachedLocation: null

  // WMO weather interpretation codes, see https://open-meteo.com/en/docs
  function describe(code) {
    switch (code) {
    case 0:
      return "Clear sky";
    case 1:
      return "Mainly clear";
    case 2:
      return "Partly cloudy";
    case 3:
      return "Overcast";
    case 45:
    case 48:
      return "Fog";
    case 51:
    case 53:
    case 55:
      return "Drizzle";
    case 56:
    case 57:
      return "Freezing drizzle";
    case 61:
    case 63:
    case 65:
      return "Rain";
    case 66:
    case 67:
      return "Freezing rain";
    case 71:
    case 73:
    case 75:
    case 77:
      return "Snow";
    case 80:
    case 81:
    case 82:
      return "Rain showers";
    case 85:
    case 86:
      return "Snow showers";
    case 95:
      return "Thunderstorm";
    case 96:
    case 99:
      return "Thunderstorm, hail";
    default:
      return "Unknown";
    }
  }

  function icon(code, isDay) {
    switch (code) {
    case 0:
    case 1:
      return isDay ? "clear_day" : "clear_night";
    case 2:
      return isDay ? "partly_cloudy_day" : "partly_cloudy_night";
    case 3:
      return "cloud";
    case 45:
    case 48:
      return "foggy";
    case 71:
    case 73:
    case 77:
    case 85:
      return "cloudy_snowing";
    case 75:
    case 86:
      return "weather_snowy";
    case 95:
    case 96:
    case 99:
      return "thunderstorm";
    default:
      if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82))
        return "rainy";
      return "cloud";
    }
  }

  function iconColor(code, isDay) {
    if (code <= 2)
      return isDay ? Theme.options.yellow : Theme.options.lavender;
    if (code === 3)
      return Theme.options.overlay2;
    if (code === 45 || code === 48)
      return Theme.options.overlay1;
    if ((code >= 71 && code <= 77) || code === 85 || code === 86)
      return Theme.options.sky;
    if (code >= 95)
      return Theme.options.mauve;
    return Theme.options.blue;
  }

  function refresh() {
    if (root.location) {
      root.fetchWeather();
    } else {
      root.resolveLocation();
    }
  }

  function request(url, onSuccess, onError) {
    const xhr = new XMLHttpRequest();
    xhr.onreadystatechange = () => {
      if (xhr.readyState !== XMLHttpRequest.DONE)
        return;
      if (xhr.status >= 200 && xhr.status < 300) {
        try {
          onSuccess(JSON.parse(xhr.responseText));
        } catch (e) {
          onError(`invalid response from ${url}: ${e}`);
        }
      } else {
        onError(`${url} returned ${xhr.status}`);
      }
    };
    xhr.open("GET", url);
    xhr.send();
  }

  function scheduleRetry(message) {
    console.warn(`SWeather: ${message}`);
    root.error = message;
    root.loading = false;
    root.failures += 1;
    // 30s, 60s, 120s, ... capped at 5 minutes
    refreshTimer.interval = Math.min(30000 * Math.pow(2, root.failures - 1), 300000);
    refreshTimer.restart();
  }

  function setLocation(lat, lon, city, source) {
    root.location = {
      lat: Number(lat),
      lon: Number(lon),
      city: city ?? "",
      source
    };
    const cached = root.cachedLocation;
    const sameLocation = cached && Math.abs(cached.lat - root.location.lat) < 0.01 && Math.abs(cached.lon - root.location.lon) < 0.01;
    const age = Date.now() - root.fetchedAt;
    if (sameLocation && age < root.refreshInterval) {
      // cache is fresh, wait for it to expire
      refreshTimer.interval = root.refreshInterval - age;
      refreshTimer.restart();
    } else {
      root.fetchWeather();
    }
  }

  function resolveLocation() {
    if (!root.secretChecked)
      return; // secretFile callbacks call back into resolveLocation

    // IP geolocation, cached for 24h
    const cached = locationCache.text().trim();
    if (cached.length > 0) {
      try {
        const data = JSON.parse(cached);
        if (Date.now() - data.fetchedAt < root.locationMaxAge) {
          root.setLocation(data.lat, data.lon, data.city, "ip");
          return;
        }
      } catch (e) {}
    }

    root.loading = true;
    const save = (lat, lon, city) => {
      locationCache.setText(JSON.stringify({
        lat,
        lon,
        city,
        fetchedAt: Date.now()
      }));
      root.setLocation(lat, lon, city, "ip");
    };
    root.request("https://ipapi.co/json/", data => {
      if (data.latitude === undefined)
        throw new Error("no coordinates");
      save(data.latitude, data.longitude, data.city);
    }, () => {
      root.request("http://ip-api.com/json/", data => {
        if (data.status !== "success")
          throw new Error(data.message);
        save(data.lat, data.lon, data.city);
      }, err => root.scheduleRetry(`location lookup failed: ${err}`));
    });
  }

  function fetchWeather() {
    const loc = root.location;
    root.loading = true;
    const url = "https://api.open-meteo.com/v1/forecast" + `?latitude=${loc.lat}&longitude=${loc.lon}` + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,precipitation_probability,weather_code,is_day,wind_speed_10m" + "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max" + `&timezone=auto&forecast_days=${root.forecastDays}`;
    root.request(url, data => {
      root.apply(data, Date.now());
      root.failures = 0;
      root.error = "";
      root.loading = false;
      refreshTimer.interval = root.refreshInterval;
      refreshTimer.restart();
      weatherCache.setText(JSON.stringify({
        fetchedAt: root.fetchedAt,
        location: root.location,
        data
      }));
    }, err => root.scheduleRetry(`weather fetch failed: ${err}`));
  }

  function apply(data, fetchedAt) {
    const c = data.current;
    const isDay = c.is_day === 1;
    root.current = {
      temperature: Math.round(c.temperature_2m),
      feelsLike: Math.round(c.apparent_temperature),
      code: c.weather_code,
      isDay,
      humidity: c.relative_humidity_2m,
      precipitation: c.precipitation_probability ?? data.daily?.precipitation_probability_max?.[0] ?? 0,
      wind: Math.round(c.wind_speed_10m),
      icon: root.icon(c.weather_code, isDay),
      iconColor: root.iconColor(c.weather_code, isDay),
      description: root.describe(c.weather_code)
    };
    const d = data.daily;
    root.daily = d.time.map((date, i) => ({
          date: new Date(`${date}T00:00:00`),
          code: d.weather_code[i],
          max: Math.round(d.temperature_2m_max[i]),
          min: Math.round(d.temperature_2m_min[i]),
          icon: root.icon(d.weather_code[i], true),
          iconColor: root.iconColor(d.weather_code[i], true)
        }));
    root.fetchedAt = fetchedAt;
  }

  // Theme colors are baked into current/daily, recompute them on theme change
  Connections {
    target: Theme

    function onChanged() {
      const cached = weatherCache.text().trim();
      if (cached.length === 0)
        return;
      try {
        const c = JSON.parse(cached);
        root.apply(c.data, c.fetchedAt);
      } catch (e) {}
    }
  }

  FileView {
    id: secretFile

    path: root.secretPath
    printErrors: false
    onLoaded: {
      root.secretChecked = true;
      const parts = secretFile.text().trim().split(",");
      const lat = parseFloat(parts[0]);
      const lon = parseFloat(parts[1]);
      if (parts.length >= 2 && !isNaN(lat) && !isNaN(lon)) {
        root.setLocation(lat, lon, parts.slice(2).join(",").trim(), "secret");
      } else {
        console.warn(`SWeather: ${root.secretPath} is not "lat,lon,City", falling back to IP geolocation`);
        root.resolveLocation();
      }
    }
    onLoadFailed: () => {
      root.secretChecked = true;
      root.resolveLocation();
    }
  }

  FileView {
    id: locationCache

    path: root.locationCachePath
    blockLoading: true
    printErrors: false
  }

  FileView {
    id: weatherCache

    path: root.weatherCachePath
    blockLoading: true
    printErrors: false
    onLoaded: {
      const cached = weatherCache.text().trim();
      if (cached.length === 0)
        return;
      try {
        const c = JSON.parse(cached);
        root.apply(c.data, c.fetchedAt);
        root.cachedLocation = c.location;
      } catch (e) {}
    }
  }

  Timer {
    id: refreshTimer

    interval: root.refreshInterval
    onTriggered: root.refresh()
  }
}
