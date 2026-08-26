//
//  ProbeRecord.swift
//  WidgetSizeProbe
//
//  Created by Ryan Lintott on 2026-08-24.
//

import Foundation
import os
import WidgetKit
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// One measurement of the frame WidgetKit provides for a single widget family on a single device.
///
/// Records are emitted to the unified log as one line of JSON prefixed with ``ProbeRecord/logPrefix``, so a sweep can be captured with:
///
/// ```
/// xcrun simctl spawn booted log stream --predicate 'subsystem == "com.abetterwaytodo.FrameUpExample.WidgetSizeProbe"'
/// ```
struct ProbeRecord: Codable {
    /// Marker used to find records in a log stream.
    static let logPrefix = "WIDGET_SIZE_PROBE"

    /// Device model identifier such as `iPhone17,1`. Reports the simulated device when run on a simulator.
    let deviceModel: String
    /// Operating system version such as `26.0`.
    let systemVersion: String
    /// Widget family as reported by `WidgetFamily.description`, such as `systemLarge`.
    let family: String
    /// Frame size WidgetKit reports in `TimelineProviderContext.displaySize`. Nil for records emitted while rendering.
    let displaySize: CGSize?
    /// Frame size measured inside the widget body. Nil for records emitted from a provider callback.
    let viewSize: CGSize?
    /// Provider callback or render pass that produced this record.
    let stage: String
    /// Whether WidgetKit reported this render as a preview, such as in the widget gallery.
    let isPreview: Bool?
    /// Rendering mode the widget was drawn with. The Lock Screen and StandBy in low light use `vibrant`, the Home Screen uses `fullColor` or `accented`, so this identifies where a render came from. Nil for provider callbacks, which have no environment.
    let renderingMode: String?
    /// Whether the widget was drawn with a container background. False on the Lock Screen and in StandBy. Nil for provider callbacks.
    let showsContainerBackground: Bool?
    /// Screen size ignoring orientation, the key the `WidgetSize` lookup tables switch on. Nil when it could not be read, see ``ProbeRecord/screenSize``.
    let screenSize: CGSize?
    /// Pixels per point on the display. Nil when it could not be read, see ``ProbeRecord/screenSize``.
    ///
    /// Recorded rather than inferred. A screen size in points does not imply a scale, and a frame that happens to be a whole number of points is a whole number of pixels at both 2x and 3x, so the scale cannot be recovered from the frame afterwards.
    let displayScale: CGFloat?
    /// User interface idiom as a string. Nil when it could not be read, see ``ProbeRecord/screenSize``.
    let idiom: String?
}

extension ProbeRecord {
    /// Device model identifier, reporting the simulated device rather than the host when run on a simulator.
    static var deviceModel: String {
        if let simulated = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return simulated
        }
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }
        }
    }

    /// Operating system version.
    ///
    /// Read from `ProcessInfo` rather than `UIDevice` so it is available no matter which thread the probe runs on.
    static var systemVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }

    /// Screen size ignoring orientation, matching the value `WidgetSize` uses to look up frames.
    ///
    /// `UIScreen` is main actor isolated but `TimelineProvider` callbacks make no promise about which thread they run on, so this returns nil rather than hopping actors. A run where this is always nil tells us the provider does not run on the main thread.
    static var screenSize: CGSize? {
        guard Thread.isMainThread else { return nil }
        #if canImport(UIKit)
        return MainActor.assumeIsolated { UIScreen.main.fixedCoordinateSpace.bounds.size }
        #elseif canImport(AppKit)
        return MainActor.assumeIsolated { NSScreen.main?.frame.size }
        #else
        return nil
        #endif
    }

    /// Pixels per point on the display. Nil when not read from the main thread, see ``ProbeRecord/screenSize``.
    ///
    /// Recorded rather than inferred. A screen size in points does not imply a scale, and a frame that happens to be a whole number of points is a whole number of pixels at both 2x and 3x, so the scale cannot be recovered from the frame afterwards.
    static var displayScale: CGFloat? {
        guard Thread.isMainThread else { return nil }
        #if canImport(UIKit)
        return MainActor.assumeIsolated { UIScreen.main.scale }
        #elseif canImport(AppKit)
        return MainActor.assumeIsolated { NSScreen.main?.backingScaleFactor }
        #else
        return nil
        #endif
    }

    /// User interface idiom as a string. Nil when not read from the main thread, see ``ProbeRecord/screenSize``.
    static var idiom: String? {
        #if canImport(UIKit)
        guard Thread.isMainThread else { return nil }
        return MainActor.assumeIsolated {
            switch UIDevice.current.userInterfaceIdiom {
            case .phone: "phone"
            case .pad: "pad"
            case .mac: "mac"
            case .vision: "vision"
            case .carPlay: "carPlay"
            case .tv: "tv"
            default: "unspecified"
            }
        }
        #elseif canImport(AppKit)
        return "mac"
        #else
        return nil
        #endif
    }
}

enum ProbeLog {
    static let logger = Logger(
        subsystem: "com.abetterwaytodo.FrameUpExample.WidgetSizeProbe",
        category: "measurement"
    )

    /// Emits one record to the unified log as a single line of JSON.
    static func emit(_ record: ProbeRecord) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard
            let data = try? encoder.encode(record),
            let json = String(data: data, encoding: .utf8)
        else {
            logger.error("\(ProbeRecord.logPrefix, privacy: .public) failed to encode record")
            return
        }
        logger.log("\(ProbeRecord.logPrefix, privacy: .public) \(json, privacy: .public)")
    }

    /// Emits a record for a provider callback.
    static func emit(family: String, displaySize: CGSize, isPreview: Bool, stage: String) {
        emit(
            ProbeRecord(
                deviceModel: ProbeRecord.deviceModel,
                systemVersion: ProbeRecord.systemVersion,
                family: family,
                displaySize: displaySize,
                viewSize: nil,
                stage: stage,
                isPreview: isPreview,
                renderingMode: nil,
                showsContainerBackground: nil,
                screenSize: ProbeRecord.screenSize,
                displayScale: ProbeRecord.displayScale,
                idiom: ProbeRecord.idiom
            )
        )
    }

    /// Emits a record for a frame measured while rendering the widget body.
    static func emit(family: String, viewSize: CGSize, renderingMode: String, showsContainerBackground: Bool) {
        emit(
            ProbeRecord(
                deviceModel: ProbeRecord.deviceModel,
                systemVersion: ProbeRecord.systemVersion,
                family: family,
                displaySize: nil,
                viewSize: viewSize,
                stage: "render",
                isPreview: nil,
                renderingMode: renderingMode,
                showsContainerBackground: showsContainerBackground,
                screenSize: ProbeRecord.screenSize,
                displayScale: ProbeRecord.displayScale,
                idiom: ProbeRecord.idiom
            )
        )
    }
}
