import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets.common

StyledRect {
  id: root

  implicitHeight: content.implicitHeight + ConfigCalendar.cardPadding * 2
  radius: Styles.radius.windowRounding
  color: Theme.options.mantle
  border {
    width: 1
    color: Theme.options.surface0
  }

  ColumnLayout {
    id: content

    anchors {
      fill: parent
      margins: ConfigCalendar.cardPadding
    }
    spacing: 8

    // Current conditions
    RowLayout {
      Layout.fillWidth: true
      visible: SWeather.available
      spacing: 10

      MaterialIcon {
        icon: SWeather.current?.icon ?? "cloud"
        size: 28
        fill: 1
        weight: Font.Normal
        color: SWeather.current?.iconColor ?? Theme.options.overlay2
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        StyledText {
          textFormat: Text.RichText
          text: `${SWeather.current?.temperature}°<font color="${Theme.options.subtext0}"><span style="font-size:${Styles.font.pixelSize.small}px"> feels ${SWeather.current?.feelsLike}°</span></font>`
          font.pixelSize: Styles.font.pixelSize.larger
          font.weight: Font.Medium
        }

        StyledText {
          Layout.fillWidth: true
          text: [SWeather.current?.description, SWeather.city].filter(s => s && s.length > 0).join(" · ")
          elide: Text.ElideRight
          font.pixelSize: Styles.font.pixelSize.smaller
          color: Theme.options.subtext0
        }
      }

      ColumnLayout {
        spacing: 0

        Repeater {
          model: [
            {
              icon: "water_drop",
              color: Theme.options.blue,
              value: `${SWeather.current?.precipitation ?? 0}%`
            },
            {
              icon: "air",
              color: Theme.options.overlay1,
              value: `${SWeather.current?.wind ?? 0} km/h`
            }
          ]

          RowLayout {
            required property var modelData

            Layout.alignment: Qt.AlignRight
            spacing: 3

            MaterialIcon {
              icon: modelData.icon
              size: Styles.font.pixelSize.small
              weight: Font.Normal
              color: modelData.color
            }

            StyledText {
              text: modelData.value
              font.pixelSize: Styles.font.pixelSize.smaller
              color: Theme.options.subtext0
            }
          }
        }
      }
    }

    // Forecast
    Item {
      Layout.fillWidth: true
      visible: SWeather.daily.length > 0
      implicitHeight: forecast.implicitHeight + 6

      Rectangle {
        anchors {
          top: parent.top
          left: parent.left
          right: parent.right
        }
        height: 1
        color: Theme.options.surface0
      }

      RowLayout {
        id: forecast

        anchors {
          left: parent.left
          right: parent.right
          bottom: parent.bottom
        }
        spacing: 2

        Repeater {
          model: SWeather.daily

          StyledRect {
            required property var modelData
            required property int index

            Layout.fillWidth: true
            Layout.preferredWidth: 1
            implicitHeight: day.implicitHeight + 8
            radius: Styles.radius.windowRounding
            color: index === 0 ? Theme.options.surface0 : "transparent"

            ColumnLayout {
              id: day

              anchors.centerIn: parent
              spacing: 2

              StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDate(modelData.date, "ddd")
                font.pixelSize: Styles.font.pixelSize.smaller
                color: Theme.options.overlay0
              }

              MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                icon: modelData.icon
                size: Styles.font.pixelSize.large
                fill: 1
                weight: Font.Normal
                color: modelData.iconColor
              }

              StyledText {
                Layout.alignment: Qt.AlignHCenter
                textFormat: Text.StyledText
                text: `${modelData.max}°<font color="${Theme.options.overlay1}"> ${modelData.min}°</font>`
                font.pixelSize: Styles.font.pixelSize.smaller
              }
            }
          }
        }
      }
    }

    // Loading / error
    RowLayout {
      Layout.fillWidth: true
      visible: !SWeather.available
      spacing: 8

      MaterialIcon {
        icon: SWeather.loading ? "progress_activity" : "cloud_off"
        size: Styles.font.pixelSize.larger
        weight: Font.Normal
        color: Theme.options.overlay1
      }

      StyledText {
        Layout.fillWidth: true
        text: SWeather.loading ? "Fetching weather…" : "Weather unavailable"
        elide: Text.ElideRight
        font.pixelSize: Styles.font.pixelSize.small
        color: Theme.options.subtext0
      }
    }
  }
}
