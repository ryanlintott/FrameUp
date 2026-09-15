#!/usr/bin/env swift

//
//  probelog.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-09-11.
//

/// Reads the widget size probe's log off a simulator and summarises the frames it reported, separating the frames a placed widget reported from the ones WidgetKit pre-rendered.
///
/// A widget size can have a different frame in different places, such as an Apple Watch complication and the same widget in the Smart Stack, and nothing readable at render time says which place a render came from. What does separate them is placing the probe in one place and nowhere else: the frame that placed widget reports belongs to that place. See `Measurements/README.md`.
///
/// This tool cannot know where the widget was placed, so the placement is the operator's assertion, passed in with `--placement` and recorded in the output.
///
/// Runs directly with no build step:
///
/// ```sh
/// Measurements/probelog.swift                                     # whatever the booted simulator has logged
/// Measurements/probelog.swift --placement watchFace --last 5m
/// Measurements/probelog.swift --device "Apple Watch Series 11 (42mm)" --records
/// Measurements/probelog.swift --file console.log --placement lockScreen
/// ```
///
/// `--file` reads a saved log instead of a simulator, which is the only route for a physical device: its records come out of Console.app rather than out of `simctl`.

import Foundation

// MARK: - Errors

/// Anything that stops a capture, reported as a message rather than a crash.
struct ProbeError: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}

// MARK: - Sizes

/// A frame in points, kept as its own type so sizes can be grouped and compared.
struct Size: Hashable {
    let width: Double
    let height: Double

    var area: Double { width * height }

    var description: String {
        Self.number(width) + "×" + Self.number(height)
    }

    /// Trailing zeros dropped, so 72.5 stays 72.5 and 176.0 reads 176.
    static func number(_ value: Double) -> String {
        String(format: "%g", value)
    }

    /// Reads the `[width, height]` array a `CGSize` encodes to.
    init?(_ value: Any?) {
        guard let pair = value as? [Any], pair.count == 2,
              let width = (pair[0] as? NSNumber)?.doubleValue,
              let height = (pair[1] as? NSNumber)?.doubleValue
        else { return nil }
        self.width = Self.rounded(width)
        self.height = Self.rounded(height)
    }

    /// Rounded to a thousandth of a point, so one frame is one size.
    ///
    /// A third of a pixel is not exact in floating point, and the same @3x frame arrives as both 164.33333333333331 and 164.33333333333334. Unrounded, those count as two sizes that print identically, and a placed frame reads as not matching its own pre-rendered frame.
    ///
    /// A thousandth is the precision the report prints, so a size can no longer differ from the way it reads. It is far finer than any real difference: frames land on whole pixels, so two of them are at least a third of a point apart.
    static func rounded(_ value: Double) -> Double {
        (value * 1_000).rounded() / 1_000
    }
}

// MARK: - Records

/// What a record can be trusted to say about where the widget was.
///
/// Named after what the records have been observed to mean rather than after a placement, because no record reports a placement. See `Measurements/README.md` for what each group has been observed to mean.
enum StageGroup {
    /// A provider callback for a widget that is really on the device: `snapshot` or `timeline` with `isPreview` false. The only group attributable to wherever the operator put the widget.
    case placed
    /// Any callback WidgetKit flagged as a preview. A gallery browse produces `snapshot` records with `isPreview` true, which look exactly like a placed widget's until this field is read.
    case preview
    /// `placeholder`. WidgetKit asking the provider for each frame it intends to pre-render, so this is where a family's pair of frames shows up. It happens during a gallery browse as well as on a placed widget, so it attributes nothing on its own.
    case preRendered
    /// `render`, measured inside the widget body by the probe's own `Shape`. That runs for a placed widget and a pre-render alike, with nothing to tell them apart.
    case rendered

    init?(stage: String, isPreview: Bool?) {
        if isPreview == true {
            self = .preview
            return
        }
        switch stage {
        case "snapshot", "timeline": self = .placed
        case "placeholder": self = .preRendered
        case "render": self = .rendered
        default: return nil
        }
    }

    var heading: String {
        switch self {
        case .placed: "placed"
        case .preview: "preview"
        case .preRendered: "pre-rendered"
        case .rendered: "rendered"
        }
    }

    /// Order the table's columns read in, which is the order a measurement run produces them.
    static let columns: [StageGroup] = [.preRendered, .preview, .placed, .rendered]
}

/// One line of the probe's log.
struct Record {
    let timestamp: String
    let fields: [String: Any]

    var family: String { fields["family"] as? String ?? "unknown" }
    var stage: String { fields["stage"] as? String ?? "unknown" }
    var isPreview: Bool? { fields["isPreview"] as? Bool }
    var widgetKind: String? { fields["widgetKind"] as? String }
    var group: StageGroup? { StageGroup(stage: stage, isPreview: isPreview) }
    var deviceModel: String { fields["deviceModel"] as? String ?? "unknown" }
    var systemVersion: String { fields["systemVersion"] as? String ?? "unknown" }
    var idiom: String? { fields["idiom"] as? String }
    var screenSize: Size? { Size(fields["screenSize"]) }
    var displayScale: Double? { (fields["displayScale"] as? NSNumber)?.doubleValue }

    /// The frame this record reports, whichever instrument measured it.
    var size: Size? { Size(fields["displaySize"]) ?? Size(fields["viewSize"]) }

    /// Marker the probe writes ahead of its JSON payload.
    static let logPrefix = "WIDGET_SIZE_PROBE"

    /// Reads one record out of a log line, or nil if the line carries no record.
    init?(line: String) {
        guard let marker = line.range(of: Self.logPrefix + " ") else { return nil }
        let json = String(line[marker.upperBound...])
        guard let data = json.data(using: .utf8),
              let fields = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        self.fields = fields
        /// `log show` puts the date and time first, whatever the style. Anything else is treated as having no timestamp rather than as a failure, since the payload is what matters.
        let head = line[line.startIndex..<marker.lowerBound]
        let parts = head.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true)
        if parts.count >= 2, parts[0].count == 10, parts[0].contains("-") {
            timestamp = parts[0] + " " + parts[1].prefix(12)
        } else {
            timestamp = "—"
        }
    }
}

// MARK: - Options

struct Options {
    /// Device specifier `simctl` understands: a UDID, a unique device name, or `booted`.
    var device = "booted"
    /// A saved log to read instead of a simulator. `-` reads standard input.
    var file: String?
    /// Window passed to `log show --last`.
    var window = "10m"
    /// Where the operator placed the widget. Nil reports the frames without attributing them.
    var placement: String?
    /// Lists every record rather than only the summary.
    var showsRecords = false

    /// The cases of `WidgetPlacement` in the library.
    static let placements = ["homeScreen", "lockScreen", "standBy", "carPlay", "watchFace", "smartStack", "iPhoneWidgetsOnMac"]

    static let usage = """
        usage: probelog.swift [--placement <placement>] [--device <udid|name>]
                              [--file <log>] [--last <window>] [--records]

          --placement  Where the widget was placed for this capture, one of
                       \(placements.joined(separator: ", ")).
                       Asserted by you, since no record reports a placement.
          --device     Simulator to read the log from. Default: booted.
          --file       Read a saved log instead, as exported from Console.app for a physical
                       device. Use - for standard input.
          --last       Window to read, passed to log show. Default: 10m.
          --records    List every record with its timestamp, not just the summary.
        """

    static func parse(_ arguments: [String]) throws -> Options {
        var options = Options()
        var remaining = Array(arguments.dropFirst())
        while !remaining.isEmpty {
            let argument = remaining.removeFirst()
            func value(_ name: String) throws -> String {
                guard !remaining.isEmpty else { throw ProbeError("\(name) needs a value\n\n\(usage)") }
                return remaining.removeFirst()
            }
            switch argument {
            case "--placement":
                let placement = try value(argument)
                guard placements.contains(placement) else {
                    throw ProbeError("unknown placement \(placement), expected one of \(placements.joined(separator: ", "))")
                }
                options.placement = placement
            case "--device": options.device = try value(argument)
            case "--file": options.file = try value(argument)
            case "--last": options.window = try value(argument)
            case "--records": options.showsRecords = true
            case "--help", "-h":
                print(usage)
                exit(0)
            default: throw ProbeError("unknown argument \(argument)\n\n\(usage)")
            }
        }
        return options
    }
}

// MARK: - Reading the log

/// Runs a command and returns its standard output, or throws with whatever it wrote to standard error.
func run(_ executable: String, _ arguments: [String]) throws -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    let output = Pipe()
    let errors = Pipe()
    process.standardOutput = output
    process.standardError = errors
    try process.run()
    /// Read before waiting, so a long log cannot fill the pipe and deadlock.
    let outputData = output.fileHandleForReading.readDataToEndOfFile()
    let errorData = errors.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
        let message = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        throw ProbeError("\(([executable] + arguments).joined(separator: " ")) failed\n\(message)")
    }
    return String(data: outputData, encoding: .utf8) ?? ""
}

/// Every probe record in a saved log.
///
/// Console.app exports one line per message the same way `log show` prints them, and any line without the probe's marker is ignored, so a whole unfiltered export works as well as a filtered one.
func records(file: String) throws -> [Record] {
    let text: String
    if file == "-" {
        let data = FileHandle.standardInput.readDataToEndOfFile()
        text = String(data: data, encoding: .utf8) ?? ""
    } else {
        guard let contents = try? String(contentsOf: URL(fileURLWithPath: file), encoding: .utf8) else {
            throw ProbeError("could not read \(file)")
        }
        text = contents
    }
    return text.split(separator: "\n").compactMap { Record(line: String($0)) }
}

/// Every probe record a simulator has logged inside the window.
///
/// History is queried rather than streamed because a long lived `log stream` can be killed and lose everything it had buffered.
func records(device: String, window: String) throws -> [Record] {
    let output = try run("/usr/bin/xcrun", [
        "simctl", "spawn", device,
        "log", "show", "--style", "compact", "--last", window,
        "--predicate", "subsystem == \"com.abetterwaytodo.FrameUpExample.WidgetSizeProbe\""
    ])
    return output.split(separator: "\n").compactMap { Record(line: String($0)) }
}

// MARK: - Reporting

/// Distinct sizes in a group of records, smallest first.
func sizes(_ records: [Record]) -> [Size] {
    Array(Set(records.compactMap(\.size))).sorted { $0.area < $1.area }
}

/// Distinct sizes with how many records reported each, smallest first.
///
/// The count is not decoration. A watch that pre-renders a family twice at the same size looks identical to one that pre-renders it once until the records are counted, and the two mean opposite things: a pair whose halves happen to be equal, against a family with only one frame. Reading the 42mm as the second was wrong.
func tally(_ records: [Record]) -> [(size: Size, count: Int)] {
    var counts: [Size: Int] = [:]
    for size in records.compactMap(\.size) { counts[size, default: 0] += 1 }
    return counts.sorted { $0.key.area < $1.key.area }.map { (size: $0.key, count: $0.value) }
}

/// A cell listing each size and, where a size was reported more than once, how many times.
func cell(_ records: [Record]) -> String {
    let tallied = tally(records)
    if tallied.isEmpty { return "–" }
    return tallied.map { $0.count > 1 ? "\($0.size.description) ×\($0.count)" : $0.size.description }.joined(separator: "  ")
}

/// Lays rows out aligned on their widest cell, so a long family name or an extra frame does not break the columns.
func table(_ rows: [[String]], indent: String = "") -> [String] {
    guard let columns = rows.map(\.count).max() else { return [] }
    let widths = (0..<columns).map { column in
        rows.compactMap { $0.count > column ? $0[column].count : nil }.max() ?? 0
    }
    return rows.map { row in
        indent + row.enumerated().map { index, cell in
            index == row.count - 1 ? cell : cell.padding(toLength: widths[index] + 2, withPad: " ", startingAt: 0)
        }.joined()
    }
}

/// The report as lines.
func report(_ records: [Record], options: Options) -> [String] {
    var lines: [String] = []
    func print(_ text: String = "") { lines.append(text) }
    func print(_ rows: [String]) { lines += rows }
    let devices = Set(records.map(\.deviceModel)).sorted()
    let screens = Set(records.compactMap(\.screenSize)).sorted { $0.area < $1.area }
    let versions = Set(records.map(\.systemVersion)).sorted()
    let idioms = Set(records.compactMap(\.idiom)).sorted()
    let scales = Set(records.compactMap(\.displayScale)).sorted()
    let source = options.file.map { "in \($0)" } ?? "in the last \(options.window)"

    print("\(devices.joined(separator: ", "))  \(idioms.joined(separator: ", ")) \(versions.joined(separator: ", "))")
    print("screen \(screens.isEmpty ? "unknown" : screens.map(\.description).joined(separator: ", "))\(scales.isEmpty ? "" : " @\(scales.map { Size.number($0) }.joined(separator: ", "))x")")
    print("\(records.count) records \(source)")
    if devices.count > 1 || screens.count > 1 {
        print("WARNING: more than one device logged inside this window, so the frames below are mixed. Narrow --last.")
    }
    print("")

    let grouped = Dictionary(grouping: records, by: \.family)
    let families = grouped.keys.sorted()
    var rows: [[String]] = [["family"] + StageGroup.columns.map(\.heading)]
    for family in families {
        let byGroup = Dictionary(grouping: grouped[family] ?? [], by: \.group)
        let cells = StageGroup.columns.map { cell(byGroup[$0] ?? []) }
        rows.append([family] + cells)
    }
    print(table(rows))
    print("")

    /// What the capture is for: the frame a placed widget reported, and where that frame sits among the frames WidgetKit pre-rendered.
    print("Frames attributed to \(options.placement ?? "wherever you placed it"):")
    var attributed: [[String]] = []
    var ambiguous: [String] = []
    for family in families {
        let byGroup = Dictionary(grouping: grouped[family] ?? [], by: \.group)
        let placed = byGroup[.placed] ?? []
        let frames = sizes(placed)
        let pair = sizes(byGroup[.preRendered] ?? [])
        guard let frame = frames.first else { continue }
        if frames.count > 1 {
            ambiguous.append(family)
            attributed.append([family, frames.map(\.description).joined(separator: "  "), "AMBIGUOUS, see below"])
            continue
        }
        let preRendered = tally(byGroup[.preRendered] ?? [])
        let preRenderedCount = preRendered.reduce(0) { $0 + $1.count }
        var note = ""
        switch pair.count {
        case 0: note = "no pre-rendered frame to compare it with"
        case 1 where frame != pair[0]: note = "does not match the pre-rendered \(pair[0].description), worth a second run"
        case 1 where preRenderedCount > 1: note = "\(preRenderedCount) frames pre-rendered here, all the same size"
        case 1: note = "the only frame pre-rendered here"
        default:
            if frame == pair.last { note = "the largest of \(pair.count) pre-rendered sizes" }
            else if frame == pair.first { note = "the smallest of \(pair.count) pre-rendered sizes" }
            else { note = "not one of the \(pair.count) pre-rendered sizes, worth a second run" }
        }
        attributed.append([family, frame.description, "\(placed.count) record\(placed.count == 1 ? "" : "s"), \(note)"])
    }
    if attributed.isEmpty {
        print("  nothing. This window has no placed record, which is a snapshot or timeline callback with isPreview false.")
        print("  Place the probe and leave it on screen so it renders, then run this again.")
    } else {
        print(table(attributed, indent: "  "))
    }

    for family in ambiguous {
        print("")
        print("\(family) reported more than one frame from a placed widget, so this window covers more than one placement.")
        print("Narrow --last to the one you are measuring, or tell them apart by time and widget:")
        let records = (grouped[family] ?? []).filter { $0.group == .placed }.sorted { $0.timestamp < $1.timestamp }
        print(table(records.map { [$0.timestamp, $0.stage, $0.widgetKind ?? "—", $0.size?.description ?? "no size"] }, indent: "  "))
    }

    if options.showsRecords {
        print("")
        print("Every record:")
        let rows = records.sorted { $0.timestamp < $1.timestamp }.map {
            [$0.timestamp, $0.stage, $0.group?.heading ?? "unknown", $0.family, $0.size?.description ?? "no size"]
        }
        print(table(rows, indent: "  "))
    }
    return lines
}

// MARK: - Entry point

do {
    let options = try Options.parse(CommandLine.arguments)
    let captured = try options.file.map(records(file:)) ?? records(device: options.device, window: options.window)
    guard !captured.isEmpty else {
        let source = options.file.map { "in \($0)" } ?? "in the last \(options.window) on \(options.device)"
        throw ProbeError("""
            no probe records \(source).
            Check that the example app is installed, that the widget has rendered since, and that the device is the one you think it is:
              xcrun simctl list devices booted
            """)
    }
    print(report(captured, options: options).joined(separator: "\n"))
} catch let error as ProbeError {
    FileHandle.standardError.write(Data((error.description + "\n").utf8))
    exit(1)
} catch {
    FileHandle.standardError.write(Data(("\(error)\n").utf8))
    exit(1)
}
