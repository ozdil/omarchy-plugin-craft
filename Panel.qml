import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "ozdil.plugin-craft"
  ipcTarget: "ozdil.plugin-craft"

  property int pluginCount: 13
  property var pluginList: []

  Process {
    id: scanProc
    command: [Qt.resolvedUrl("plugincraft-engine").toString().replace(/^file:\/\//, "")]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var parsed = JSON.parse(text)
          root.pluginCount = parsed.total_plugins || 13
          root.pluginList = parsed.plugins || []
        } catch(e) {}
      }
    }
  }

  Timer {
    interval: 20000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      if (!scanProc.running) scanProc.running = true
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰏖 " + root.pluginCount
    color: "#38bdf8"
    slotSize: Style.bar.statusSlot
    tooltipText: "PluginCraft: " + root.pluginCount + " Eklenti Merkezi"
    onPressed: root.toggle()
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    width: 520
    contentHeight: panel.fittedContentHeight(mainCol.implicitHeight)

    Column {
      id: mainCol
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      spacing: Style.space(10)

      // Header
      RowLayout {
        width: parent.width
        Text {
          text: "󰏖 PluginCraft • Eklenti Karargahı"
          font.pixelSize: Style.font.title
          font.bold: true
          color: root.bar ? root.bar.foreground : "#ffffff"
          Layout.fillWidth: true
        }

        Rectangle {
          width: 90
          height: 24
          radius: 12
          color: "#0369a1"
          Text {
            anchors.centerIn: parent
            text: root.pluginCount + " EKLENTİ"
            font.pixelSize: 10
            font.bold: true
            color: "#ffffff"
          }
        }
      }

      Text {
        text: "Açmak istediğiniz eklentiye tıklayın:"
        font.pixelSize: Style.font.caption
        color: "#94a3b8"
      }

      Rectangle {
        width: parent.width
        height: 1
        color: "#334155"
      }

      // 2-Column Grid of Clickable Plugin Cards
      GridLayout {
        columns: 2
        columnSpacing: 8
        rowSpacing: 8
        width: parent.width

        Repeater {
          model: root.pluginList
          delegate: Rectangle {
            Layout.fillWidth: true
            height: 52
            radius: 8
            color: mouseArea.containsMouse ? "#1e293b" : "#0f172a"
            border.color: mouseArea.containsMouse ? "#38bdf8" : "#1e293b"
            border.width: 1

            RowLayout {
              anchors.fill: parent
              anchors.margins: 8
              spacing: 8

              Text {
                text: modelData.icon || "📦"
                font.pixelSize: 18
              }

              Column {
                Layout.fillWidth: true
                spacing: 2
                Text {
                  text: modelData.name
                  font.bold: true
                  font.pixelSize: Style.font.caption
                  color: "#f8fafc"
                  elide: Text.ElideRight
                  width: 180
                }
                Text {
                  text: modelData.description || ""
                  font.pixelSize: 10
                  color: "#94a3b8"
                  elide: Text.ElideRight
                  width: 180
                }
              }
            }

            MouseArea {
              id: mouseArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                root.close()
                if (modelData.exec_cmd && root.bar) {
                  root.bar.run("omarchy-launch-floating-terminal-with-presentation " + modelData.exec_cmd)
                }
              }
            }
          }
        }
      }
    }
  }
}
