pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
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

  // source string -> stable cached file:// url
  property var cacheMap: ({})
  // image://qsimage sources awaiting a grab (serialized through grabImage)
  property var grabQueue: []
  property bool grabBusy: false
  property string currentGrabSource: ""

  // Emitted once `source` has been materialized to a cached file.
  signal cached(source: string, url: string)

  readonly property var imageExtensions: [
    "png", "jpg", "jpeg", "gif", "webp", "bmp", "svg", "ico", "tiff", "tif", "avif",
  ]

  Component.onCompleted: {
    Quickshell.execDetached(["mkdir", "-p", root.cacheDirectory()]);
  }

  function cacheDirectory(): string {
    return Paths.strip(Paths.notificationsimageCache);
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

    const cachePrefix = root.cacheDirectory();
    if (source.startsWith(`${cachePrefix}/`) || source.startsWith(`file://${cachePrefix}/`))
      return source;

    if (source.startsWith("image://icon/"))
      return source;

    if (source.startsWith("image://qsimage/") || source.startsWith("image://qspixmap/")) {
      root.enqueueGrab(source);
      return source;
    }

    if (root.isFilePath(source))
      return root.cacheFile(source);

    // themed icon name or anything unrecognized: nothing to cache
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

  function cacheFile(source: string): string {
    const srcPath = Paths.strip(source);
    const ext = root.extensionOf(srcPath);
    const destExt = root.isImageExtension(ext) ? ext : "png";
    const destPath = `${root.cacheDirectory()}/${root.hashString(srcPath)}.${destExt}`;
    const destUrl = `file://${destPath}`;
    root.cacheMap[source] = destUrl;
    // mkdir + cp in one shot: the singleton is created lazily on first use, so a
    // separate async mkdir could lose the race against this first copy. Paths are
    // passed as positional args so spaces/quotes in srcPath stay safe.
    Quickshell.execDetached([
      "sh", "-c", "mkdir -p \"$1\" && cp -f \"$2\" \"$3\"", "sh", root.cacheDirectory(), srcPath, destPath,
    ]);
    root.cached(source, destUrl);
    return destUrl;
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
      const destPath = `${root.cacheDirectory()}/${root.hashString(source)}.png`;
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
