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
//   - a real file path / file:// url   -> copied into the cache
//   - image://qsimage/<n>/<m>          -> in-memory decoded pixels, rasterized to disk via a grab
//   - image://icon/<name>              -> themed icon, already persistent, left untouched
//   - ""                               -> nothing to do
Singleton {
  id: root

  readonly property string cacheDir: Paths.strip(Paths.notificationsimageCache)

  // source string -> stable cached file:// url
  property var cacheMap: ({})
  // image://qsimage sources awaiting a grab (serialized through grabImage)
  property var grabQueue: []
  property bool grabBusy: false
  property string currentGrabSource: ""
  // file copies awaiting completion (serialized through copyProcess)
  property var copyQueue: []
  property bool copyBusy: false
  property var currentCopyJob: null

  // Emitted once `source` has been materialized to a cached file.
  signal cached(source: string, url: string)

  readonly property var imageExtensions: ["png", "jpg", "jpeg", "gif", "webp", "bmp", "svg", "ico", "tiff", "tif", "avif",]

  // Copies create the dir themselves (install -D); this only covers the grab path,
  // whose saveToFile cannot create directories.
  Component.onCompleted: {
    Quickshell.execDetached(["mkdir", "-p", root.cacheDir]);
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

    if (root.cacheMap[source])
      return root.cacheMap[source];

    // already one of our cached files
    if (source.startsWith(`${root.cacheDir}/`) || source.startsWith(`file://${root.cacheDir}/`))
      return source;

    if (source.startsWith("image://qsimage/") || source.startsWith("image://qspixmap/")) {
      root.enqueueGrab(source);
      return source;
    }

    if (root.isFilePath(source))
      return root.cacheFile(source);

    // themed icon (name or image://icon/ url) or unrecognized: nothing to cache
    return source;
  }

  function isFilePath(source: string): bool {
    return source.startsWith("/") || source.startsWith("file:");
  }

  // True only for a real file path that points at a recognizable image format.
  // Used to decide whether an appIcon (which may also be a themed icon name) is
  // worth caching.
  function isImagePath(source: string): bool {
    return root.isFilePath(source) && root.isImageExtension(root.extensionOf(Paths.strip(source)));
  }

  // Queue a copy and return the eventual cached url. `cached()` fires only once
  // the file is actually on disk, so consumers can switch to it race-free (the
  // source is often an ephemeral temp file the sender deletes right after).
  function cacheFile(source: string): string {
    const srcPath = Paths.strip(source);
    const ext = root.extensionOf(srcPath);
    const destExt = root.isImageExtension(ext) ? ext : "png";
    const destPath = `${root.cacheDir}/${root.hashString(srcPath)}.${destExt}`;
    const destUrl = `file://${destPath}`;
    root.cacheMap[source] = destUrl;
    root.copyQueue.push({
      "source": source,
      "srcPath": srcPath,
      "destPath": destPath,
      "destUrl": destUrl
    });
    root.processCopyQueue();
    return destUrl;
  }

  function processCopyQueue() {
    if (root.copyBusy || root.copyQueue.length === 0)
      return;
    root.copyBusy = true;
    root.currentCopyJob = root.copyQueue.shift();
    const job = root.currentCopyJob;
    // install -D creates any missing parent dirs and copies in one process (no shell).
    copyProcess.exec(["install", "-D", "-m", "644", job.srcPath, job.destPath]);
  }

  function enqueueGrab(source: string) {
    root.cacheMap[source] = source; // reserve so the same source is not queued twice
    root.grabQueue.push(source);
    root.processGrabQueue();
  }

  function processGrabQueue() {
    if (root.grabBusy || root.grabQueue.length === 0)
      return;
    root.grabBusy = true;
    root.currentGrabSource = root.grabQueue.shift();
    grabImage.source = root.currentGrabSource;
  }

  function finishGrab() {
    root.grabBusy = false;
    root.currentGrabSource = "";
    root.processGrabQueue();
  }

  // Emits cached() only after a successful copy so consumers never switch to a
  // missing file; on failure the source is left live.
  Process {
    id: copyProcess

    onExited: {
      const job = root.currentCopyJob;
      if (job) {
        if (exitCode === 0)
          root.cached(job.source, job.destUrl);
        else
          root.cacheMap[job.source] = job.source;
      }
      root.currentCopyJob = null;
      root.copyBusy = false;
      root.processCopyQueue();
    }
  }

  // Offscreen rasterizer for in-memory provider images.
  Image {
    id: grabImage

    visible: false

    onStatusChanged: {
      if (grabImage.status === Image.Error) {
        root.finishGrab();
        return;
      }
      if (grabImage.status !== Image.Ready)
        return;

      const source = root.currentGrabSource;
      const destPath = `${root.cacheDir}/${root.hashString(source)}.png`;
      const destUrl = `file://${destPath}`;
      const size = Qt.size(grabImage.sourceSize.width, grabImage.sourceSize.height);
      grabImage.grabToImage(result => {
        if (result.saveToFile(destPath)) {
          root.cacheMap[source] = destUrl;
          root.cached(source, destUrl);
        }
        root.finishGrab();
      }, size);
    }
  }
}
