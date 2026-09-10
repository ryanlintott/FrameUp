//
//  WidgetSizeExtremesTests.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-08-26.
//

import CoreGraphics
import Testing
@testable import FrameUp

/// `minimumSize` and `maximumSize` are derived from the frame tables, so these check the derivation rather than a list of expected numbers, which is what drifted out of date when the values were maintained by hand.
struct WidgetSizeExtremesTests {
    /// Every widget size with a frame has extremes. `accessoryCorner` is the one case with no frame anywhere, so it is the one case the zero fallback in `minimumSize` and `maximumSize` is reachable for.
    @Test(arguments: WidgetSize.allCases)
    func everyWidgetSizeWithAFrameHasExtremes(widgetSize: WidgetSize) {
        guard widgetSize != .accessoryCorner else {
            #expect(WidgetFrameRecord.extremes[widgetSize] == nil)
            #expect(widgetSize.minimumSize == .zero)
            #expect(widgetSize.maximumSize == .zero)
            return
        }
        #expect(WidgetFrameRecord.extremes[widgetSize] != nil)
        #expect(widgetSize.minimumSize != .zero)
        #expect(widgetSize.maximumSize != .zero)
    }

    /// No frame in the tables is smaller or larger by area than the range reported for its widget size.
    @Test(arguments: WidgetSize.allCases)
    func noFrameFallsOutsideTheReportedRange(widgetSize: WidgetSize) {
        guard widgetSize != .accessoryCorner else { return }
        let area = { (size: CGSize) in size.width * size.height }
        let frames = WidgetFrameRecord.all.filter { $0.widgetSize == widgetSize && $0.target != .homeScreen }
        for frame in frames {
            #expect(area(frame.frame) >= area(widgetSize.minimumSize), "\(frame.platform) \(frame.screenSize)")
            #expect(area(frame.frame) <= area(widgetSize.maximumSize), "\(frame.platform) \(frame.screenSize)")
        }
    }

    /// Both extremes are frames a real device reports rather than a mix of the narrowest width and the shortest height.
    @Test(arguments: WidgetSize.allCases)
    func bothExtremesAreRealFrames(widgetSize: WidgetSize) {
        guard widgetSize != .accessoryCorner else { return }
        let frames = WidgetFrameRecord.all.filter { $0.widgetSize == widgetSize && $0.target != .homeScreen }.map(\.frame)
        #expect(frames.contains(widgetSize.minimumSize))
        #expect(frames.contains(widgetSize.maximumSize))
    }

    /// The iPad Home Screen frames are the design canvas scaled down, so they are left out of the range. The narrowest of them is well below the reported minimum, which would not be true if they counted.
    @Test func iPadHomeScreenFramesAreExcluded() throws {
        let narrowest = try #require(
            WidgetFrameRecord.all
                .filter { $0.platform == .pad && $0.widgetSize == .small && $0.target == .homeScreen }
                .map(\.frame.width)
                .min()
        )
        #expect(narrowest < WidgetSize.small.minimumSize.width)
    }

    /// A spot check that the derivation reaches across platforms: the roomiest `accessoryRectangular` is an Apple Watch Ultra 3 face complication and the tightest is an iPad Lock Screen.
    @Test func accessoryRectangularSpansEveryPlatform() {
        #expect(WidgetSize.accessoryRectangular.maximumSize == CGSize(width: 199, height: 84.5))
        #expect(WidgetSize.accessoryRectangular.minimumSize == CGSize(width: 133, height: 53.5))
    }
}
