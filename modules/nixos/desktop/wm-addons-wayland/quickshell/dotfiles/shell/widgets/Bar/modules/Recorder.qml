import QtQuick
import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.Bar.config

Loader {
  id: root

  property bool isRecording: SRecorder.isRecording
  property bool isVisible: isRecording

  active: isVisible
  visible: isVisible
  sourceComponent: Component {
    MaterialIcon {
      icon: "screen_record"
      size: Styles.font.pixelSize.huge
      color: Theme.options.red
    }
  }
}
