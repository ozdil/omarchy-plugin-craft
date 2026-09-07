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

  property int totalPlugins: 0
  property var pluginList: []
  property string statusMsg: "READY"

  Process {
    id: engineProc
    command: [Qt.resolvedUrl("plugincraft-engine").toString().replace(/^file:\/\//, ""), "--json"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var raw = String(text || "").slice(0, 65536)
          var data = JSON.parse(raw)
          root.totalPlugins = data.total_plugins || 0
          root.pluginList = data.plugins || []
          root.statusMsg = "OPERATIONAL"
        } catch (e) {
          root.statusMsg = "PARSE ERROR"
        }
      }
    }
  }

  Process {
    id: execProc
    onExited: function(exitCode) {
      launchDeadlineTimer.stop()
    }
  }

  Timer {
    id: launchDeadlineTimer
    interval: 5000
    repeat: false
    onTriggered: {
      if (execProc.running) execProc.kill()
    }
  }

  Component.onDestruction: {
    if (engineProc.running) engineProc.kill()
    if (execProc.running) execProc.kill()
  }

  function runPlugin(cmd) {
    if (!cmd || typeof cmd !== "string" || !cmd.startsWith("/")) return
    execProc.command = [cmd]
    launchDeadlineTimer.restart()
    execProc.running = true
  }

  Timer {
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      if (!engineProc.running) engineProc.running = true
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "PLUGINS: " + root.totalPlugins
    tooltipText: "PluginCraft Hub • " + root.totalPlugins + " Active Plugins\nNative Rust Engine"
    onPressed: function(b) { if (root.opened) root.close(); else root.open(); }
  }

  KeyboardPanel {
    bar: root.bar
    id: panel
    anchorItem: button
    owner: root
    width: Style.space(520)
    contentHeight: Math.min(Style.space(640), panel.fittedContentHeight(mainCol.implicitHeight + Style.space(24)))

    Flickable {
      anchors.fill: parent
      anchors.margins: Style.space(12)
      contentHeight: mainCol.implicitHeight
      clip: true

      ColumnLayout {
        id: mainCol
        width: parent.width
        spacing: Style.space(12)

        // Header
        RowLayout {
          Layout.fillWidth: true
          ColumnLayout {
            spacing: Style.space(2)
            Text {
              textFormat: Text.PlainText
              text: "PLUGINCRAFT"
              font.bold: true
              font.pixelSize: Style.font.title
              color: "#a855f7"
            }
            Text {
              textFormat: Text.PlainText
              text: "CENTRALIZED PLUGIN HUB • NATIVE ARCH"
              font.pixelSize: Style.font.caption
              color: "#94a3b8"
            }
          }
          Item { Layout.fillWidth: true }
          Rectangle {
            width: Style.space(90)
            height: Style.space(24)
            radius: Style.space(4)
            color: "#1e293b"
            border.color: "#334155"
            border.width: 1
            Text {
              anchors.centerIn: parent
              textFormat: Text.PlainText
              text: root.statusMsg
              font.bold: true
              font.pixelSize: Style.font.caption
              color: "#a855f7"
            }
          }
        }

        // Summary Bar
        Rectangle {
          Layout.fillWidth: true
          height: Style.space(52)
          radius: Style.space(8)
          color: "#0f172a"
          border.color: "#1e293b"
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.margins: Style.space(10)
            ColumnLayout {
              spacing: Style.space(1)
              Text {
                textFormat: Text.PlainText
                text: "TOTAL INSTALLED"
                font.pixelSize: Style.font.caption
                color: "#64748b"
              }
              Text {
                textFormat: Text.PlainText
                text: root.totalPlugins + " PLUGINS"
                font.bold: true
                font.pixelSize: Style.font.body
                color: "#f8fafc"
              }
            }
            Item { Layout.fillWidth: true }
            ColumnLayout {
              spacing: Style.space(1)
              Text {
                textFormat: Text.PlainText
                text: "ENGINE CORE"
                font.pixelSize: Style.font.caption
                color: "#64748b"
              }
              Text {
                textFormat: Text.PlainText
                text: "NATIVE RUST"
                font.bold: true
                font.pixelSize: Style.font.body
                color: "#38bdf8"
              }
            }
            Item { Layout.fillWidth: true }
            ColumnLayout {
              spacing: Style.space(1)
              Text {
                textFormat: Text.PlainText
                text: "INTERFACE"
                font.pixelSize: Style.font.caption
                color: "#64748b"
              }
              Text {
                textFormat: Text.PlainText
                text: "ZERO CLI / NATIVE UI"
                font.bold: true
                font.pixelSize: Style.font.body
                color: "#4ade80"
              }
            }
          }
        }

        // Plugin List Section Header
        Text {
          textFormat: Text.PlainText
          text: "REGISTERED OMARCHY PLUGINS"
          font.bold: true
          font.pixelSize: Style.font.caption
          color: "#94a3b8"
        }

        // Plugin Cards
        ColumnLayout {
          Layout.fillWidth: true
          spacing: Style.space(6)

          Repeater {
            model: root.pluginList
            delegate: Rectangle {
              Layout.fillWidth: true
              height: Style.space(54)
              radius: Style.space(6)
              color: "#0f172a"
              border.color: "#1e293b"
              border.width: 1

              RowLayout {
                anchors.fill: parent
                anchors.margins: Style.space(8)
                spacing: Style.space(8)

                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: Style.space(2)
                  RowLayout {
                    spacing: Style.space(6)
                    Text {
                      textFormat: Text.PlainText
                      text: (modelData.name || modelData.key || "").toUpperCase()
                      font.bold: true
                      font.pixelSize: Style.font.caption
                      color: "#f8fafc"
                      elide: Text.ElideRight
                    }
                    Text {
                      textFormat: Text.PlainText
                      text: "v" + (modelData.version || "1.0.0")
                      font.pixelSize: Style.font.caption
                      color: "#64748b"
                    }
                  }
                  Text {
                    textFormat: Text.PlainText
                    text: modelData.description || "Omarchy Native Plugin"
                    font.pixelSize: Style.font.caption
                    color: "#94a3b8"
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                  }
                }

                Button {
                  text: "LAUNCH"
                  visible: modelData.exec_cmd && modelData.exec_cmd.length > 0
                  onClicked: root.runPlugin(modelData.exec_cmd)
                }
              }
            }
          }
        }

        // Footer Actions
        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(8)

          Button {
            Layout.fillWidth: true
            text: "REFRESH PLUGINS"
            onClicked: {
              if (!engineProc.running) engineProc.running = true
            }
          }

          Button {
            Layout.fillWidth: true
            text: "CLOSE"
            onClicked: root.close()
          }
        }
      }
    }
  }
}
