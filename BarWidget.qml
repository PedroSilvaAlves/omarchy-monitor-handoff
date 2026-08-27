import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "pedrosilvaalves.monitor-handoff"

  readonly property string selectedMonitor: String(setting("monitor", ""))
  readonly property int pollIntervalMs: Math.max(1, Number(setting("pollIntervalSec", 2))) * 1000
  readonly property string helperPath: decodeURIComponent(Qt.resolvedUrl("monitor-handoff").toString().replace(/^file:\/\//, ""))

  property string iconText: "󰍹"
  property string statusTooltip: "Right-click to choose a monitor"
  property bool statusActive: false
  property var panelItem: null

  readonly property bool opened: panelItem ? panelItem.opened === true : false
  readonly property bool popoutSwitchClosing: panelItem ? panelItem.popoutSwitchClosing === true : false

  function open() { if (panelItem) panelItem.open() }
  function close() { if (panelItem) panelItem.close() }
  function closeForPopoutSwitch() { if (panelItem) panelItem.closeForPopoutSwitch() }
  function togglePanel() { if (panelItem) panelItem.toggle() }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    panelItem = target
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
    if ("helperPath" in target) target.helperPath = root.helperPath
  }

  function refresh() {
    if (statusProcess.running) return
    statusProcess.command = [root.helperPath, "status", root.selectedMonitor]
    statusProcess.running = true
  }

  function toggleSelected() {
    if (!root.selectedMonitor) {
      root.open()
      return
    }
    Quickshell.execDetached([root.helperPath, "toggle", root.selectedMonitor])
    refreshDelay.restart()
  }

  function selectMonitor(name) {
    if (!name || !root.bar) return
    root.bar.run("omarchy bar set " + root.moduleName + " monitor " + Util.shellQuote(name))
    root.close()
    refreshDelay.restart()
  }

  function updateStatus(raw) {
    var data = Util.parseModuleJson(raw)
    root.iconText = data.text || "󰍹"
    root.statusTooltip = data.tooltip || "Monitor Handoff"
    var klass = data.class || ""
    root.statusActive = klass === "active" || (Array.isArray(klass) && klass.indexOf("active") !== -1)
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: {
    injectPanel()
    refresh()
  }
  Component.onCompleted: refresh()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.iconText
    active: root.statusActive
    tooltipText: root.statusTooltip

    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) root.togglePanel()
      else if (buttonCode === Qt.LeftButton) root.toggleSelected()
    }
  }

  Process {
    id: statusProcess
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.updateStatus(text)
    }
  }

  Timer {
    interval: root.pollIntervalMs
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Timer {
    id: refreshDelay
    interval: 600
    repeat: false
    onTriggered: root.refresh()
  }
}
