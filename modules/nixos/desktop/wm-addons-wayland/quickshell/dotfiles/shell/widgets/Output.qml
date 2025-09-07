import QtQuick
import qs.services
import qs.widgets.common

OsdProgress {
  service: SPipewire
  serviceSignalName: "outputVolumeChanged"
  serviceValueKey: "outputVolume"
  serviceValueTransformer: value => value * 100
  namespace: "quickshell:output-osd"
  icon: "volume_up"
}
