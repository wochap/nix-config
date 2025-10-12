pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
  id: root

  property bool isBlurEnabled: false
  property bool areAnimationsEnabled: false

  function formatTimeRemaining(totalSeconds) {
    // Ensure the input is a valid number, default to 0 if not.
    const seconds = Number(totalSeconds);
    if (isNaN(seconds) || seconds < 0) {
      return '0m';
    }

    const SECONDS_IN_AN_HOUR = 3600;

    if (seconds < SECONDS_IN_AN_HOUR) {
      // Calculate minutes and round to the nearest whole number.
      const minutes = Math.round(seconds / 60);
      return `${minutes}m`;
    } else {
      // Calculate hours.
      const hours = seconds / SECONDS_IN_AN_HOUR;
      const formattedHours = hours.toFixed(1);
      return `${formattedHours}h`;
    }
  }
}
