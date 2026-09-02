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

  property int currentTab: 0 // 0: Eklentiler, 1: Monitör Kontrolü, 2: Menu & OEM
  property int pluginCount: 13
  property var pluginList: []
  
  // Monitor states
  property int monitorCount: 2
  property bool vrrActive: false
  property var monitorsList: []
  property string statusMsg: ""

  // OEM states
  property string oemVendor: "GAME GARAJ"
  property string oemModel: "SLAYER 4 ULTRA"
  property string oemColor: "#ef4444"

  Process {
    id: pluginProc
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

  Process {
    id: monEngineProc
    command: [Qt.resolvedUrl("../monitor-craft/monitorcraft-engine").toString().replace(/^file:\/\//, ""), "--json"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var parsed = JSON.parse(text)
          root.monitorCount = parsed.total_monitors || 2
          root.vrrActive = parsed.vrr_enabled || false
          root.monitorsList = parsed.monitors || []
        } catch(e) {}
      }
    }
  }

  Process {
    id: monActionProc
  }

  function runMonitorAction(args, msg) {
    var enginePath = Qt.resolvedUrl("../monitor-craft/monitorcraft-engine").toString().replace(/^file:\/\//, "")
    monActionProc.command = [enginePath].concat(args)
    monActionProc.running = true
    root.statusMsg = msg || "Uygulandı"
    monRefreshTimer.restart()
  }

  Timer {
    id: monRefreshTimer
    interval: 500
    repeat: false
    onTriggered: {
      if (!monEngineProc.running) monEngineProc.running = true
    }
  }

  Timer {
    interval: 15000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      if (!pluginProc.running) pluginProc.running = true
      if (!monEngineProc.running) monEngineProc.running = true
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰏖 " + root.pluginCount
    color: "#38bdf8"
    slotSize: Style.bar.statusSlot
    tooltipText: "PluginCraft: " + root.pluginCount + " Eklenti & Kontrol Merkezi"
    onPressed: root.toggle()
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    width: 540
    contentHeight: panel.fittedContentHeight(mainCol.implicitHeight)

    Column {
      id: mainCol
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      spacing: Style.space(10)

      // Header Bar
      RowLayout {
        width: parent.width
        Text {
          text: "󰏖 PluginCraft • Kontrol Merkezi"
          font.pixelSize: Style.font.title
          font.bold: true
          color: root.bar ? root.bar.foreground : "#ffffff"
          Layout.fillWidth: true
        }

        Rectangle {
          width: 130
          height: 24
          radius: 12
          color: root.oemColor
          Text {
            anchors.centerIn: parent
            text: "🎮 " + root.oemVendor
            font.pixelSize: 10
            font.bold: true
            color: "#ffffff"
          }
        }
      }

      // Tab Navigation (100% Mouse Clickable)
      RowLayout {
        width: parent.width
        spacing: 6

        Button {
          text: "📦 Eklentiler (" + root.pluginCount + ")"
          Layout.fillWidth: true
          color: root.currentTab === 0 ? "#0284c7" : "#1e293b"
          onClicked: root.currentTab = 0
        }

        Button {
          text: "🖥️ Monitör & Hz"
          Layout.fillWidth: true
          color: root.currentTab === 1 ? "#0284c7" : "#1e293b"
          onClicked: {
            root.currentTab = 1
            if (!monEngineProc.running) monEngineProc.running = true
          }
        }

        Button {
          text: "🎨 Menü & OEM"
          Layout.fillWidth: true
          color: root.currentTab === 2 ? "#0284c7" : "#1e293b"
          onClicked: root.currentTab = 2
        }
      }

      Rectangle {
        width: parent.width
        height: 1
        color: "#334155"
      }

      // ==========================================
      // TAB 0: ALL PLUGINS GRID (Mouse Clickable)
      // ==========================================
      Column {
        width: parent.width
        visible: root.currentTab === 0
        spacing: 8

        Text {
          text: "Yüklü tüm araçlar (Başlatmak için tıklayın):"
          font.pixelSize: Style.font.caption
          color: "#94a3b8"
        }

        GridLayout {
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
              border.color: mArea.containsMouse ? "#38bdf8" : "#1e293b"
              border.width: 1

              RowLayout {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 8

                Text {
                  text: modelData.icon || "📦"
                  font.pixelSize: 18
                }

                Column {
                  Layout.fillWidth: true
                  spacing: 1
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

      // ==========================================
      // TAB 1: MONITORCRAFT GUI (Mouse Clickable)
      // ==========================================
      Column {
        width: parent.width
        visible: root.currentTab === 1
        spacing: 10

        RowLayout {
          width: parent.width
          Text {
            text: root.statusMsg ? "✓ " + root.statusMsg : "Ekran yenileme hızı, ölçek ve konum ayarları:"
            font.pixelSize: Style.font.caption
            color: root.statusMsg ? "#34d399" : "#94a3b8"
            Layout.fillWidth: true
          }

          Rectangle {
            width: 80
            height: 22
            radius: 11
            color: root.vrrActive ? "#059669" : "#334155"
            Text {
              anchors.centerIn: parent
              text: root.vrrActive ? "VRR AÇIK" : "VRR KAPALI"
              font.pixelSize: 9
              font.bold: true
              color: "#ffffff"
            }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.runMonitorAction(["--set-vrr", root.vrrActive ? "0" : "1"], root.vrrActive ? "VRR Kapatıldı" : "VRR Açıldı")
            }
          }
        }

        Repeater {
          model: root.monitorsList
          delegate: Rectangle {
            width: mainCol.width
            height: mCol.implicitHeight + 16
            radius: 8
            color: "#0f172a"
            border.color: "#1e293b"
            border.width: 1

            Column {
              id: mCol
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.top: parent.top
              anchors.margins: 8
              spacing: 6

              RowLayout {
                width: parent.width
                Text {
                  text: "󰍹 " + modelData.name + " (" + modelData.model + ")"
                  font.bold: true
                  color: "#f8fafc"
                  font.pixelSize: Style.font.caption
                  Layout.fillWidth: true
                }
                Text {
                  text: modelData.width + "x" + modelData.height + " @" + Math.round(modelData.refresh_rate) + "Hz [x" + modelData.scale + "]"
                  font.bold: true
                  color: "#38bdf8"
                  font.pixelSize: Style.font.caption
                }
              }

              // Hz Buttons
              RowLayout {
                width: parent.width
                spacing: 4
                Text { text: "Hz:"; color: "#94a3b8"; font.pixelSize: 10 }
                Button { text: "240Hz"; Layout.fillWidth: true; onClicked: root.runMonitorAction(["--monitor", modelData.name, "--mode", modelData.width + "x" + modelData.height + "@240"], modelData.name + " -> 240Hz") }
                Button { text: "144Hz"; Layout.fillWidth: true; onClicked: root.runMonitorAction(["--monitor", modelData.name, "--mode", modelData.width + "x" + modelData.height + "@144"], modelData.name + " -> 144Hz") }
                Button { text: "120Hz"; Layout.fillWidth: true; onClicked: root.runMonitorAction(["--monitor", modelData.name, "--mode", modelData.width + "x" + modelData.height + "@120"], modelData.name + " -> 120Hz") }
                Button { text: "60Hz"; Layout.fillWidth: true; onClicked: root.runMonitorAction(["--monitor", modelData.name, "--mode", modelData.width + "x" + modelData.height + "@60"], modelData.name + " -> 60Hz") }
              }

              // Scale Buttons
              RowLayout {
                width: parent.width
                spacing: 4
                Text { text: "Ölçek:"; color: "#94a3b8"; font.pixelSize: 10 }
                Button { text: "%100"; Layout.fillWidth: true; onClicked: root.runMonitorAction(["--monitor", modelData.name, "--scale", "1.0"], modelData.name + " -> %100") }
                Button { text: "%125"; Layout.fillWidth: true; onClicked: root.runMonitorAction(["--monitor", modelData.name, "--scale", "1.25"], modelData.name + " -> %125") }
                Button { text: "%150"; Layout.fillWidth: true; onClicked: root.runMonitorAction(["--monitor", modelData.name, "--scale", "1.5"], modelData.name + " -> %150") }
                Button { text: "%160"; Layout.fillWidth: true; onClicked: root.runMonitorAction(["--monitor", modelData.name, "--scale", "1.6"], modelData.name + " -> %160") }
              }
            }
          }
        }

        // Positioning
        RowLayout {
          width: parent.width
          spacing: 6
          Button {
            text: "⬅ Sola Yerleştir"
            Layout.fillWidth: true
            onClicked: {
              if (root.monitorsList.length >= 2) {
                root.runMonitorAction(["--monitor", root.monitorsList[1].name, "--position", "0x0"], "Sola yerleştirildi")
              }
            }
          }
          Button {
            text: "Sağa Yerleştir ➡"
            Layout.fillWidth: true
            onClicked: {
              if (root.monitorsList.length >= 2) {
                var m1_w = Math.round(root.monitorsList[0].width / (root.monitorsList[0].scale || 1))
                root.runMonitorAction(["--monitor", root.monitorsList[1].name, "--position", m1_w + "x0"], "Sağa yerleştirildi")
              }
            }
          }
          Button {
            text: "💾 Kaydet"
            Layout.fillWidth: true
            onClicked: root.runMonitorAction(["--save"], "Yapılandırma kaydedildi!")
          }
        }
      }

      // ==========================================
      // TAB 2: MENUCRAFT & OEM GUI (Mouse Clickable)
      // ==========================================
      Column {
        width: parent.width
        visible: root.currentTab === 2
        spacing: 10

        Rectangle {
          width: parent.width
          height: 60
          radius: 8
          color: "#0f172a"
          border.color: root.oemColor
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10
            Text { text: "🎮"; font.pixelSize: 24 }
            Column {
              Layout.fillWidth: true
              Text { text: root.oemVendor + " • " + root.oemModel; font.bold: true; color: "#f8fafc"; font.pixelSize: Style.font.body }
              Text { text: "Cyber Flame Red Teması & Özel Donanım Profili Aktif"; color: "#94a3b8"; font.pixelSize: Style.font.caption }
            }
          }
        }

        Button {
          width: parent.width
          text: "➕ Yeni Özel Menü Kısayolu Ekle"
          onClicked: {
            root.close()
            var dash = Qt.resolvedUrl("../menu-craft/menucraft-dashboard").toString().replace(/^file:\/\//, "")
            if (root.bar) root.bar.run("omarchy-launch-floating-terminal-with-presentation " + dash)
          }
        }

        Button {
          width: parent.width
          text: "🖼️ Bir Uygulamaya Özel Simge/Logo Ata"
          onClicked: {
            root.close()
            var dash = Qt.resolvedUrl("../menu-craft/menucraft-dashboard").toString().replace(/^file:\/\//, "")
            if (root.bar) root.bar.run("omarchy-launch-floating-terminal-with-presentation " + dash)
          }
        }

        Button {
          width: parent.width
          text: "👁️ İstenmeyen Sistem Uygulamalarını Gizle"
          onClicked: {
            root.close()
            var dash = Qt.resolvedUrl("../menu-craft/menucraft-dashboard").toString().replace(/^file:\/\//, "")
            if (root.bar) root.bar.run("omarchy-launch-floating-terminal-with-presentation " + dash)
          }
        }
      }
    }
  }
}
