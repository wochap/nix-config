pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

// Materializes notification images to stable files under the XDG cache dir so
// they survive shell reloads and history restore.
//
// `notification.image` can be one of:
//   - a local, remote, or relative URL -> rasterized into the cache
//   - image://<runtime-provider>/...   -> in-memory/provider pixels, rasterized into the cache
//   - data:image/...                   -> embedded pixels, rasterized into the cache
//   - image://icon/<name>              -> themed icon, already persistent, left untouched
//   - ""                               -> nothing to do
Singleton {
  id: root

  readonly property string cacheDir: Paths.strip(Paths.notificationsimageCache)
  readonly property string indexPath: `${root.cacheDir}/index.json`

  // Persisted source string -> stable cached file:// URL.
  property var cacheMap: ({})
  // Sources requested before the persistent index has finished loading.
  property var pendingSources: []
  // Sources currently being rasterized. Incomplete jobs are never persisted.
  property var inFlight: ({})
  property int pendingJobCount: 0
  property bool indexReady: false
  // image://qsimage sources awaiting a grab (serialized through grabImage)
  property var grabQueue: []
  property bool grabBusy: false
  property var currentGrabJob: null
  property bool cacheDirReady: false
  property var cleanupQueue: []
  property var currentCleanupJob: null
  property bool cleanupBusy: false

  // Emitted once `source` has been materialized to a cached file.
  signal cached(source: string, url: string)

  readonly property var imageExtensions: ["png", "jpg", "jpeg", "gif", "webp", "bmp", "svg", "ico", "tiff", "tif", "avif"]
  readonly property int maxImageSize: 100

  Component.onCompleted: {
    cacheDirProcess.exec(["mkdir", "-p", root.cacheDir]);
  }

  // djb2 + sdbm combined into a 16-char hex digest.
  function hashString(str: string): string {
    let h1 = 5381;
    let h2 = 0;
    for (let i = 0; i < str.length; i++) {
      const c = str.charCodeAt(i);
      h1 = ((h1 << 5) + h1 + c) >>> 0;
      h2 = (c + (h2 << 6) + (h2 << 16) - h2) >>> 0;
    }
    return h1.toString(16).padStart(8, "0") + h2.toString(16).padStart(8, "0");
  }

  function extensionOf(path: string): string {
    const clean = path.split("?")[0].split("#")[0];
    const dot = clean.lastIndexOf(".");
    const slash = clean.lastIndexOf("/");
    if (dot === -1 || dot < slash)
      return "";
    return clean.slice(dot + 1).toLowerCase();
  }

  function isImageExtension(ext: string): bool {
    return root.imageExtensions.includes(ext);
  }

  // Returns a stable cached file:// url for `source`, materializing it if needed.
  // Returns "" when there is nothing to cache, and `source` unchanged when it is
  // already stable (themed icon, already cached, or an in-memory grab still pending).
  function cache(source: string): string {
    if (!source || source === "")
      return "";

    if (!root.indexReady) {
      if (!root.pendingSources.includes(source))
        root.pendingSources.push(source);
      return source;
    }

    if (root.cacheMap[source])
      return root.cacheMap[source];

    if (root.inFlight[source])
      return source;

    // already one of our cached files
    if (source.startsWith(`${root.cacheDir}/`) || source.startsWith(`file://${root.cacheDir}/`))
      return source;

    if (root.isCacheable(source)) {
      root.enqueueGrab(source);
      return source;
    }

    // themed icon (name or image://icon/ url) or unrecognized: nothing to cache
    return source;
  }

  function isFilePath(source: string): bool {
    return source.startsWith("/") || source.startsWith("file:");
  }

  function isCacheable(source: string): bool {
    // Theme icons are stable symbolic references. Other image providers are
    // assumed to be runtime-owned and therefore unsafe to persist directly.
    if (source.startsWith("image://icon/"))
      return false;
    if (source.startsWith("image://") || source.startsWith("data:image/"))
      return true;
    if (source.startsWith("http://") || source.startsWith("https://") || root.isFilePath(source))
      return true;
    // Other schemes include persistent providers such as image://icon and
    // resources such as root:/ and qrc:/.
    if (source.includes(":"))
      return false;
    // A slash, ./ or ../, or a known extension distinguishes a relative path
    // from an icon-theme name such as "firefox".
    return source.startsWith("./") || source.startsWith("../") || source.includes("/") || root.isImageExtension(root.extensionOf(source));
  }

  function loadUrl(source: string): string {
    if (source.startsWith("./") || source.startsWith("../") || (!source.includes(":") && !source.startsWith("/")))
      return `file://${Quickshell.workingDirectory}/${source}`;
    return source;
  }

  function enqueueGrab(source: string) {
    root.inFlight[source] = true;
    root.pendingJobCount++;
    root.grabQueue.push({
      "source": source,
      "loadUrl": root.loadUrl(source)
    });
    root.processGrabQueue();
  }

  function processGrabQueue() {
    if (!root.cacheDirReady || root.grabBusy || root.grabQueue.length === 0)
      return;
    root.grabBusy = true;
    root.currentGrabJob = root.grabQueue.shift();
    grabImage.source = root.currentGrabJob.loadUrl;
  }

  function finishGrab() {
    root.pendingJobCount = Math.max(0, root.pendingJobCount - 1);
    root.grabBusy = false;
    root.currentGrabJob = null;
    grabImage.source = "";
    root.processGrabQueue();
  }

  function finishIndexLoad(entries: var) {
    root.cacheMap = entries ?? {};
    root.indexReady = true;
    const sources = root.pendingSources;
    root.pendingSources = [];
    sources.forEach(source => {
      const cachedUrl = root.cache(source);
      // Consumers are still holding the original while the index loads. Notify
      // them immediately when the persistent index already has the answer.
      if (cachedUrl !== source)
        root.cached(source, cachedUrl);
    });
  }

  function saveIndex() {
    if (root.indexReady && root.cacheDirReady)
      cacheIndexFile.setText(JSON.stringify(root.cacheMap, null, 2));
  }

  // Remove completed cache entries that are not referenced by any live
  // notification. Both file:// URLs and plain app-icon paths are accepted.
  function cleanup(usedUrls: var) {
    const usedPaths = {};
    usedUrls.forEach(url => {
      if (url)
        usedPaths[Paths.strip(url)] = true;
    });

    Object.keys(root.cacheMap).forEach(source => {
      const cachedUrl = root.cacheMap[source];
      const cachedPath = Paths.strip(cachedUrl);
      if (usedPaths[cachedPath])
        return;
      // Never allow a malformed or edited index to delete outside our cache.
      if (!cachedPath.startsWith(`${root.cacheDir}/`) || !cachedPath.endsWith(".png"))
        return;
      if (root.cleanupQueue.some(job => job.source === source) || root.currentCleanupJob?.source === source)
        return;
      root.cleanupQueue.push({
        "source": source,
        "path": cachedPath
      });
    });
    root.processCleanupQueue();
  }

  function processCleanupQueue() {
    if (root.cleanupBusy || root.cleanupQueue.length === 0)
      return;
    root.cleanupBusy = true;
    root.currentCleanupJob = root.cleanupQueue.shift();
    cleanupProcess.exec(["rm", "-f", "--", root.currentCleanupJob.path]);
  }

  Process {
    id: cacheDirProcess

    onExited: {
      root.cacheDirReady = exitCode === 0;
      if (root.cacheDirReady) {
        if (root.indexReady)
          root.saveIndex();
        root.processGrabQueue();
      }
    }
  }

  Process {
    id: cleanupProcess

    onExited: {
      const job = root.currentCleanupJob;
      if (job && exitCode === 0 && root.cacheMap[job.source] && Paths.strip(root.cacheMap[job.source]) === job.path) {
        delete root.cacheMap[job.source];
        root.saveIndex();
      }
      root.currentCleanupJob = null;
      root.cleanupBusy = false;
      root.processCleanupQueue();
    }
  }

  FileView {
    id: cacheIndexFile

    path: Qt.resolvedUrl(root.indexPath)

    onLoaded: {
      try {
        root.finishIndexLoad(JSON.parse(cacheIndexFile.text()));
      } catch (error) {
        console.warn(`Failed to parse image cache index: ${error}`);
        root.finishIndexLoad({});
      }
    }

    onLoadFailed: error => {
      if (error !== FileViewError.FileNotFound)
        console.warn(`Failed to load image cache index: ${error}`);
      root.finishIndexLoad({});
    }
  }

  // Offscreen rasterizer shared by local, remote, and in-memory images.
  Image {
    id: grabImage

    visible: false
    width: 1
    height: 1
    fillMode: Image.PreserveAspectFit

    onStatusChanged: {
      if (grabImage.status === Image.Error) {
        if (root.currentGrabJob)
          delete root.inFlight[root.currentGrabJob.source];
        root.finishGrab();
        return;
      }
      if (grabImage.status !== Image.Ready)
        return;

      const job = root.currentGrabJob;
      if (!job)
        return;
      const source = job.source;
      const destPath = `${root.cacheDir}/${root.hashString(source)}.png`;
      const destUrl = `file://${destPath}`;
      const sourceWidth = grabImage.implicitWidth;
      const sourceHeight = grabImage.implicitHeight;
      const scale = Math.min(1, root.maxImageSize / Math.max(sourceWidth, sourceHeight));
      grabImage.width = Math.max(1, Math.round(sourceWidth * scale));
      grabImage.height = Math.max(1, Math.round(sourceHeight * scale));
      const size = Qt.size(grabImage.width, grabImage.height);
      Qt.callLater(() => {
        grabImage.grabToImage(result => {
          if (result.saveToFile(destPath)) {
            root.cacheMap[source] = destUrl;
            delete root.inFlight[source];
            root.saveIndex();
            root.cached(source, destUrl);
          } else {
            delete root.inFlight[source];
          }
          root.finishGrab();
        }, size);
      });
    }
  }
}
