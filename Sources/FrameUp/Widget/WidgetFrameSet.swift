//
//  WidgetFrameSet.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-08-25.
//

import SwiftUI

/// Widget frames for one screen size on one platform, from one operating system version onward.
///
/// Apple publishes widget frames in [Human Interface Guidelines: widget specifications](https://developer.apple.com/design/human-interface-guidelines/widgets#Specifications), but that table has not been updated since iOS 18. It has no row for several current iPhone screen sizes, and iOS 26 changed the frames for every iPhone screen size. Frames for iOS 26 and later are therefore measured rather than published. See `Measurements/` in the repository for the raw data and how it was captured.
///
/// A frame depends on the screen size and the operating system version, not on the device model. Two devices that report the same screen size on the same OS report the same widget frames.
struct WidgetFrameSet: Sendable {
    /// Platform these frames apply to.
    let platform: WidgetSize.Platform
    /// Screen size ignoring orientation.
    let screenSize: CGSize
    /// Lowest major OS version these frames apply to. A later set for the same screen size supersedes this one.
    let minMajorOSVersion: Int
    /// Widget frame target. Only iPad distinguishes a design canvas from the smaller Home Screen frame, so this is nil on every other platform.
    let target: WidgetTarget?
    /// Frames by widget size. Sizes with no known frame are omitted rather than guessed.
    let frames: [WidgetSize: CGSize]

    init(
        platform: WidgetSize.Platform,
        screenSize: CGSize,
        minMajorOSVersion: Int,
        target: WidgetTarget? = nil,
        frames: [WidgetSize: CGSize]
    ) {
        self.platform = platform
        self.screenSize = screenSize
        self.minMajorOSVersion = minMajorOSVersion
        self.target = target
        self.frames = frames
    }
}

extension WidgetFrameSet {
    /// Major version of the operating system currently running.
    ///
    /// Apple aligned version numbers across platforms in 2025, so iOS 26, iPadOS 26, macOS 26 and watchOS 26 all report 26. A Mac previewing an iPhone widget therefore selects the correct frames using its own version number.
    static var currentMajorOSVersion: Int {
        ProcessInfo.processInfo.operatingSystemVersion.majorVersion
    }

    /// Builds frames from pixel measurements.
    ///
    /// Widget frames always land on a whole number of pixels, which is why a frame is fractional in points exactly when the pixel count is not divisible by the scale factor. Storing the measurement in pixels keeps repeating decimals such as 176.66666… exact.
    static func framesFromPixels(scale: CGFloat, _ pixels: [WidgetSize: (CGFloat, CGFloat)]) -> [WidgetSize: CGSize] {
        pixels.mapValues { CGSize(width: $0.0 / scale, height: $0.1 / scale) }
    }

    /// Builds frames from point values.
    static func framesFromPoints(_ points: [WidgetSize: (CGFloat, CGFloat)]) -> [WidgetSize: CGSize] {
        points.mapValues { CGSize(width: $0.0, height: $0.1) }
    }
}

extension WidgetFrameSet {
    /// Frames for the screen size closest to the one supplied.
    ///
    /// Matching is by nearest width, then nearest height where widths tie. Height matters because some screen widths appear more than once: 375 points is both an iPhone SE and an iPhone 11 Pro, and their widget frames differ by 13 points.
    ///
    /// Sets layer rather than replace. Where several sets exist for one screen size, every set the supplied version satisfies is applied in order, so a newer set only needs to list the frames that changed. A widget size the newer set does not mention keeps the frame from the older set.
    /// - Parameters:
    ///   - platform: Platform to look up.
    ///   - screenSize: Screen size ignoring orientation.
    ///   - majorOSVersion: Major OS version to look up frames for.
    ///   - target: Widget frame target. Only used on iPad.
    /// - Returns: Frames by widget size. Empty if no frames are known for this platform.
    static func frames(
        platform: WidgetSize.Platform,
        screenSize: CGSize,
        majorOSVersion: Int,
        target: WidgetTarget? = nil
    ) -> [WidgetSize: CGSize] {
        let candidates = all.filter {
            $0.platform == platform && $0.target == target && $0.minMajorOSVersion <= majorOSVersion
        }
        guard let nearest = candidates.map(\.screenSize).min(by: { a, b in
            let widthA = abs(a.width - screenSize.width)
            let widthB = abs(b.width - screenSize.width)
            if widthA != widthB { return widthA < widthB }
            let heightA = abs(a.height - screenSize.height)
            let heightB = abs(b.height - screenSize.height)
            if heightA != heightB { return heightA < heightB }
            /// Final tie break so the result never depends on the order of `all`.
            return a.width > b.width
        }) else { return [:] }

        return candidates
            .filter { $0.screenSize == nearest }
            .sorted { $0.minMajorOSVersion < $1.minMajorOSVersion }
            .reduce(into: [WidgetSize: CGSize]()) { result, set in
                result.merge(set.frames) { _, newer in newer }
            }
    }
}
