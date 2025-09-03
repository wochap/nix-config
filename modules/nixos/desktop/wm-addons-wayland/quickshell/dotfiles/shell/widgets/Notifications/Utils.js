/**
 * Converts a JavaScript date timestamp into a friendly, relative time string.
 * e.g., "now", "5m", "1h", "yesterday", "3d". If older than a week,
 * it falls back to a "Month Day" format (e.g., "August 31").
 * This is designed to be compatible with a QML fallback behavior.
 *
 * @param {number} timestamp - The JavaScript timestamp (milliseconds since epoch).
 * @returns {string} A string representing the time elapsed or the formatted date.
 */
function formatTimeAgo(timestamp) {
  // Get the current time in seconds
  const now = Math.floor(Date.now() / 1000);
  // Get the timestamp time in seconds
  const date = Math.floor(new Date(timestamp).getTime() / 1000);

  // Calculate the difference in seconds
  const seconds = now - date;

  // --- Time intervals in seconds ---
  const minute = 60;
  const hour = 3600; // 60 * 60
  const day = 86400; // 3600 * 24
  const week = 604800; // 86400 * 7

  // --- Conditional formatting ---
  if (seconds < 60) {
    return "now";
  } else if (seconds < hour) {
    return `${Math.floor(seconds / minute)}m`;
  } else if (seconds < day) {
    return `${Math.floor(seconds / hour)}h`;
  } else if (seconds < day * 2) {
    // Specifically return 'yesterday' for the 1-2 day range
    return "yesterday";
  } else if (seconds < week) {
    return `${Math.floor(seconds / day)}d`;
  } else {
    // For dates older than a week, format as "Month Day"
    const originalDate = new Date(timestamp);
    return Qt.formatDateTime(originalDate, "MMM dd");
  }
}
