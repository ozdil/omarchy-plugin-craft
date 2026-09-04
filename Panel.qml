import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "ozdil.plugin-craft"
  ipcTarget: "ozdil.plugin-craft"

  property int currentTab: 0 // 0: Hub, 1: MonitorCraft, 2: MenuCraft
  property int activePluginCount: 13
  property var pluginList: []
  property var activeMonitors: []
  property string activeOemBrand: "GAME GARAJ"
  property string statusMsg: ""

  Process {
    id: engineProc
    command: [Qt.resolvedUrl("plugincraft-engine").toString().replace(/^file:\/\//, "")]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var cleanText = String(text || "").slice(0, 65536)
          var parsed = JSON.parse(cleanText)
          root.activePluginCount = parsed.total_plugins || 0
          root.pluginList = parsed.plugins || []
        } catch(e) {}
      }
    }
  }

  Process {
    id: launchProc
    onExited: function(exitCode) {
      launchDeadlineTimer.stop()
    }
  }

  Timer {
    id: launchDeadlineTimer
    interval: 5000
    repeat: false
    onTriggered: {
      if (launchProc.running) launchProc.kill()
    }
  }

  Component.onDestruction: {
    if (engineProc.running) engineProc.kill()
    if (launchProc.running) launchProc.kill()
  }

  function launchPluginDirect(execPath) {
    if (!execPath || typeof execPath !== "string") return
    if (!execPath.startsWith("/")) return
    root.close()
    launchProc.command = ["omarchy-launch-floating-terminal-with-presentation", execPath]
    launchDeadlineTimer.restart()
    launchProc.running = true
  }

  Timer {
    interval: 6000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      if (!engineProc.running) engineProc.running = true
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰏖 " + root.activePluginCount
    color: "#a855f7"
    slotSize: Style.bar.statusSlot
    tooltipText: "PluginCraft: " + root.activePluginCount + " Eklenti Aktif"
    onPressed: root.toggle()
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    width: 540
    contentHeight: Math.min(680, panel.fittedContentHeight(mainCol.implicitHeight + 20))

    Flickable {
      anchors.fill: parent
      contentHeight: mainCol.implicitHeight
      clip: true

      Column {
        id: mainCol
        width: parent.width
        spacing: Style.space(10)

        // Header
        RowLayout {
          width: parent.width
          Text {
            textFormat: Text.PlainText
            text: "󰏖 PluginCraft"
            font.bold: true
            font.pixelSize: Style.font.title
            color: "#a855f7"
          }
          Item { Layout.fillWidth: true }
          Text {
            textFormat: Text.PlainText
            text: root.activePluginCount + " Eklenti Kurulu"
            font.pixelSize: Style.font.caption
            color: "#94a3b8"
          }
        }

        // Tab Selector
        RowLayout {
          width: parent.width
          spacing: 6

          Button {
            Layout.fillWidth: true
            text: "Eklenti Karargahı"
            highlighted: root.currentTab === 0
            onClicked: root.currentTab = 0
          }
          Button {
            Layout.fillWidth: true
            text: "🖥️ Ekranlar"
            highlighted: root.currentTab === 1
            onClicked: root.currentTab = 1
          }
          Button {
            Layout.fillWidth: true
            text: "🎨 Menü / OEM"
            highlighted: root.currentTab === 2
            onClicked: root.currentTab = 2
          }
        }

        // TAB 0: ALL PLUGINS HUB
        GridLayout {
          visible: root.currentTab === 0
          columns: 2
          columnSpacing: 8
          rowSpacing: 8
          width: parent.width

          Repeater {
            model: root.pluginList
            delegate: Rectangle {
              Layout.fillWidth: true
              height: 48
              radius: 8
              color: mArea.containsMouse ? "#1e293b" : "#0f172a"
              border.color: mArea.containsMouse ? "#a855f7" : "#1e293b"
              border.width: 1

              RowLayout {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 8

                Text {
                  textFormat: Text.PlainText
                  text: modelData.icon || "📦"
                  font.pixelSize: 18
                }

                Column {
                  Layout.fillWidth: true
                  spacing: 1
                  Text {
                    textFormat: Text.PlainText
                    text: String(modelData.name || "").slice(0, 30)
                    font.bold: true
                    font.pixelSize: Style.font.caption
                    color: "#f8fafc"
                    elide: Text.ElideRight
                    width: 180
                  }
                  Text {
                    textFormat: Text.PlainText
                    text: String(modelData.description || "").slice(0, 50)
                    font.pixelSize: 9
                    color: "#94a3b8"
                    elide: Text.ElideRight
                    width: 180
                  }
                }
              }

              MouseArea {
                id: mArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (modelData.key === "monitor-craft") {
                    root.currentTab = 1
                  } else if (modelData.key === "menu-craft") {
                    root.currentTab = 2
                  } else {
                    root.launchPluginDirect(modelData.exec_cmd)
                  }
                }
              }
            }
          }
        }

        // TAB 1: QUICK MONITOR ACCESS
        Column {
          visible: root.currentTab === 1
          width: parent.width
          spacing: 8

          Text {
            textFormat: Text.PlainText
            text: "🖥️ MonitorCraft Hızlı Kontrolleri"
            font.bold: true
            color: "#38bdf8"
          }
          Button {
            text: "MonitorCraft Tam Stüdyosunu Aç"
            width: parent.width
            onClicked: {
              root.close()
              var p = Qt.resolvedUrl("../monitor-craft/monitorcraft-dashboard").toString().replace(/^file:\/\//, "")
              root.launchPluginDirect(p)
            }
          }
        }

        // TAB 2: QUICK MENUCRAFT ACCESS
        Column {
          visible: root.currentTab === 2
          width: parent.width
          spacing: 8

          Text {
            textFormat: Text.PlainText
            text: "🎨 MenuCraft Menü & OEM Kontrolleri"
            font.bold: true
            color: "#f59e0b"
          }
          Button {
            text: "MenuCraft Tam Stüdyosunu Aç"
            width: parent.width
            onClicked: {
              root.close()
              var p = Qt.resolvedUrl("../menu-craft/menucraft-dashboard").toString().replace(/^file:\/\//, "")
              root.launchPluginDirect(p)
            }
          }
        }
      }
    }
  }
}
