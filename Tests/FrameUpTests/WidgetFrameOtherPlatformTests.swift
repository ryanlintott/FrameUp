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

struct WidgetFrameMacTests {
    @Test(arguments: [
        (WidgetSize.small, CGSize(width: 164, height: 164)),
        (WidgetSize.medium, CGSize(width: 344, height: 164)),
        (WidgetSize.large, CGSize(width: 344, height: 344)),
        (WidgetSize.extraLarge, CGSize(width: 704, height: 344))
    ])
    func measuredFrames(widgetSize: WidgetSize, expected: CGSize) throws {
        #expect(try #require(WidgetSize.sizesForMac(majorOSVersion: 26)[widgetSize]) == expected)
    }

    /// Widgets in a Mac Catalyst app are hosted by macOS, so a Catalyst lookup returns the macOS frames.
    @Test func macCatalystUsesTheSameFrames() throws {
        let mac = WidgetFrame.frames(platform: .mac, screenSize: .zero, majorOSVersion: 26)
        let catalyst = WidgetFrame.frames(platform: .macCatalyst, screenSize: .zero, majorOSVersion: 26)
        #expect(catalyst.isEmpty == false)
        for (widgetSize, frame) in mac {
            #expect(try #require(catalyst[widgetSize]) == frame, "\(widgetSize)")
        }
    }

    /// The frames form a grid with a 16 point gutter.
    @Test func theFramesFormAConsistentGrid() throws {
        let frames = WidgetSize.sizesForMac(majorOSVersion: 26)
        let small = try #require(frames[.small])
        let medium = try #require(frames[.medium])
        let large = try #require(frames[.large])
        let extraLarge = try #require(frames[.extraLarge])
        #expect(medium.width == small.width * 2 + 16)
        #expect(extraLarge.width == large.width * 2 + 16)
        #expect(medium.height == small.height)
        #expect(large.width == medium.width)
    }

    /// Measured on macOS 26, so an earlier version reports no frame rather than a value that may not hold.
    @Test func earlierVersionsHaveNoFrames() {
        #expect(WidgetSize.sizesForMac(majorOSVersion: 15).isEmpty)
    }

    /// macOS has no Lock Screen, so there are no accessory frames, and extraLargePortrait arrives in macOS 27 unmeasured.
    @Test func absentFamilies() {
        let frames = WidgetSize.sizesForMac(majorOSVersion: 26)
        #expect(frames[.accessoryCircular] == nil)
        #expect(frames[.accessoryRectangular] == nil)
        #expect(frames[.accessoryInline] == nil)
        #expect(frames[.extraLargePortrait] == nil)
    }

    /// A Mac widget is not placed on a screen grid, so the lookup must not depend on a screen size.
    @Test(arguments: [CGSize.zero, CGSize(width: 2560, height: 1440)])
    func theLookupIgnoresScreenSize(screenSize: CGSize) throws {
        let frames = WidgetFrame.frames(platform: .mac, screenSize: screenSize, majorOSVersion: 26)
        #expect(try #require(frames[.small]) == CGSize(width: 164, height: 164))
    }
}

