//
//  WidgetSize+Supported.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-09-09.
//

import SwiftUI

public extension WidgetSize {
    /// Widget sizes a platform can show on a given OS version.
    ///
    /// This is a different question from whether FrameUp knows the frame. A size listed here may still have no frame, in which case ``frame(platform:screenSize:majorOSVersion:displayScale:placement:)`` returns nil and ``minimumSize`` or ``maximumSize`` can be used as a fallback. See ``WidgetSize`` for the sizes that are supported but not yet measured.
    /// - Parameters:
    ///   - platform: Platform the widget appears on.
    ///   - majorOSVersion: Major OS version to report support for. Nil uses the version currently running.
    /// - Returns: Every widget size that platform and version can show.
    static func supportedSizes(platform: Platform, majorOSVersion: Int? = nil) -> [WidgetSize] {
        let majorOSVersion = majorOSVersion ?? WidgetFrameRecord.currentMajorOSVersion

        return switch platform {
        case .phone:
            if majorOSVersion >= 27 {
                [.small, .medium, .large, .extraLargePortrait, .accessoryCircular, .accessoryRectangular, .accessoryInline]
            } else if majorOSVersion >= 16 {
                [.small, .medium, .large, .accessoryCircular, .accessoryRectangular, .accessoryInline]
            } else {
                [.small, .medium, .large]
            }
        case .pad:
            if majorOSVersion >= 27 {
                [.small, .medium, .large, .extraLarge, .extraLargePortrait, .accessoryCircular, .accessoryRectangular, .accessoryInline]
            } else if majorOSVersion >= 16 {
                [.small, .medium, .large, .extraLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline]
            } else {
                [.small, .medium, .large, .extraLarge]
            }
        case .mac, .macCatalyst:
            // Widgets in a Mac Catalyst app are hosted by macOS, so the sizes match `mac` and no accessory sizes are available.
            // Mac Catalyst has its own version numbers, but a Catalyst process reports the macOS version it is running on, which is the one compared here. macCatalyst 17 is macOS 14 and macCatalyst 27 is macOS 27.
            if majorOSVersion >= 27 {
                [.small, .medium, .large, .extraLarge, .extraLargePortrait]
            } else if majorOSVersion >= 14 {
                [.small, .medium, .large, .extraLarge]
            } else {
                [.small, .medium, .large]
            }
        case .vision:
            if majorOSVersion >= 27 {
                [.small, .medium, .large, .extraLarge, .extraLargePortrait, .accessoryCircular, .accessoryRectangular]
            } else if majorOSVersion >= 26 {
                /// Widgets arrive on visionOS in version 26.
                [.small, .medium, .large, .extraLarge, .extraLargePortrait]
            } else {
                []
            }
        case .watch:
            /// Every size an Apple Watch shows arrived with the Smart Stack in watchOS 9, which is FrameUp's minimum.
            [.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner]
        case .carPlay:
            if majorOSVersion >= 26 {
                [.small, .medium, .accessoryCircular, .accessoryRectangular, .accessoryInline]
            } else {
                []
            }
        case .unsupported:
            []
        }
    }

    /// Supported widget sizes for the current device.
    ///
    /// This reports what the current platform and OS version support, not what FrameUp can measure. A size listed here may still have no frame, in which case `frameForCurrentDevice` returns nil and ``minimumSize`` or ``maximumSize`` can be used as a fallback. See ``WidgetSize`` for the sizes that are supported but not yet measured.
    @preconcurrency @MainActor
    static var supportedSizesForCurrentDevice: [WidgetSize] {
        supportedSizes(platform: .current)
    }
}
