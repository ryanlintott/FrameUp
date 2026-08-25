//
//  WidgetFrameOtherPlatformTests.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-08-25.
//

import CoreGraphics
import Testing
@testable import FrameUp

struct WidgetFrameVisionOSTests {
    @Test(arguments: [
        (WidgetSize.small, CGSize(width: 158, height: 158)),
        (WidgetSize.medium, CGSize(width: 338, height: 158)),
        (WidgetSize.large, CGSize(width: 338, height: 354)),
        (WidgetSize.extraLarge, CGSize(width: 450, height: 338)),
        (WidgetSize.extraLargePortrait, CGSize(width: 338, height: 450))
    ])
    func publishedFrames(widgetSize: WidgetSize, expected: CGSize) throws {
        #expect(try #require(WidgetSize.sizesForVisionOS()[widgetSize]) == expected)
    }

    /// visionOS has no screen size to key on, so the lookup must not depend on one.
    @Test(arguments: [CGSize.zero, CGSize(width: 1000, height: 1000)])
    func theLookupIgnoresScreenSize(screenSize: CGSize) throws {
        let frames = WidgetFrame.frames(platform: .vision, screenSize: screenSize, majorOSVersion: 26)
        #expect(try #require(frames[.small]) == CGSize(width: 158, height: 158))
    }

    /// The accessory sizes arrive in visionOS 27 but have no frame yet, so they stay absent rather than being guessed.
    @Test func accessoryFramesAreAbsent() {
        let frames = WidgetSize.sizesForVisionOS()
        #expect(frames[.accessoryCircular] == nil)
        #expect(frames[.accessoryRectangular] == nil)
    }
}

struct WidgetFrameWatchTests {
    /// Every screen size the case size mapping knows, and the frame Apple publishes for it.
    static let published: [(CGSize, CGSize)] = [
        (CGSize(width: 136, height: 170), CGSize(width: 152, height: 69.5)),
        (CGSize(width: 162, height: 197), CGSize(width: 152, height: 69.5)),
        (CGSize(width: 156, height: 195), CGSize(width: 165, height: 72.5)),
        (CGSize(width: 176, height: 215), CGSize(width: 165, height: 72.5)),
        (CGSize(width: 187, height: 223), CGSize(width: 165, height: 72.5)),
        (CGSize(width: 184, height: 224), CGSize(width: 173, height: 76.5)),
        (CGSize(width: 198, height: 242), CGSize(width: 184, height: 80.5)),
        (CGSize(width: 208, height: 248), CGSize(width: 184, height: 80.5)),
        (CGSize(width: 205, height: 251), CGSize(width: 191, height: 81.5)),
        (CGSize(width: 211, height: 257), CGSize(width: 191, height: 81.5))
    ]

    @Test(arguments: published)
    func framesByScreenSize(screenSize: CGSize, expected: CGSize) throws {
        let frames = WidgetSize.sizesForWatch(screenSize: screenSize)
        #expect(try #require(frames[.accessoryRectangular]) == expected)
    }

    /// The case size in millimetres routes to the same frames as the screen size.
    @Test(arguments: [
        (CGFloat(38), CGSize(width: 152, height: 69.5)),
        (CGFloat(40), CGSize(width: 152, height: 69.5)),
        (CGFloat(41), CGSize(width: 165, height: 72.5)),
        (CGFloat(42), CGSize(width: 165, height: 72.5)),
        (CGFloat(44), CGSize(width: 173, height: 76.5)),
        (CGFloat(45), CGSize(width: 184, height: 80.5)),
        (CGFloat(46), CGSize(width: 184, height: 80.5)),
        (CGFloat(49), CGSize(width: 191, height: 81.5))
    ])
    func framesByCaseSize(watchSize: CGFloat, expected: CGSize) throws {
        let frames = WidgetSize.sizesForWatch(watchSize: watchSize)
        #expect(try #require(frames[.accessoryRectangular]) == expected)
    }

    /// A watch released after this table was written now resolves to the nearest known screen size. The previous lookup returned nothing.
    @Test func anUnknownWatchResolvesToTheNearestKnownOne() throws {
        let frames = WidgetSize.sizesForWatch(screenSize: CGSize(width: 215, height: 262))
        #expect(try #require(frames[.accessoryRectangular]) == CGSize(width: 191, height: 81.5))
    }

    /// Apple Watch is a 2x display, so every published frame is a whole number of pixels there.
    @Test func everyWatchFrameLandsOnAWholePixelAtTwoX() {
        for stored in WidgetFrame.all where stored.platform == .watch {
            for value in [stored.frame.width, stored.frame.height] {
                let pixels = value * 2
                #expect(abs(pixels - pixels.rounded()) < 0.0001, "\(stored.screenSize) \(value)")
            }
        }
    }

    /// The 38mm Apple Watch is smaller than any case size Apple publishes, so it takes the smallest published frame.
    @Test func theSmallestWatchTakesTheSmallestPublishedFrame() throws {
        let byCase = try #require(WidgetFrame.watchRectangular(caseSize: 38))
        let byScreen = WidgetSize.sizesForWatch(screenSize: CGSize(width: 136, height: 170))
        #expect(byCase == CGSize(width: 152, height: 69.5))
        #expect(try #require(byScreen[.accessoryRectangular]) == byCase)
    }

    /// A case size larger than any Apple publishes takes the largest frame, so a future Apple Watch still reports something.
    @Test func aLargerCaseTakesTheLargestPublishedFrame() throws {
        #expect(try #require(WidgetFrame.watchRectangular(caseSize: 52)) == CGSize(width: 191, height: 81.5))
    }

    /// The published rows are the ones Apple lists, with no invented entry to catch smaller watches.
    @Test func theCaseSizeListMatchesApplesPublishedRows() {
        let published = WidgetFrame.watchRectangularByCaseSize.map(\.minCaseSize).sorted()
        #expect(published == [40, 41, 44, 45, 49])
    }
}
