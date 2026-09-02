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
  property string statusText: "Eklenti Merkezi"

  Process {
    id: scanProc
    command: [Qt.resolvedUrl("plugincraft-engine").toString().replace(/^file:\/\//, "")]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var parsed = JSON.parse(text)
          root.pluginCount = parsed.total_plugins || 13
        } catch(e) {}
      }
    }
  }

  Timer {
    interval: 30000
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
    tooltipText: "PluginCraft: " + root.pluginCount + " aktif eklenti"
    onPressed: root.toggle()
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    width: 460
    contentHeight: panel.fittedContentHeight(mainCol.implicitHeight)

    Column {
      id: mainCol
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      spacing: Style.space(12)

      Text {
        text: "󰏖 PluginCraft • Eklenti Karargahı"
        font.pixelSize: Style.font.title
        font.bold: true
        color: root.bar ? root.bar.foreground : "#ffffff"
      }

      Text {
        text: "Yüklü " + root.pluginCount + " eklentinizi tek bir merkezden yönetin ve açın."
        font.pixelSize: Style.font.body
        color: "#94a3b8"
      }

      Button {
        width: parent.width
        text: "🚀 Eklenti Menüsünü Aç"
        onClicked: {
          root.close()
          var dashPath = Qt.resolvedUrl("plugincraft-dashboard").toString().replace(/^file:\/\//, "")
          if (root.bar) root.bar.run("omarchy-launch-floating-terminal-with-presentation " + dashPath)
        }
      }
    }
  }
}
