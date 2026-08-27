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
    /// Measured on Apple Vision Pro on visionOS 26.5 and 27.0. Only `small` matches the value Apple publishes.
    @Test(arguments: [
        (WidgetSize.small, CGSize(width: 158, height: 158)),
        (WidgetSize.medium, CGSize(width: 354, height: 158)),
        (WidgetSize.large, CGSize(width: 354, height: 354)),
        (WidgetSize.extraLarge, CGSize(width: 550, height: 354)),
        (WidgetSize.extraLargePortrait, CGSize(width: 354, height: 550))
    ])
    func measuredFrames(widgetSize: WidgetSize, expected: CGSize) throws {
        #expect(try #require(WidgetSize.sizesForVisionOS(majorOSVersion: 26)[widgetSize]) == expected)
    }

    /// Every system frame lands on a grid of 158 point cells with a 38 point gutter, so one, two and three cells are 158, 354 and 550 points.
    @Test func systemFramesLandOnTheCellGrid() {
        let cells: Set<CGFloat> = [158, 354, 550]
        let frames = WidgetFrame.all.filter { $0.platform == .vision && !$0.widgetSize.rawValue.hasPrefix("accessory") }
        #expect(frames.count == 5)
        for frame in frames {
            #expect(cells.contains(frame.frame.width), "\(frame.widgetSize) width")
            #expect(cells.contains(frame.frame.height), "\(frame.widgetSize) height")
        }
    }

    /// visionOS has no screen size to key on, so the lookup must not depend on one.
    @Test(arguments: [CGSize.zero, CGSize(width: 1000, height: 1000)])
    func theLookupIgnoresScreenSize(screenSize: CGSize) throws {
        let frames = WidgetFrame.frames(platform: .vision, screenSize: screenSize, majorOSVersion: 26)
        #expect(try #require(frames[.small]) == CGSize(width: 158, height: 158))
    }

    /// The accessory sizes arrive in visionOS 27. A 26.5 sweep offered every other family and not these, which is what pins the version.
    @Test func accessoryFramesStartAtVisionOS27() throws {
        let visionOS26 = WidgetSize.sizesForVisionOS(majorOSVersion: 26)
        #expect(visionOS26[.accessoryCircular] == nil)
        #expect(visionOS26[.accessoryRectangular] == nil)

        let visionOS27 = WidgetSize.sizesForVisionOS(majorOSVersion: 27)
        #expect(try #require(visionOS27[.accessoryCircular]) == CGSize(width: 75, height: 75))
        #expect(try #require(visionOS27[.accessoryRectangular]) == CGSize(width: 208, height: 79))
    }

    /// visionOS has no `accessoryInline` case in its SDK, so it must never resolve to a frame there.
    @Test func inlineAccessoryDoesNotExistOnVisionOS() {
        #expect(WidgetSize.accessoryInline.sizeForVisionOS(majorOSVersion: 27) == nil)
    }

    /// Widgets arrived on visionOS in version 26, so nothing resolves before it.
    @Test func noFramesBeforeVisionOS26() {
        #expect(WidgetSize.sizesForVisionOS(majorOSVersion: 2).isEmpty)
    }
}

struct WidgetFrameWatchTests {
    /// The Smart Stack frame for every screen size the case size mapping knows.
    ///
    /// The five measured watches carry their measured frame; the rest keep the value Apple publishes for their case size.
    static let smartStack: [(CGSize, CGSize)] = [
        (CGSize(width: 136, height: 170), CGSize(width: 152, height: 69.5)),
        (CGSize(width: 162, height: 197), CGSize(width: 152, height: 69.5)),   // measured, matches published
        (CGSize(width: 156, height: 195), CGSize(width: 165, height: 72.5)),
        (CGSize(width: 176, height: 215), CGSize(width: 165, height: 72.5)),
        (CGSize(width: 187, height: 223), CGSize(width: 176, height: 72.5)),   // measured, no published row
        (CGSize(width: 184, height: 224), CGSize(width: 173, height: 76.5)),   // measured, matches published
        (CGSize(width: 198, height: 242), CGSize(width: 184, height: 80.5)),
        (CGSize(width: 208, height: 248), CGSize(width: 194, height: 80.5)),   // measured, no published row
        (CGSize(width: 205, height: 251), CGSize(width: 191, height: 81.5)),   // Ultra 2, published
        (CGSize(width: 211, height: 257), CGSize(width: 197, height: 84))      // Ultra 3, measured
    ]

    @Test(arguments: smartStack)
    func framesByScreenSize(screenSize: CGSize, expected: CGSize) throws {
        let frames = WidgetSize.sizesForWatch(screenSize: screenSize)
        #expect(try #require(frames[.accessoryRectangular]) == expected)
    }

    /// Both 49mm, different screens, different frames. Case size alone cannot tell them apart, which is why the rows are keyed on screen size.
    @Test func theTwoUltrasDoNotShareAFrame() throws {
        let ultra2 = WidgetSize.sizesForWatch(screenSize: CGSize(width: 205, height: 251))
        let ultra3 = WidgetSize.sizesForWatch(screenSize: CGSize(width: 211, height: 257))
        #expect(try #require(ultra2[.accessoryRectangular]) == CGSize(width: 191, height: 81.5))
        #expect(try #require(ultra3[.accessoryRectangular]) == CGSize(width: 197, height: 84))
    }

    /// A watch face complication is a different size from a Smart Stack widget on the same watch. These are the two watches where a placed widget confirmed both frames.
    @Test(arguments: [
        (CGSize(width: 162, height: 197), CGSize(width: 152, height: 69.5), CGSize(width: 162, height: 69), CGSize(width: 42, height: 42)),
        (CGSize(width: 184, height: 224), CGSize(width: 173, height: 76.5), CGSize(width: 184, height: 78), CGSize(width: 47, height: 47))
    ])
    func theWatchFaceFrameDiffersFromTheSmartStack(
        screenSize: CGSize,
        expectedSmartStack: CGSize,
        expectedWatchFace: CGSize,
        expectedCircular: CGSize
    ) throws {
        let smartStack = WidgetFrame.frames(platform: .watch, screenSize: screenSize, majorOSVersion: 27, placement: .smartStack)
        let watchFace = WidgetFrame.frames(platform: .watch, screenSize: screenSize, majorOSVersion: 27, placement: .watchFace)
        #expect(try #require(smartStack[.accessoryRectangular]) == expectedSmartStack)
        #expect(try #require(watchFace[.accessoryRectangular]) == expectedWatchFace)
        #expect(try #require(watchFace[.accessoryCircular]) == expectedCircular)
    }

    /// `accessoryCircular` is only recorded against the watch face, which is the only place it was observed placed, so a Smart Stack lookup has no frame for it.
    @Test func circularIsWatchFaceOnly() {
        let smartStack = WidgetFrame.frames(platform: .watch, screenSize: CGSize(width: 184, height: 224), majorOSVersion: 27, placement: .smartStack)
        #expect(smartStack[.accessoryCircular] == nil)
    }

    /// The 42mm watch pre-renders only one rectangular frame, so no watch face frame is invented for it. It resolves to the nearest watch that has one instead of duplicating its own Smart Stack value.
    @Test func theFortyTwoMillimetreWatchHasNoOwnWatchFaceRectangle() {
        let stored = WidgetFrame.all.filter {
            $0.platform == .watch
            && $0.placement == .watchFace
            && $0.widgetSize == .accessoryRectangular
            && $0.screenSize == CGSize(width: 187, height: 223)
        }
        #expect(stored.isEmpty)
    }

    /// Only the 44mm was measured with a placed widget. Every other watch face frame applies the rule that measurement established, so the rows must stay in step with it: the watch face frame is the larger of the pair.
    @Test func everyWatchFaceFrameIsLargerThanItsSmartStackFrame() throws {
        for row in WidgetFrame.all where row.platform == .watch && row.placement == .watchFace && row.widgetSize == .accessoryRectangular {
            let smartStack = WidgetFrame.frames(
                platform: .watch,
                screenSize: row.screenSize,
                majorOSVersion: 27,
                placement: .smartStack
            )
            let paired = try #require(smartStack[.accessoryRectangular])
            #expect(row.frame.width > paired.width, "\(row.screenSize)")
        }
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
        #expect(try #require(frames[.accessoryRectangular]) == CGSize(width: 197, height: 84))
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

