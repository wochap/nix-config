import QtQuick

import qs.services
import qs.widgets.common

Osd {
  service: Audio
  serviceSignalName: "outputVolumeChanged"
  serviceValueKey: "outputVolume"
  serviceValueTransformer: value => value * 100
  namespace: "quickshell:output-osd"
  icon: "volume_up"
}
