import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// cpurr - a cat that runs in your bar based on CPU usage.
//
// Omarchy port of the Noctalia widget (Deoxizn/cpurr), which ports Carlo
// Cattano's waycat (catloop.sh). The busier the CPU, the faster it runs;
// after a few idle cycles in a row it curls up and sleeps.
//
//   frame delay = clamp(1000 / (4 + cpu%), 30, 250) ms
//   sleep below 2% usage for 4 frames in a row
//   frames: A-E running, G-N sleeping (Waycat.ttf)
//
// Settings (from this widget's shell.json layout entry, edited in the bar's
// settings card):
//   size  int, default 32   pose art size in px. The bar clips widgets to its
//                           thickness, so keep this under it.
BarWidget {
  id: root
  moduleName: "deoxizn.cpurr"

  readonly property string home: Quickshell.env("HOME")
  readonly property string cpuScript: home + "/.config/omarchy/plugins/deoxizn.cpurr/cpu_monitor.py"

  readonly property var runFrames: ["A", "B", "C", "D", "E"]
  readonly property var sleepFrames: ["G", "H", "I", "J", "K", "L", "M", "N"]

  // catloop.sh defaults, same as the Noctalia original.
  readonly property real sleepThreshold: 2
  readonly property int sleepAfter: 4
  readonly property int minDelayMs: 30
  readonly property int maxDelayMs: 250

  // Pose art size in px, from the widget's settings (default 32).
  readonly property int catSize: Math.max(8, Number(setting("size", 32)))

  readonly property color fg: bar ? bar.barForeground : Color.foreground

  // Latest CPU usage percent from cpu_monitor.py (0 until the first sample).
  property real cpu: 0
  property int lowCycles: 0
  property int frameIndex: 0

  readonly property bool sleeping: root.lowCycles >= root.sleepAfter
  readonly property var frames: root.sleeping ? root.sleepFrames : root.runFrames
  readonly property int frameDelay: Math.max(root.minDelayMs, Math.min(root.maxDelayMs, Math.round(1000 / (4 + root.cpu))))

  // Fixed slot sized to the widest pose, so the bar doesn't shift as the cat
  // changes frames. Measured from the loaded font; falls back to the default
  // font's metrics if Waycat.ttf is missing.
  function maxFrameWidth() {
    var w = 0
    var all = root.runFrames.concat(root.sleepFrames)
    for (var i = 0; i < all.length; i++) w = Math.max(w, catMetrics.advanceWidth(all[i]))
    return Math.ceil(w)
  }

  implicitWidth: root.maxFrameWidth()
  implicitHeight: Math.ceil(catMetrics.height)

  FontLoader {
    id: catFont
    source: Qt.resolvedUrl("fonts/Waycat.ttf")
    onStatusChanged: if (catFont.status === FontLoader.Error)
      console.warn("cpurr: fonts/Waycat.ttf is missing - run setup/install.sh to fetch it")
  }

  FontMetrics {
    id: catMetrics
    font.family: catFont.name
    font.pixelSize: root.catSize
  }

  Text {
    id: frameLabel
    anchors.centerIn: parent
    text: root.frames[root.frameIndex]
    font.family: catFont.name
    font.pixelSize: root.catSize
    color: root.fg
  }

  function advance() {
    if (root.cpu < root.sleepThreshold) root.lowCycles += 1
    else root.lowCycles = 0
    root.frameIndex = (root.frameIndex + 1) % root.frames.length
  }

  Timer {
    id: frameTimer
    interval: root.frameDelay
    repeat: true
    running: true
    onTriggered: root.advance()
  }

  // cpu_monitor.py samples /proc/stat and prints one usage percent per line;
  // each line updates the run speed (the Timer interval follows root.cpu).
  property int cpuRestarts: 0
  Process {
    id: cpuWatcher
    command: ["python3", root.cpuScript]
    stdout: SplitParser {
      splitMarker: "\n"
      onRead: data => {
        var v = parseFloat(String(data || "").trim())
        if (!isNaN(v)) root.cpu = Math.max(0, Math.min(100, v))
      }
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (String(text || "").trim() !== "") console.warn("cpurr", String(text).trim())
    }
    running: true
    onExited: {
      if (exitCode !== 0 && root.cpuRestarts < 3) {
        root.cpuRestarts += 1
        restartCpu.start()
      }
    }
  }

  Timer {
    id: restartCpu
    interval: 1200
    repeat: false
    onTriggered: cpuWatcher.running = true
  }
}
