import QtQuick
import QtQuick.Controls
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "pedrosilvaalves.monitor-handoff"

  property var anchorItem: null
  property var hostWidget: null
  property string helperPath: ""
  property var monitors: []
  property string errorMessage: ""

  readonly property var barIdentity: hostWidget || root
  readonly property string selectedMonitor: String(setting("monitor", ""))

  function open() {
    root.controller.show()
    root.refresh()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function refresh() {
    if (!root.helperPath || listProcess.running) return
    root.errorMessage = ""
    listProcess.command = [root.helperPath, "list"]
    listProcess.running = true
  }

  function choose(name) {
    if (root.hostWidget && root.hostWidget.selectMonitor) root.hostWidget.selectMonitor(name)
  }

  onOpenedChanged: if (opened) refresh()

  Process {
    id: listProcess
    stdout: StdioCollector { id: listOutput; waitForEnd: true }
    stderr: StdioCollector { id: listError; waitForEnd: true }
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.errorMessage = String(listError.text || "Unable to read monitor list").trim()
        return
      }
      try {
        root.monitors = JSON.parse(String(listOutput.text || "[]"))
      } catch (error) {
        root.errorMessage = "Invalid monitor data"
      }
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    contentWidth: panel.fittedContentWidth(Style.space(390))
    contentHeight: panel.fittedContentHeight(contentColumn.implicitHeight, Style.space(480))

    PanelKeyCatcher {
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      ScrollView {
        anchors.fill: parent
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        Column {
          id: contentColumn
          width: parent.width
          spacing: Style.space(10)

          Text {
            text: "Monitor Handoff"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.title
            font.bold: true
          }

          Text {
            width: parent.width
            wrapMode: Text.WordWrap
            text: "Choose the monitor that should be disconnected for another computer."
            color: Qt.darker(root.bar.foreground, 1.35)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.body
          }

          Text {
            visible: root.errorMessage !== ""
            width: parent.width
            wrapMode: Text.WordWrap
            text: root.errorMessage
            color: root.bar.urgent
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.body
          }

          Repeater {
            model: root.monitors

            CursorSurface {
              id: monitorRow
              required property var modelData
              width: contentColumn.width
              implicitHeight: rowContent.implicitHeight + Style.space(16)
              current: root.selectedMonitor === modelData.name
              bordered: true
              foreground: root.bar.foreground
              accent: root.bar.urgent

              Row {
                id: rowContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Style.space(10)
                anchors.rightMargin: Style.space(10)
                spacing: Style.space(10)

                Text {
                  text: monitorRow.modelData.active ? "󰍹" : "󰶐"
                  color: root.bar.foreground
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.subtitle
                  anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                  width: parent.width - Style.space(54)
                  spacing: Style.space(2)

                  Text {
                    text: monitorRow.modelData.name
                    color: root.bar.foreground
                    font.family: root.bar.fontFamily
                    font.pixelSize: Style.font.body
                    font.bold: true
                  }

                  Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: monitorRow.modelData.description || "Unknown display"
                    color: Qt.darker(root.bar.foreground, 1.35)
                    font.family: root.bar.fontFamily
                    font.pixelSize: Style.font.caption
                  }
                }

                Text {
                  text: root.selectedMonitor === monitorRow.modelData.name ? "󰄬" : ""
                  color: root.bar.foreground
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.subtitle
                  anchors.verticalCenter: parent.verticalCenter
                }
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onContainsMouseChanged: monitorRow.hasCursor = containsMouse
                onClicked: root.choose(monitorRow.modelData.name)
              }
            }
          }

          Text {
            visible: !listProcess.running && root.errorMessage === "" && root.monitors.length === 0
            text: "No monitors detected"
            color: Qt.darker(root.bar.foreground, 1.35)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.body
          }
        }
      }
    }
  }
}
