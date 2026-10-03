import QtQuick
import qs.config
import qs.services
import qs.widgets.common

OsdProgress {
  service: SPipewire
  serviceSignalName: "outputVolumeChanged"
  serviceValueKey: "outputVolume"
  serviceValueTransformer: value => value * 100
  serviceMutedKey: "isOutputMuted"
  namespace: "quickshell:output-osd"
  icon: "volume_up"
  mutedIcon: "volume_off"
  fillColor: Theme.options.lavender
}
