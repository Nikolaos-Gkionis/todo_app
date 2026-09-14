// Peponi One Day — pure helpers + demo data (no network / Rails API yet).
// Beginner note: .js files imported into QML are a shared toolbox.
// Keep this Qt-free so logic stays easy to read and test later.

var WEEKDAYS_LONG = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
var WEEKDAYS_SHORT = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
var MONTHS_SHORT = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

function pad2(n) {
  return (n < 10 ? "0" : "") + n
}

// "YYYY-MM-DD" key for looking up tasks by day.
function keyForDate(date) {
  var d = date instanceof Date ? date : new Date(date)
  return d.getFullYear() + "-" + pad2(d.getMonth() + 1) + "-" + pad2(d.getDate())
}

// Move a calendar day by delta (negative = past). Noon avoids DST glitches.
function stepDay(date, delta) {
  var d = date instanceof Date ? new Date(date.getTime()) : new Date(date)
  d.setHours(12, 0, 0, 0)
  d.setDate(d.getDate() + (delta || 0))
  return d
}

function startOfToday() {
  var d = new Date()
  d.setHours(12, 0, 0, 0)
  return d
}

function isSameDay(a, b) {
  return keyForDate(a) === keyForDate(b)
}

// Hero heading: "Monday · Sep 14"
function dayHeading(date) {
  var d = date instanceof Date ? date : new Date(date)
  return WEEKDAYS_LONG[d.getDay()] + " · " + MONTHS_SHORT[d.getMonth()] + " " + d.getDate()
}

function relativeLabel(selected, today) {
  if (keyForDate(selected) === keyForDate(today)) return "Today"
  var a = new Date(selected.getFullYear(), selected.getMonth(), selected.getDate(), 12)
  var b = new Date(today.getFullYear(), today.getMonth(), today.getDate(), 12)
  var diff = Math.round((a - b) / 86400000)
  if (diff === 1) return "Tomorrow"
  if (diff === -1) return "Yesterday"
  if (diff > 1) return "In " + diff + " days"
  return Math.abs(diff) + " days ago"
}

// ---------------------------------------------------------------------------
// DEMO DATA — weekday-keyed sample tasks. Replace with a real CLI/API later.
// ---------------------------------------------------------------------------
var demoByWeekday = {
  0: [
    { title: "Weekly review", done: false, list: "Planning" },
    { title: "Call family", done: true, list: "Personal" }
  ],
  1: [
    { title: "Ship Omarchy one-day overlay", done: false, list: "Work" },
    { title: "Inbox zero pass", done: false, list: "Work" },
    { title: "Gym — upper body", done: true, list: "Health" }
  ],
  2: [
    { title: "Write plugin README", done: false, list: "Work" },
    { title: "Buy groceries", done: false, list: "Errands" }
  ],
  3: [
    { title: "Mid-week check-in", done: false, list: "Work" },
    { title: "Read 20 pages", done: false, list: "Personal" }
  ],
  4: [
    { title: "Prepare Friday demo", done: false, list: "Work" },
    { title: "Water plants", done: true, list: "Home" }
  ],
  5: [
    { title: "Ship the week", done: false, list: "Work" },
    { title: "Plan weekend", done: false, list: "Personal" }
  ],
  6: [
    { title: "Long walk", done: false, list: "Health" },
    { title: "Meal prep", done: false, list: "Home" }
  ]
}

// Undated "Not Yet" inbox — shown in the bottom drawer (Peponi GUI cue).
var demoNotYet = [
  { title: "Book dentist", list: "Personal" },
  { title: "Rewrite onboarding copy", list: "Work" },
  { title: "Try new coffee beans", list: "Someday" },
  { title: "Sort photo backlog", list: "Home" }
]

function tasksForDate(date) {
  var d = date instanceof Date ? date : new Date(date)
  var rows = demoByWeekday[d.getDay()] || []
  var out = []
  for (var i = 0; i < rows.length; i++) {
    out.push({
      title: rows[i].title,
      done: rows[i].done === true,
      list: rows[i].list || ""
    })
  }
  return out
}

function notYetItems() {
  var out = []
  for (var i = 0; i < demoNotYet.length; i++) {
    out.push({
      title: demoNotYet[i].title,
      list: demoNotYet[i].list || ""
    })
  }
  return out
}

function openCount(tasks) {
  var n = 0
  for (var i = 0; i < tasks.length; i++) if (!tasks[i].done) n++
  return n
}

function parsePayloadDate(payloadJson) {
  var payload = ({})
  try { payload = JSON.parse(payloadJson || "{}") } catch (e) { payload = ({}) }
  if (payload.date) {
    var parts = String(payload.date).split("-")
    if (parts.length === 3) {
      var y = parseInt(parts[0], 10)
      var m = parseInt(parts[1], 10) - 1
      var day = parseInt(parts[2], 10)
      if (isFinite(y) && isFinite(m) && isFinite(day)) {
        var d = new Date(y, m, day, 12, 0, 0, 0)
        if (!isNaN(d.getTime())) return d
      }
    }
  }
  return startOfToday()
}
