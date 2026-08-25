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
    /// Screen size in points, ignoring orientation.
    let screenSize: CGSize
    /// Number of pixels per point on the display, matching SwiftUI's `displayScale` environment value. Two on a 2x device, three on a 3x device.
    ///
    /// Not to be confused with ``WidgetSize/scaleFactorForiPad(screenSize:)``, which is the ratio between an iPad's Home Screen frame and its larger design canvas.
    ///
    /// A screen size in points does not imply a scale: 414x896 is a 2x screen on an iPhone 11 and a 3x screen on an iPhone 11 Pro Max, and from iOS 26 those two report different widget frames. Nil means these frames apply at any scale, which is the case wherever a screen size is not known to split.
    let displayScale: CGFloat?
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
        displayScale: CGFloat? = nil,
        target: WidgetTarget? = nil,
        frames: [WidgetSize: CGSize]
    ) {
        self.platform = platform
        self.screenSize = screenSize
        self.displayScale = displayScale
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
    /// Widget frames always land on a whole number of pixels, which is why a frame is fractional in points exactly when the pixel count is not divisible by the display scale. Writing the measurement in pixels keeps repeating decimals such as 176.66666… exact. The frames themselves are stored in points.
    static func framesFromPixels(displayScale: CGFloat, _ pixels: [WidgetSize: (CGFloat, CGFloat)]) -> [WidgetSize: CGSize] {
        pixels.mapValues { CGSize(width: $0.0 / displayScale, height: $0.1 / displayScale) }
    }

    /// Builds frames from point values.
    static func framesFromPoints(_ points: [WidgetSize: (CGFloat, CGFloat)]) -> [WidgetSize: CGSize] {
        points.mapValues { CGSize(width: $0.0, height: $0.1) }
    }
}

extension WidgetFrameSet {
    /// Frames for the screen size closest to the one supplied.
    ///
    /// Matching is by nearest width, then nearest height where widths tie. Height matters because some screen widths appear more than once: 375 points is both an iPhone SE and an iPhone 11 Pro, and their frames differ by 13 points.
    ///
    /// Sets layer rather than replace. Where several sets exist for one screen size, every set the supplied version satisfies is applied in order, so a newer set only needs to list the frames that changed. A widget size the newer set does not mention keeps the frame from the older set.
    /// - Parameters:
    ///   - platform: Platform to look up.
    ///   - screenSize: Screen size in points, ignoring orientation.
    ///   - majorOSVersion: Major OS version to look up frames for.
    ///   - displayScale: Pixels per point on the display. Only 414x896 is known to need this, where a 2x iPhone 11 and a 3x iPhone 11 Pro Max report different frames from iOS 26. Nil resolves deterministically, preferring a set that applies at any scale and otherwise the lowest scale, so a caller that cannot know the scale still gets a stable answer.
    ///   - target: Widget frame target. Only used on iPad.
    /// - Returns: Frames by widget size in points. Empty if no frames are known for this platform.
    static func frames(
        platform: WidgetSize.Platform,
        screenSize: CGSize,
        majorOSVersion: Int,
        displayScale: CGFloat? = nil,
        target: WidgetTarget? = nil
    ) -> [WidgetSize: CGSize] {
        let candidates = all.filter { set in
            guard set.platform == platform,
                  set.target == target,
                  set.minMajorOSVersion <= majorOSVersion
            else { return false }
            /// A set with no display scale applies at every scale. A set with one only applies when the caller knows the scale and it matches.
            guard let setScale = set.displayScale else { return true }
            guard let displayScale else { return true }
            return setScale == displayScale
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

        let matching = candidates.filter { $0.screenSize == nearest }
        let byVersion = Dictionary(grouping: matching, by: \.minMajorOSVersion)
        return byVersion.keys.sorted().reduce(into: [WidgetSize: CGSize]()) { result, version in
            guard let sets = byVersion[version],
                  let set = resolve(sets, displayScale: displayScale)
            else { return }
            result.merge(set.frames) { _, newer in newer }
        }
    }

    /// Chooses one set from several that share a screen size and OS version but differ by display scale.
    private static func resolve(_ sets: [WidgetFrameSet], displayScale: CGFloat?) -> WidgetFrameSet? {
        if let displayScale, let exact = sets.first(where: { $0.displayScale == displayScale }) {
            return exact
        }
        if let anyScale = sets.first(where: { $0.displayScale == nil }) {
            return anyScale
        }
        return sets.min { ($0.displayScale ?? 0) < ($1.displayScale ?? 0) }
    }
}
