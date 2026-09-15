//
//  WidgetFrameRecord.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-08-25.
//

import SwiftUI

/// The frame of one widget size, on one screen size, in one place, from one operating system version onward.
///
/// Apple publishes widget frames in [Human Interface Guidelines: widget specifications](https://developer.apple.com/design/human-interface-guidelines/widgets#Specifications), but that table has not been updated since iOS 18. It has no row for several current iPhone screen sizes, no accessory row for iPad at all, and iOS 26 changed the frames for every iPhone screen size. Frames that Apple does not publish are measured instead. See `Measurements/` in the repository for how they are captured.
///
/// One frame per line means each value carries everything that qualifies it. A widget size that arrived in a later OS, or that only appears in one place, or that differs by display scale, is an ordinary row rather than a special case.
struct WidgetFrameRecord: Sendable {
    /// Platform this frame applies to.
    let platform: WidgetSize.Platform
    /// Widget size this frame is for.
    let widgetSize: WidgetSize
    /// The frame in points.
    let frame: CGSize
    /// Screen size in points, ignoring orientation.
    let screenSize: CGSize
    /// Lowest major OS version this frame applies to. A later frame for the same widget size, screen size and placement supersedes it.
    let minMajorOSVersion: Int
    /// Number of pixels per point on the display, matching SwiftUI's `displayScale` environment value.
    ///
    /// Not to be confused with ``WidgetFrame/scaleFactor``, which is the ratio between an iPad's Home Screen frame and its larger design canvas.
    ///
    /// A screen size in points does not imply a scale: 414x896 is a 2x screen on an iPhone 11 and a 3x screen on an iPhone 11 Pro Max, and from iOS 26 those report different frames. Nil means this frame applies at any scale, which is the case wherever a screen size is not known to split.
    let displayScale: CGFloat?
    /// Where the widget appears. A widget size can have a different frame in different places on the same device.
    let placement: WidgetPlacement
    /// Which of an iPad's two frames this is.
    ///
    /// Every platform lays a widget out on a design canvas, so that is the default. Only the iPad Home Screen scales that canvas into a smaller slot, so `.homeScreen` rows exist for iPad alone.
    let target: WidgetTarget
}

extension WidgetFrameRecord {
    /// Major version of the operating system currently running.
    ///
    /// Apple aligned version numbers across platforms in 2025, so iOS 26, iPadOS 26, macOS 26 and watchOS 26 all report 26. A Mac previewing an iPhone widget therefore selects the correct frames using its own version number.
    static var currentMajorOSVersion: Int {
        ProcessInfo.processInfo.operatingSystemVersion.majorVersion
    }

    /// Expands one group of frames that share a screen size, placement and OS version into a row for each widget size.
    static func group(
        platform: WidgetSize.Platform,
        minMajorOSVersion: Int,
        placement: WidgetPlacement,
        screenSize: (CGFloat, CGFloat),
        displayScale: CGFloat?,
        target: WidgetTarget,
        frames: [WidgetSize: (CGFloat, CGFloat)]
    ) -> [WidgetFrameRecord] {
        frames.map { widgetSize, frame in
            WidgetFrameRecord(
                platform: platform,
                widgetSize: widgetSize,
                frame: CGSize(width: frame.0, height: frame.1),
                screenSize: CGSize(width: screenSize.0, height: screenSize.1),
                minMajorOSVersion: minMajorOSVersion,
                displayScale: displayScale,
                placement: placement,
                target: target
            )
        }
    }

    /// Converts frames measured in pixels to points.
    ///
    /// Widget frames always land on a whole number of pixels, which is why a frame is fractional in points exactly when the pixel count is not divisible by the display scale. Writing the measurement in pixels keeps repeating decimals such as 176.66666… exact.
    static func framesFromPixels(displayScale: CGFloat, _ pixels: [WidgetSize: (CGFloat, CGFloat)]) -> [WidgetSize: (CGFloat, CGFloat)] {
        pixels.mapValues { ($0.0 / displayScale, $0.1 / displayScale) }
    }
}

extension WidgetFrameRecord {
    /// Frames for a device, chosen independently for each widget size.
    ///
    /// Each widget size first resolves to one placement, then to the nearest screen size that has a frame for it in that placement, by width and then by height. Resolving per widget size rather than per device means a size that has only been measured on one screen still resolves everywhere, the way the system sizes already do. Height matters because some screen widths appear more than once: 375 points is both an iPhone SE and an iPhone 11 Pro, and their frames differ by 13 points.
    ///
    /// When no placement is supplied, a size that appears both on the Home Screen and elsewhere uses its Home Screen frames. A size that only appears elsewhere uses its highest-priority available placement according to ``WidgetPlacement/defaultResolutionOrder``. Frames from another placement never participate in nearest-screen matching. The frame is then chosen by the highest OS version the supplied version satisfies, then by display scale.
    /// - Parameters:
    ///   - platform: Platform to look up.
    ///   - screenSize: Screen size in points, ignoring orientation.
    ///   - majorOSVersion: Major OS version to look up frames for.
    ///   - displayScale: Pixels per point on the display. Only 414x896 is known to need this, where a 2x iPhone 11 and a 3x iPhone 11 Pro Max report different frames from iOS 26. Nil resolves deterministically, preferring a frame that applies at any scale and otherwise the lowest scale.
    ///   - placement: Where the widget appears. Nil considers every placement, preferring the Home Screen where a widget size appears in more than one.
    ///   - target: Which of an iPad's two frames to look up. Only iPad has `.homeScreen` rows, so every other platform answers on the default design canvas.
    /// - Returns: Frames by widget size in points. Sizes with no known frame are omitted.
    static func frames(
        platform: WidgetSize.Platform,
        screenSize: CGSize,
        majorOSVersion: Int,
        displayScale: CGFloat? = nil,
        placement: WidgetPlacement? = nil,
        target: WidgetTarget = .designCanvas
    ) -> [WidgetSize: CGSize] {
        /// Widgets in a Mac Catalyst app are hosted by macOS, so they use the same frames.
        let platform = platform == .macCatalyst ? .mac : platform
        let candidates = all.filter { candidate in
            guard candidate.platform == platform,
                  candidate.target == target,
                  candidate.minMajorOSVersion <= majorOSVersion
            else { return false }
            if let placement {
                guard candidate.placement == placement else { return false }
            }
            /// A frame with no display scale applies at every scale. One with a scale only applies when the caller knows the scale and it matches.
            guard let frameScale = candidate.displayScale, let displayScale else { return true }
            return frameScale == displayScale
        }

        return Dictionary(grouping: candidates, by: \.widgetSize)
            .compactMapValues { candidates in
                guard let preferredPlacement = WidgetPlacement.defaultResolutionOrder.last(where: { placement in
                    candidates.contains { $0.placement == placement }
                }) else { return nil }
                return candidates
                    .filter { $0.placement == preferredPlacement }
                    .min { a, b in a.isBetterThan(b, for: screenSize, displayScale: displayScale) }?
                    .frame
            }
    }

    /// Ordering used to pick one frame from several that could apply.
    private func isBetterThan(_ other: WidgetFrameRecord, for screenSize: CGSize, displayScale: CGFloat?) -> Bool {
        let widthDelta = (abs(self.screenSize.width - screenSize.width), abs(other.screenSize.width - screenSize.width))
        if widthDelta.0 != widthDelta.1 { return widthDelta.0 < widthDelta.1 }

        let heightDelta = (abs(self.screenSize.height - screenSize.height), abs(other.screenSize.height - screenSize.height))
        if heightDelta.0 != heightDelta.1 { return heightDelta.0 < heightDelta.1 }

        if minMajorOSVersion != other.minMajorOSVersion { return minMajorOSVersion > other.minMajorOSVersion }

        let scaleRank = (self.scaleRank(for: displayScale), other.scaleRank(for: displayScale))
        if scaleRank.0 != scaleRank.1 { return scaleRank.0 < scaleRank.1 }

        /// Final tie break so the result never depends on the order of `all`.
        return self.screenSize.width > other.screenSize.width
    }

    /// Lower is preferred. An exact scale match beats a frame that applies at any scale, which beats a lower scale.
    private func scaleRank(for displayScale: CGFloat?) -> CGFloat {
        if let displayScale, self.displayScale == displayScale { return -2 }
        guard let frameScale = self.displayScale else { return -1 }
        return frameScale
    }
}

extension WidgetFrameRecord {
    /// The smallest and largest frame one widget size takes across every device that has one.
    struct Extremes: Sendable {
        let minimum: CGSize
        let maximum: CGSize
    }

    /// The smallest and largest known frame for every widget size.
    ///
    /// Derived from ``all`` rather than written out, so adding a measurement widens the range on its own. Maintained by hand these drifted out of step with the tables twice, most recently when `extraLargePortrait` was measured at 378.5x611.33 while its recorded maximum was still the 338x450 visionOS frame.
    ///
    /// The iPad Home Screen frames are left out because they are the design canvas scaled down, and the canvas is the size widget content is laid out in.
    ///
    /// Frames are compared by area, so the answer is always a frame some device actually reports rather than the narrowest width paired with the shortest height. A frame smaller than every other on both axes also has the smallest area, so comparing by area alone still picks the outright smallest wherever there is one.
    static let extremes: [WidgetSize: Extremes] = {
        Dictionary(grouping: all.filter { $0.target != .homeScreen }, by: \.widgetSize)
            .compactMapValues { frames in
                guard let minimum = frames.min(by: isSmaller)?.frame,
                      let maximum = frames.max(by: isSmaller)?.frame
                else { return nil }
                return Extremes(minimum: minimum, maximum: maximum)
            }
    }()

    /// Orders frames by area, falling back to width and then height so frames of equal area still order deterministically.
    private static func isSmaller(_ a: WidgetFrameRecord, _ b: WidgetFrameRecord) -> Bool {
        let area = (a.frame.width * a.frame.height, b.frame.width * b.frame.height)
        if area.0 != area.1 { return area.0 < area.1 }
        if a.frame.width != b.frame.width { return a.frame.width < b.frame.width }
        return a.frame.height < b.frame.height
    }
}
