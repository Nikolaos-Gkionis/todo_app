import QtQuick
import Quickshell
import Quickshell.Io
import "Model.js" as Model

// Shared engine for every bar / overlay instance.
// Talks to the peponi CLI (credentials in ~/.config/peponi/).
Item {
  id: root

  property var shell: null
  property var settings: ({})
  property bool active: true

  property bool authenticated: false
  property bool probing: false
  property bool loadingDay: false
  property bool loadingNotYet: false
  property string lastError: ""
  property string statusMessage: ""
  property string userEmail: ""
  property string appTitle: "Peponi"
  property string notYetTitle: "Not Yet"
  property int openTaskCount: 0

  property date selectedDate: Model.startOfToday()
  property var dayTasks: []
  property var notYetItems: []

  readonly property bool demoMode: Quickshell.env("PEPONI_DEMO") === "1"
  readonly property bool busy: probing || loadingDay || loadingNotYet

  function peponiBin() {
    // Absolute path first so Quickshell Process finds it without a login shell PATH.
    var home = Quickshell.env("HOME") || ""
    if (home !== "") return home + "/.local/bin/peponi"
    return "peponi"
  }

  function refreshAuth() {
    if (demoMode) {
      authenticated = true
      statusMessage = "Demo mode (PEPONI_DEMO=1)"
      lastError = ""
      return
    }
    probing = true
    lastError = ""
    authProcess.command = [peponiBin(), "auth", "status", "--json"]
    authProcess.running = true
  }

  function loadDay(dateObj) {
    selectedDate = dateObj instanceof Date ? dateObj : Model.startOfToday()
    if (demoMode) {
      dayTasks = Model.tasksForDate(selectedDate)
      openTaskCount = Model.openCount(dayTasks)
      return
    }
    if (!authenticated) {
      dayTasks = []
      openTaskCount = 0
      return
    }
    loadingDay = true
    dayProcess.command = [peponiBin(), "day", Model.keyForDate(selectedDate), "--json"]
    dayProcess.running = true
  }

  function loadNotYet() {
    if (demoMode) {
      notYetItems = Model.notYetItems()
      return
    }
    if (!authenticated) {
      notYetItems = []
      return
    }
    loadingNotYet = true
    notYetProcess.command = [peponiBin(), "not-yet", "--json"]
    notYetProcess.running = true
  }

  function reloadAll() {
    refreshAuth()
  }

  function applyAuth(stdoutText, exitCode) {
    probing = false
    if (exitCode !== 0) {
      authenticated = false
      userEmail = ""
      lastError = "Not signed in. Run: peponi auth login"
      statusMessage = lastError
      dayTasks = []
      notYetItems = []
      openTaskCount = 0
      return
    }
    try {
      var data = JSON.parse(stdoutText || "{}")
      authenticated = data.authenticated === true
      if (data.user) {
        userEmail = data.user.email || ""
        appTitle = data.user.app_title || "Peponi"
        notYetTitle = data.user.not_yet_panel_title || "Not Yet"
      }
      statusMessage = authenticated ? ("Signed in as " + userEmail) : "Not signed in"
      lastError = authenticated ? "" : statusMessage
    } catch (e) {
      authenticated = false
      lastError = "Could not read peponi auth status"
      statusMessage = lastError
    }
    if (authenticated) {
      loadDay(selectedDate)
      loadNotYet()
    }
  }

  function applyDay(stdoutText, exitCode) {
    loadingDay = false
    if (exitCode !== 0) {
      lastError = "Failed to load day (is peponi signed in?)"
      dayTasks = []
      openTaskCount = 0
      return
    }
    dayTasks = Model.tasksFromDayJson(stdoutText)
    openTaskCount = Model.openCount(dayTasks)
    lastError = ""
  }

  function applyNotYet(stdoutText, exitCode) {
    loadingNotYet = false
    if (exitCode !== 0) {
      notYetItems = []
      return
    }
    try {
      var data = JSON.parse(stdoutText || "{}")
      if (data.title) notYetTitle = data.title
    } catch (e) {}
    notYetItems = Model.notYetFromJson(stdoutText)
  }

  Component.onCompleted: reloadAll()

  Process {
    id: authProcess
    command: []
    stdout: StdioCollector {
      onStreamFinished: root.applyAuth(this.text, authProcess.exitCode)
    }
    onExited: function(exitCode) {
      // If stdout collector already ran, this is a no-op safety net when empty
      if (!root.probing) return
      root.applyAuth("", exitCode)
    }
  }

  Process {
    id: dayProcess
    command: []
    stdout: StdioCollector {
      onStreamFinished: root.applyDay(this.text, dayProcess.exitCode)
    }
    onExited: function(exitCode) {
      if (!root.loadingDay) return
      root.applyDay("", exitCode)
    }
  }

  Process {
    id: notYetProcess
    command: []
    stdout: StdioCollector {
      onStreamFinished: root.applyNotYet(this.text, notYetProcess.exitCode)
    }
    onExited: function(exitCode) {
      if (!root.loadingNotYet) return
      root.applyNotYet("", exitCode)
    }
  }
}
