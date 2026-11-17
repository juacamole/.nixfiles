// Global singleton mirroring the allam daemon (~/cpp/allam): llama-server
// in router mode, driven over $XDG_RUNTIME_DIR/allam.sock. Every call goes
// through the `allam` CLI, which prints one JSON line per command.
//
//   phase:  "off" (no daemon) | "starting" | "running" | "restarting" | "stopping"
//   model / modelState / kvMib: the active model, if any
//   ubatch / batch / pending:   current and queued batch sizes
//
// Status is polled; `ls` is only polled while the popup is open and nothing
// is loaded. Assignments are guarded so idle polls cause no rebinds.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string phase: "off"
    property string model: ""
    property string modelState: "unloaded"   // unloaded | loading | loaded | sleeping
    property real kvMib: -1
    property int ubatch: 512
    property int batch: 512
    property int pendingUbatch: 0
    property int pendingBatch: 0
    property var models: []                  // [{ index, id, status }]

    // Last refused batch request, so the popup can offer "force" under the
    // slider that caused it. Cleared after a few seconds.
    property string refusedSlider: ""        // "" | "ubatch" | "batch"
    property int refusedUbatch: 0
    property int refusedBatch: 0
    property string refusedReason: ""

    property bool popupOpen: false

    readonly property bool hasModel: model.length > 0 && modelState !== "unloaded"

    function put(prop, value) { if (root[prop] !== value) root[prop] = value }

    function refresh(): void { if (!statusProc.running) statusProc.running = true }
    function refreshModels(): void { if (!lsProc.running) lsProc.running = true }

    function run(args): void {
        const p = actionComponent.createObject(root, { command: ["allam"].concat(args) })
        p.running = true
    }

    function start(): void { run(["start"]) }
    function load(index): void { run(["load", String(index)]) }
    function unload(): void { run(["unload"]) }

    // `slider` names which slider asked, for routing a refusal back to it.
    function setBatch(slider, ub, b, force): void {
        const args = ["batch", String(ub), String(b)]
        if (force) args.push("force")
        const p = batchComponent.createObject(root, {
            command: ["allam"].concat(args), slider: slider, ub: ub, b: b
        })
        p.running = true
        refusedSlider = ""
    }

    function applyStatus(j): void {
        put("phase", j.phase || "off")
        put("model", j.model || "")
        put("modelState", j.model_state || "unloaded")
        if (typeof j.ubatch === "number") put("ubatch", j.ubatch)
        if (typeof j.batch === "number") put("batch", j.batch)
        put("pendingUbatch", j.pending ? j.pending.ubatch : 0)
        put("pendingBatch", j.pending ? j.pending.batch : 0)
        const m = j.memory
        const kv = m && m.main ? (m.main.kv_mib || 0) + (m.mtp ? m.mtp.kv_mib || 0 : 0) : -1
        put("kvMib", kv)
    }

    Process {
        id: statusProc
        command: ["allam", "status"]
        property bool got: false
        onStarted: got = false
        stdout: SplitParser {
            onRead: line => {
                try {
                    const j = JSON.parse(line)
                    if (j.ok) { statusProc.got = true; root.applyStatus(j) }
                } catch (e) {}
            }
        }
        // No JSON line == daemon not running (the CLI only writes to stderr).
        onExited: if (!got) { root.put("phase", "off"); root.put("model", ""); root.put("modelState", "unloaded") }
    }

    Process {
        id: lsProc
        command: ["allam", "ls"]
        stdout: SplitParser {
            onRead: line => {
                try {
                    const j = JSON.parse(line)
                    if (!j.ok) return
                    const next = j.models.map(m => ({ index: m.index, id: m.id, status: m.status }))
                    if (JSON.stringify(next) !== JSON.stringify(root.models)) root.models = next
                } catch (e) {}
            }
        }
    }

    Component {
        id: actionComponent
        Process {
            onExited: { root.refresh(); root.refreshModels(); destroy() }
        }
    }

    Component {
        id: batchComponent
        Process {
            id: bp
            property string slider
            property int ub
            property int b
            stdout: SplitParser {
                onRead: line => {
                    try {
                        const j = JSON.parse(line)
                        if (j.ok) { root.applyStatus(j); return }
                        // Only the fit check is overridable; other errors
                        // (bad sizes) just get dropped.
                        if ((j.error || "").indexOf("force") >= 0) {
                            root.refusedUbatch = bp.ub
                            root.refusedBatch = bp.b
                            root.refusedReason = j.error
                            root.refusedSlider = bp.slider
                            refusalTimer.restart()
                        }
                    } catch (e) {}
                }
            }
            onExited: { root.refresh(); destroy() }
        }
    }

    Timer {
        id: refusalTimer
        interval: 8000
        onTriggered: root.refusedSlider = ""
    }

    // Fast while the popup is open or the daemon is mid-transition, slow
    // otherwise, slower still in battery-saver mode.
    Timer {
        interval: root.popupOpen || (root.phase !== "running" && root.phase !== "off") ? 1000
                : BatterySaver.active ? 15000 : 4000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            root.refresh()
            if (root.popupOpen && !root.hasModel) root.refreshModels()
        }
    }

    onPopupOpenChanged: if (popupOpen) { refresh(); refreshModels() }
}
