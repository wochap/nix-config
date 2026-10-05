import QtQuick
import QtQuick.Layouts
import qs.config
import qs.widgets.common
import qs.widgets.AuthPrompt

// key/value box, values marked mono are identifiers (paths, fingerprints, action ids)
StyledRect {
  id: root

  // [{ label, value, isMono }]
  property var rows: []

  implicitHeight: column.implicitHeight + 20
  radius: ConfigAuth.controlRadius
  color: Theme.options.mantle
  border.width: 1
  border.color: Theme.options.surface0

  ColumnLayout {
    id: column

    anchors {
      fill: parent
      topMargin: 10
      bottomMargin: 10
      leftMargin: 12
      rightMargin: 12
    }
    spacing: 6

    Repeater {
      model: root.rows

      RowLayout {
        id: detailRow

        required property var modelData

        Layout.fillWidth: true
        spacing: 12

        StyledText {
          Layout.preferredWidth: ConfigAuth.detailsLabelWidth
          Layout.alignment: Qt.AlignTop
          text: detailRow.modelData.label
          color: ConfigAuth.subtext
          elide: Text.ElideRight
          font.pixelSize: ConfigAuth.metaSize
          lineHeight: 18
          lineHeightMode: Text.FixedHeight
        }

        StyledText {
          Layout.fillWidth: true
          text: detailRow.modelData.value
          wrapMode: Text.WrapAnywhere
          font.pixelSize: ConfigAuth.metaSize
          lineHeight: 18
          lineHeightMode: Text.FixedHeight
        }
      }
    }
  }
}
