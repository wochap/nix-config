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
  // verifying: keeps the text, blocks edits
  property bool isReadOnly: false
  // spinner in place of the eye
  property bool isBusy: false
  property bool hasEye: true
  // keep the ring on success, the lock screen shows it
  property bool hasSuccessRing: false
  // glyph on the left edge, none when empty
  property string leadingIcon: ""
  property color leadingIconColor: ConfigAuth.subtext
  // the lock screen uses mauve, auth dialogs lavender
  property color ink: ConfigAuth.ink
  property int textSize: ConfigAuth.bodySize
  property int hiddenTextSize: ConfigAuth.hiddenTextSize
  property real hiddenLetterSpacing: 1
  // Tab target, the default focus chain skips the input inside the next field
  property Item nextField: null
  readonly property bool isFocused: input.activeFocus

  signal accepted
  // every key reaches this first, accept it to stop the field handling it
  signal keyPressed(var event)

  function clear() {
    input.text = "";
  }

  function focusInput() {
    input.forceActiveFocus();
  }

  implicitHeight: ConfigAuth.fieldHeight
  activeFocusOnTab: root.enabled
  opacity: root.enabled && !root.isSuccess ? 1 : ConfigAuth.disabledOpacity

  readonly property color _edgeColor: root.isError ? Theme.options.red : root.isSuccess ? Theme.options.green : root.isFocused ? root.ink : ConfigAuth.fieldBorder

  // 2px ring: 1px border + 1px outer ring
  StyledRect {
    anchors {
      fill: parent
      margins: -1
    }
    visible: root.isError || root.isFocused || (root.isSuccess && root.hasSuccessRing)
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

  MaterialIcon {
    id: leadingGlyph

    anchors {
      left: parent.left
      leftMargin: 10
      verticalCenter: parent.verticalCenter
    }
    visible: root.leadingIcon !== ""
    icon: root.leadingIcon
    size: 18
    weight: Font.Normal
    color: root.leadingIconColor
  }

  TextInput {
    id: input

    anchors {
      left: leadingGlyph.visible ? leadingGlyph.right : parent.left
      right: eyeButton.left
      leftMargin: leadingGlyph.visible ? 8 : 12
      rightMargin: 4
      verticalCenter: parent.verticalCenter
    }
    focus: true
    clip: true
    readOnly: root.isReadOnly
    echoMode: root.isRevealed ? TextInput.Normal : TextInput.Password
    passwordCharacter: "•"
    inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
    renderType: Text.NativeRendering
    color: root.isReadOnly ? ConfigAuth.subtext : Theme.options.text
    selectionColor: root.ink
    selectedTextColor: ConfigAuth.onInk
    font {
      family: Styles.font.family.main
      pixelSize: root.isRevealed || input.text === "" ? root.textSize : root.hiddenTextSize
      letterSpacing: root.isRevealed ? 0 : root.hiddenLetterSpacing
    }
    onAccepted: root.accepted()
    Keys.onPressed: event => {
      root.keyPressed(event);
      if (event.accepted) {
        return;
      }
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
    font.pixelSize: root.textSize
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
    visible: root.hasEye || root.isBusy
    radius: ConfigAuth.chipRadius
    color: root.isBusy ? "transparent" : eyeMouseArea.containsMouse || root.isRevealed ? Theme.options.surface0 : "transparent"

    MaterialIcon {
      anchors.centerIn: parent
      visible: root.isBusy
      icon: "progress_activity"
      size: 16
      weight: Font.Bold
      color: root.ink

      RotationAnimation on rotation {
        running: root.isBusy
        from: 0
        to: 360
        duration: 800
        loops: Animation.Infinite
      }
    }

    MaterialIcon {
      anchors.centerIn: parent
      visible: !root.isBusy
      icon: root.isRevealed ? "visibility_off" : "visibility"
      size: 18
      color: eyeMouseArea.containsMouse || root.isRevealed ? Theme.options.text : ConfigAuth.subtext
    }

    MouseArea {
      id: eyeMouseArea

      anchors.fill: parent
      enabled: !root.isBusy
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        root.isRevealed = !root.isRevealed;
        input.forceActiveFocus();
      }
    }
  }
}
