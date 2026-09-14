import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.Commons
import qs.Ui
import "Model.js" as Model

// Peponi One Day — fullscreen overlay (clipboard / reminders style).
// Beginner map:
//   Overlay.qml     = window + keys + day state
//   DayView.qml     = task list for selectedDate
//   BottomDrawer.qml = Not Yet slide-up (same window, not a 2nd layer-shell)
Item {
  id: root

  // Injected by omarchy-shell when the overlay Loader starts.
  property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  property var shell: null
  property var manifest: null

  property bool opened: false
  property bool drawerOpen: false
  property bool helpOpen: false

  // Selected calendar day (noon-normalized).
  property date selectedDate: Model.startOfToday()
  property date today: Model.startOfToday()
  property var dayTasks: []
  property var notYetItems: []

  // Theme tokens — same menu surface as clipboard/reminders.
  property color background: Color.menu.background
  property color foreground: Color.menu.text
  property color border: Color.menu.border
  property var borderSpec: Border.surfaceSpec("menu", "border", border, Math.max(1, Style.space(2)))
  property color scrim: Color.menu.scrim
  property color selectedBackground: Color.menu.selectedBackground
  property color selectedText: Color.menu.selectedText
  property color dim: Qt.darker(Color.menu.text, 1.55)
  property color accent: Color.accent
  readonly property int cornerRadius: Style.cornerRadius
  property string fontFamily: Style.font.menuFamily
  property int contentMargin: Style.spacing.panelPadding
  property int cardWidth: Math.min(Style.space(720), panel.width - Style.gapsOut * 2)
  property int cardHeight: Math.min(Style.space(640), panel.height - Style.gapsOut * 2)

  readonly property string heading: Model.dayHeading(selectedDate)
  readonly property string relative: Model.relativeLabel(selectedDate, today)
  readonly property bool isToday: Model.isSameDay(selectedDate, today)

  // ---- Lifecycle (shell summon / hide / toggle / call) --------------------

  function open(payloadJson) {
    root.today = Model.startOfToday()
    root.selectedDate = Model.parsePayloadDate(payloadJson)
    root.drawerOpen = false
    root.helpOpen = false
    root.reloadDay()
    root.opened = true
    Qt.callLater(function() {
      if (keyCatcher) keyCatcher.forceActiveFocus()
    })
  }

  function close() {
    root.drawerOpen = false
    root.helpOpen = false
    root.opened = false
  }

  function dismiss() {
    root.close()
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide((root.manifest && root.manifest.id) || "peponi.one-day")
  }

  function toggle() {
    if (root.opened) root.dismiss()
    else root.open("{}")
  }

  // IPC: omarchy-shell shell call peponi.one-day prevDay
  function prevDay() {
    root.ensureOpenForIpc()
    root.selectedDate = Model.stepDay(root.selectedDate, -1)
    root.reloadDay()
    return "ok"
  }

  function nextDay() {
    root.ensureOpenForIpc()
    root.selectedDate = Model.stepDay(root.selectedDate, 1)
    root.reloadDay()
    return "ok"
  }

  function goToToday() {
    root.today = Model.startOfToday()
    root.selectedDate = root.today
    root.reloadDay()
    return "ok"
  }

  function toggleDrawer() {
    root.ensureOpenForIpc()
    root.drawerOpen = !root.drawerOpen
    if (root.drawerOpen) drawer.resetCursor()
    else dayView.resetCursor()
    Qt.callLater(function() {
      if (keyCatcher) keyCatcher.forceActiveFocus()
    })
    return root.drawerOpen ? "open" : "closed"
  }

  function ensureOpenForIpc() {
    if (root.opened) return
    root.today = Model.startOfToday()
    if (!root.selectedDate || isNaN(root.selectedDate.getTime()))
      root.selectedDate = root.today
    root.reloadDay()
    root.opened = true
    Qt.callLater(function() {
      if (keyCatcher) keyCatcher.forceActiveFocus()
    })
  }

  function reloadDay() {
    root.dayTasks = Model.tasksForDate(root.selectedDate)
    root.notYetItems = Model.notYetItems()
    dayView.resetCursor()
  }

  function handleEscape() {
    if (root.helpOpen) {
      root.helpOpen = false
      return
    }
    if (root.drawerOpen) {
      root.drawerOpen = false
      dayView.resetCursor()
      return
    }
    root.dismiss()
  }

  Component.onCompleted: {
    root.today = Model.startOfToday()
    root.selectedDate = root.today
    root.reloadDay()
  }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "peponi-one-day"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    // Dim the desktop behind the card.
    Rectangle {
      anchors.fill: parent
      color: root.scrim
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.dismiss()
    }

    BorderSurface {
      id: card
      width: root.cardWidth
      height: root.cardHeight
      radius: root.cornerRadius
      anchors.centerIn: parent
      color: root.background
      borderSpec: root.borderSpec
      padding: root.contentMargin

      // Keep clicks on the card from dismissing via the scrim MouseArea.
      MouseArea { anchors.fill: parent; onClicked: {} }

      Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true
        z: 30

        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
          // Esc: close help → drawer → overlay
          if (event.key === Qt.Key_Escape) {
            root.handleEscape()
            event.accepted = true
            return
          }

          // ← / → : previous / next day (only when drawer closed, like Peponi GUI)
          if (event.key === Qt.Key_Left) {
            if (!root.drawerOpen) root.prevDay()
            event.accepted = true
            return
          }
          if (event.key === Qt.Key_Right) {
            if (!root.drawerOpen) root.nextDay()
            event.accepted = true
            return
          }

          // ↑ / ↓ : move among tasks (or Not Yet items when drawer is open)
          if (event.key === Qt.Key_Up) {
            if (root.drawerOpen) drawer.select(-1)
            else dayView.select(-1)
            event.accepted = true
            return
          }
          if (event.key === Qt.Key_Down) {
            if (root.drawerOpen) drawer.select(1)
            else dayView.select(1)
            event.accepted = true
            return
          }

          // Letter shortcuts (Peponi GUI cues)
          var t = event.text
          if (t === "y" || t === "Y") {
            root.toggleDrawer()
            event.accepted = true
            return
          }
          if (t === "t" || t === "T") {
            root.goToToday()
            event.accepted = true
            return
          }
          if (t === "?") {
            root.helpOpen = !root.helpOpen
            event.accepted = true
            return
          }
        }
      }

      // Main content
      Item {
        anchors.fill: parent
        anchors.topMargin: card.contentTopInset
        anchors.rightMargin: card.contentRightInset
        anchors.bottomMargin: card.contentBottomInset
        anchors.leftMargin: card.contentLeftInset

        Column {
          id: mainColumn
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          anchors.bottomMargin: root.drawerOpen ? drawer.openHeight + Style.space(8) : 0
          spacing: Style.space(14)

          Behavior on anchors.bottomMargin {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
          }

          // Hero: brand + day
          Column {
            width: parent.width
            spacing: Style.space(4)

            Text {
              text: "PEPONI"
              color: root.accent
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Row {
              spacing: Style.space(14)

              Text {
                text: root.heading
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.display
                font.bold: true
              }

              Text {
                anchors.baseline: parent.children[0].baseline
                text: root.relative.toUpperCase()
                color: root.isToday ? root.accent : root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                font.bold: true
              }
            }

            Text {
              text: "← → day  ·  y not yet  ·  t today  ·  esc close  ·  ?"
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }
          }

          Rectangle {
            width: parent.width
            height: 1
            color: root.border
            opacity: 0.45
          }

          DayView {
            id: dayView
            width: parent.width
            height: parent.height - Style.space(120)
            tasks: root.dayTasks
            foreground: root.foreground
            dim: root.dim
            accent: root.accent
            selectedBackground: root.selectedBackground
            selectedText: root.selectedText
            fontFamily: root.fontFamily
          }
        }

        // Bottom drawer — child of the same overlay card (not a new layer-shell).
        BottomDrawer {
          id: drawer
          anchors.fill: parent
          open: root.drawerOpen
          items: root.notYetItems
          background: root.background
          foreground: root.foreground
          dim: root.dim
          accent: root.accent
          border: root.border
          borderSpec: root.borderSpec
          selectedBackground: root.selectedBackground
          selectedText: root.selectedText
          fontFamily: root.fontFamily
        }

        // Lightweight shortcuts help overlay inside the card.
        Rectangle {
          visible: root.helpOpen
          anchors.fill: parent
          color: Qt.rgba(0, 0, 0, 0.55)
          z: 40

          MouseArea {
            anchors.fill: parent
            onClicked: root.helpOpen = false
          }

          BorderSurface {
            anchors.centerIn: parent
            width: Math.min(Style.space(420), parent.width - Style.space(40))
            height: helpCol.implicitHeight + Style.space(32)
            radius: root.cornerRadius
            color: root.background
            borderSpec: root.borderSpec
            padding: Style.spacing.panelPadding

            Column {
              id: helpCol
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.top: parent.top
              anchors.margins: Style.space(8)
              spacing: Style.space(8)

              Text {
                text: "SHORTCUTS"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.title
                font.bold: true
              }

              Text {
                width: parent.width
                text: "← / →   previous / next day\ny       toggle Not Yet drawer\nt       jump to today\n↑ / ↓   move in list\nEsc     close drawer, then overlay\n?       this help"
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                wrapMode: Text.Wrap
              }
            }
          }
        }
      }
    }
  }
}
