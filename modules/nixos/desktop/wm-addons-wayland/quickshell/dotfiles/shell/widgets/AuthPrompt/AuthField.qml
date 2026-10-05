import QtQuick
import qs.config
import qs.widgets.common
import qs.widgets.AuthPrompt

// 36px secret field with show/hide toggle (eye button or Alt+V)
FocusScope {
  id: root

  property alias text: input.text
  property string placeholder: ""
  property bool isRevealed: false
  property bool isError: false
  property bool isSuccess: false
  // Tab target, the default focus chain skips the input inside the next field
  property Item nextField: null
  readonly property bool isFocused: input.activeFocus

  signal accepted

  function clear() {
    input.text = "";
  }

  function focusInput() {
    input.forceActiveFocus();
  }

  implicitHeight: ConfigAuth.fieldHeight
  activeFocusOnTab: root.enabled
  opacity: root.enabled && !root.isSuccess ? 1 : ConfigAuth.disabledOpacity

  readonly property color _edgeColor: root.isError ? Theme.options.red : root.isSuccess ? Theme.options.green : root.isFocused ? ConfigAuth.ink : ConfigAuth.fieldBorder

  // 2px ring: 1px border + 1px outer ring
  StyledRect {
    anchors {
      fill: parent
      margins: -1
    }
    visible: root.isError || root.isFocused
    radius: ConfigAuth.controlRadius + 1
    border.width: 1
    border.color: root._edgeColor
  }

  StyledRect {
    anchors.fill: parent
    radius: ConfigAuth.controlRadius
    color: Theme.options.mantle
    border.width: 1
    border.color: root._edgeColor
  }

  TextInput {
    id: input

    anchors {
      left: parent.left
      right: eyeButton.left
      leftMargin: 12
      rightMargin: 4
      verticalCenter: parent.verticalCenter
    }
    focus: true
    clip: true
    echoMode: root.isRevealed ? TextInput.Normal : TextInput.Password
    passwordCharacter: "•"
    inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
    renderType: Text.NativeRendering
    color: Theme.options.text
    selectionColor: ConfigAuth.ink
    selectedTextColor: ConfigAuth.onInk
    font {
      family: Styles.font.family.main
      pixelSize: root.isRevealed || input.text === "" ? ConfigAuth.bodySize : ConfigAuth.hiddenTextSize
      letterSpacing: root.isRevealed ? 0 : 1
    }
    onAccepted: root.accepted()
    Keys.onPressed: event => {
      if (event.key === Qt.Key_V && (event.modifiers & Qt.AltModifier)) {
        root.isRevealed = !root.isRevealed;
        event.accepted = true;
      } else if (event.key === Qt.Key_Tab && root.nextField?.visible) {
        root.nextField.focusInput();
        event.accepted = true;
      }
    }
  }

  StyledText {
    anchors {
      left: input.left
      right: input.right
      verticalCenter: parent.verticalCenter
    }
    visible: input.text === ""
    text: root.placeholder
    color: ConfigAuth.placeholder
    elide: Text.ElideRight
    font.pixelSize: ConfigAuth.bodySize
  }

  StyledRect {
    id: eyeButton

    anchors {
      right: parent.right
      rightMargin: 4
      verticalCenter: parent.verticalCenter
    }
    width: 28
    height: 28
    radius: ConfigAuth.chipRadius
    color: eyeMouseArea.containsMouse || root.isRevealed ? Theme.options.surface0 : "transparent"

    MaterialIcon {
      anchors.centerIn: parent
      icon: root.isRevealed ? "visibility_off" : "visibility"
      size: 18
      color: eyeMouseArea.containsMouse || root.isRevealed ? Theme.options.text : ConfigAuth.subtext
    }

    MouseArea {
      id: eyeMouseArea

      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        root.isRevealed = !root.isRevealed;
        input.forceActiveFocus();
      }
    }
  }
}
