//
//  WidgetFrameiPadTests.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-08-25.
//

import CoreGraphics
import Testing
@testable import FrameUp

struct WidgetFrameiPadTests {
    /// One published iPad row, both targets.
    struct Row: Sendable, CustomStringConvertible {
        let screenSize: CGSize
        let canvas: [CGSize]
        let homeScreen: [CGSize]

        init(_ width: CGFloat, _ height: CGFloat, canvas: [CGSize], homeScreen: [CGSize]) {
            self.screenSize = CGSize(width: width, height: height)
            self.canvas = canvas
            self.homeScreen = homeScreen
        }

        var description: String { "\(Int(screenSize.width))x\(Int(screenSize.height))" }
    }

    static func s(_ w: CGFloat, _ h: CGFloat) -> CGSize { CGSize(width: w, height: h) }

    /// Transcribed independently from Apple's published table so a mistake in the frame table does not agree with a matching mistake here.
    static let published: [Row] = [
        .init(1192, 1590, canvas: [s(188, 188), s(412, 188), s(412, 412), s(860, 412)],
                          homeScreen: [s(188, 188), s(412, 188), s(412, 412), s(860, 412)]),
        .init(1024, 1366, canvas: [s(170, 170), s(378.5, 170), s(378.5, 378.5), s(795, 378.5)],
                          homeScreen: [s(160, 160), s(356, 160), s(356, 356), s(748, 356)]),
        .init(970, 1389, canvas: [s(162, 162), s(350, 162), s(350, 350), s(726, 350)],
                         homeScreen: [s(162, 162), s(350, 162), s(350, 350), s(726, 350)]),
        .init(954, 1373, canvas: [s(162, 162), s(350, 162), s(350, 350), s(726, 350)],
                         homeScreen: [s(162, 162), s(350, 162), s(350, 350), s(726, 350)]),
        .init(834, 1194, canvas: [s(155, 155), s(342, 155), s(342, 342), s(715.5, 342)],
                         homeScreen: [s(136, 136), s(300, 136), s(300, 300), s(628, 300)]),
        .init(834, 1112, canvas: [s(150, 150), s(327.5, 150), s(327.5, 327.5), s(682, 327.5)],
                         homeScreen: [s(132, 132), s(288, 132), s(288, 288), s(600, 288)]),
        .init(820, 1180, canvas: [s(155, 155), s(342, 155), s(342, 342), s(715.5, 342)],
                         homeScreen: [s(136, 136), s(300, 136), s(300, 300), s(628, 300)]),
        .init(810, 1080, canvas: [s(146, 146), s(320.5, 146), s(320.5, 320.5), s(669, 320.5)],
                         homeScreen: [s(124, 124), s(272, 124), s(272, 272), s(568, 272)]),
        .init(768, 1024, canvas: [s(141, 141), s(305.5, 141), s(305.5, 305.5), s(634.5, 305.5)],
                         homeScreen: [s(120, 120), s(260, 120), s(260, 260), s(540, 260)]),
        .init(744, 1133, canvas: [s(141, 141), s(305.5, 141), s(305.5, 305.5), s(634.5, 305.5)],
                         homeScreen: [s(120, 120), s(260, 120), s(260, 260), s(540, 260)])
    ]

    static let systemSizes: [WidgetSize] = [.small, .medium, .large, .extraLarge]

    @Test(arguments: published)
    func publishedFramesMatchTheTable(row: Row) throws {
        let frames = WidgetSize.frames(platform: .pad, screenSize: row.screenSize, majorOSVersion: 18)
        for (index, widgetSize) in Self.systemSizes.enumerated() {
            let frame = try #require(frames[widgetSize])
            #expect(frame.canvasSize == row.canvas[index], "\(row) canvas \(widgetSize)")
            #expect(frame.renderedSize == row.homeScreen[index], "\(row) rendered \(widgetSize)")
        }
    }

    /// The design canvas is larger than the Home Screen frame wherever the two differ, never smaller.
    @Test(arguments: published)
    func theDesignCanvasIsNeverSmallerThanTheHomeScreenFrame(row: Row) throws {
        let frames = WidgetSize.frames(platform: .pad, screenSize: row.screenSize, majorOSVersion: 18)
        for widgetSize in Self.systemSizes {
            let frame = try #require(frames[widgetSize])
            #expect(frame.canvasSize.width >= frame.renderedSize.width)
            #expect(frame.canvasSize.height >= frame.renderedSize.height)
        }
    }

    /// A 820x1180 iPad reports a 155 point small widget on the Home Screen and 152 on the Lock Screen, both measured.
    @Test func theLockScreenSmallFrameDiffersFromTheHomeScreenOne() throws {
        let screen = CGSize(width: 820, height: 1180)
        let home = WidgetSize.frames(platform: .pad, screenSize: screen, majorOSVersion: 26, placement: .homeScreen)
        let lock = WidgetSize.frames(platform: .pad, screenSize: screen, majorOSVersion: 26, placement: .lockScreen)
        #expect(try #require(home[.small]).canvasSize == CGSize(width: 155, height: 155))
        #expect(try #require(lock[.small]).canvasSize == CGSize(width: 152, height: 152))
    }

    /// Apple publishes no accessory frames for iPad. These were measured.
    @Test(arguments: [
        (WidgetSize.accessoryCircular, CGSize(width: 63, height: 63)),
        (WidgetSize.accessoryRectangular, CGSize(width: 152, height: 63)),
        (WidgetSize.accessoryInline, CGSize(width: 372, height: 36))
    ])
    func accessoryFramesAreAvailable(widgetSize: WidgetSize, expected: CGSize) throws {
        let frames = WidgetSize.frames(
            platform: .pad,
            screenSize: CGSize(width: 820, height: 1180),
            majorOSVersion: 26
        )
        #expect(try #require(frames[widgetSize]).canvasSize == expected)
    }

    /// iPad Lock Screen widgets are not known before iPadOS 18, so an older lookup reports none.
    @Test func accessoryFramesAreAbsentBeforeiPadOS18() {
        let frames = WidgetSize.frames(
            platform: .pad,
            screenSize: CGSize(width: 820, height: 1180),
            majorOSVersion: 17
        )
        #expect(frames[.accessoryCircular] == nil)
        #expect(frames[.small]?.canvasSize == CGSize(width: 155, height: 155))
    }

    /// iPad frames did not change in iOS 26, so a lookup returns the same values on either side of that boundary.
    @Test(arguments: published)
    func iPadFramesAreTheSameBeforeAndAfteriOS26(row: Row) throws {
        let before = WidgetSize.frames(platform: .pad, screenSize: row.screenSize, majorOSVersion: 18, placement: .homeScreen)
        let after = WidgetSize.frames(platform: .pad, screenSize: row.screenSize, majorOSVersion: 26, placement: .homeScreen)
        for widgetSize in Self.systemSizes {
            /// Comparing the whole frame covers both the design canvas and the rendered size.
            #expect(try #require(before[widgetSize]) == #require(after[widgetSize]))
        }
    }

    @Test func everyPublishedFrameLandsOnAWholePixelAtTwoX() {
        for stored in WidgetFrameRecord.all where stored.platform == .pad {
            for value in [stored.frame.width, stored.frame.height] {
                let pixels = value * 2
                #expect(
                    abs(pixels - pixels.rounded()) < 0.0001,
                    "\(stored.screenSize) \(stored.widgetSize) has \(value) points, which is not a whole pixel at 2x"
                )
            }
        }
    }

    /// Each iPad has its own measured accessory frames rather than borrowing another iPad's.
    @Test(arguments: [
        (CGFloat(1032), CGSize(width: 60, height: 60)),
        (CGFloat(1024), CGSize(width: 59.5, height: 59.5)),
        (CGFloat(834), CGSize(width: 61, height: 61)),
        (CGFloat(820), CGSize(width: 63, height: 63)),
        (CGFloat(810), CGSize(width: 58, height: 58)),
        (CGFloat(768), CGSize(width: 53, height: 53)),
        (CGFloat(744), CGSize(width: 53.5, height: 53.5))
    ])
    func accessoryFramesAreMeasuredPerScreenSize(width: CGFloat, expected: CGSize) throws {
        let frames = WidgetSize.frames(
            platform: .pad,
            screenSize: CGSize(width: width, height: width * 1.4),
            majorOSVersion: 26
        )
        #expect(try #require(frames[.accessoryCircular]).canvasSize == expected)
    }

    /// On every iPad the Lock Screen systemSmall is exactly as wide as accessoryRectangular. The Lock Screen widget column is that wide and a system small is sized to fit it.
    @Test func theLockScreenSmallMatchesTheRectangularWidth() throws {
        /// CGSize is only Hashable from macOS 15, so the screen sizes are deduplicated by description.
        var seen: Set<String> = []
        let screenSizes = WidgetFrameRecord.all
            .filter { $0.platform == .pad && $0.placement == .lockScreen }
            .map(\.screenSize)
            .filter { seen.insert("\($0)").inserted }
        #expect(screenSizes.count >= 8)
        for screenSize in screenSizes {
            let frames = WidgetSize.frames(
                platform: .pad,
                screenSize: screenSize,
                majorOSVersion: 26,
                placement: .lockScreen
            )
            let small = try #require(frames[.small]).canvasSize
            let rectangular = try #require(frames[.accessoryRectangular]).canvasSize
            #expect(small.width == rectangular.width, "\(screenSize)")
            #expect(small.width == small.height, "\(screenSize)")
        }
    }

    /// The Lock Screen small is a different frame from the Home Screen one, and is not always smaller.
    @Test(arguments: [
        (CGSize(width: 820, height: 1180), CGSize(width: 155, height: 155), CGSize(width: 152, height: 152)),
        (CGSize(width: 834, height: 1112), CGSize(width: 150, height: 150), CGSize(width: 152, height: 152)),
        (CGSize(width: 744, height: 1133), CGSize(width: 141, height: 141), CGSize(width: 133, height: 133))
    ])
    func lockScreenAndHomeScreenSmallDiffer(screenSize: CGSize, home: CGSize, lock: CGSize) throws {
        let onHome = WidgetSize.frames(platform: .pad, screenSize: screenSize, majorOSVersion: 26, placement: .homeScreen)
        let onLock = WidgetSize.frames(platform: .pad, screenSize: screenSize, majorOSVersion: 26, placement: .lockScreen)
        #expect(try #require(onHome[.small]).canvasSize == home)
        #expect(try #require(onLock[.small]).canvasSize == lock)
    }

    /// Placement is resolved before screen proximity, so an exact Lock Screen row cannot replace a nearby Home Screen row in an unnamed lookup.
    @Test func defaultPlacementIsMatchedBeforeNearestScreen() throws {
        let screenSize = CGSize(width: 1032, height: 1376)
        let frames = WidgetSize.frames(
            platform: .pad,
            screenSize: screenSize,
            majorOSVersion: 26
        )
        let homeScreenFrames = WidgetSize.frames(
            platform: .pad,
            screenSize: screenSize,
            majorOSVersion: 26,
            placement: .homeScreen
        )
        let lockScreenFrames = WidgetSize.frames(
            platform: .pad,
            screenSize: screenSize,
            majorOSVersion: 26,
            placement: .lockScreen
        )

        #expect(try #require(frames[.small]) == #require(homeScreenFrames[.small]))
        #expect(try #require(frames[.small]) != #require(lockScreenFrames[.small]))
    }

    /// On every iPad, extraLargePortrait is exactly as wide as medium and large, the same rule that holds on iPhone. It holds within each target, since the canvas and the rendered frame are different sizes.
    @Test func extraLargePortraitSharesTheMediumWidth() throws {
        for stored in WidgetFrameRecord.all
        where stored.platform == .pad && stored.widgetSize == .extraLargePortrait {
            let frames = WidgetSize.frames(
                platform: .pad,
                screenSize: stored.screenSize,
                majorOSVersion: 27
            )
            /// The rule holds within each target, since the canvas and the rendered frame are different sizes.
            let isRendered = stored.target == .homeScreen
            let medium = try #require(frames[.medium])
            let large = try #require(frames[.large])
            let mediumWidth = isRendered ? medium.renderedSize.width : medium.canvasSize.width
            let largeHeight = isRendered ? large.renderedSize.height : large.canvasSize.height
            #expect(stored.frame.width == mediumWidth, "\(stored.screenSize) \(stored.target)")
            #expect(stored.frame.height > largeHeight, "\(stored.screenSize) \(stored.target)")
        }
    }

    /// The rendered `extraLargePortrait` frame is the canvas scaled by the same factor every other size on that iPad uses. Confirmed on the 820x1180 iPad by measuring a placed widget at 600x928 pixels.
    @Test func extraLargePortraitScalesLikeEveryOtherSize() throws {
        for stored in WidgetFrameRecord.all
        where stored.platform == .pad && stored.widgetSize == .extraLargePortrait && stored.target == .homeScreen {
            let scale = try #require(WidgetSize.extraLargePortrait.frame(platform: .pad, screenSize: stored.screenSize, majorOSVersion: 27)).scaleFactor
            let smallScale = try #require(WidgetSize.small.frame(platform: .pad, screenSize: stored.screenSize, majorOSVersion: 27)).scaleFactor
            #expect(abs(scale - smallScale) < 0.001, "\(stored.screenSize)")
            /// Every rendered frame lands on a whole pixel at 2x.
            for value in [stored.frame.width, stored.frame.height] {
                #expect((value * 2).truncatingRemainder(dividingBy: 1) == 0, "\(stored.screenSize) \(value)")
            }
        }
    }

    /// The Display Zoom screen sizes, which previously had no Lock Screen or extraLargePortrait frame and fell back to the nearest unzoomed iPad.
    @Test(arguments: [
        (CGSize(width: 1192, height: 1590), CGSize(width: 412, height: 636), CGSize(width: 154.5, height: 154.5)),
        (CGSize(width: 970, height: 1389), CGSize(width: 350, height: 538), CGSize(width: 152.5, height: 152.5)),
        (CGSize(width: 954, height: 1373), CGSize(width: 350, height: 538), CGSize(width: 149, height: 149))
    ])
    func displayZoomFrames(screenSize: CGSize, portrait: CGSize, lockScreenSmall: CGSize) throws {
        let canvas = WidgetSize.frames(platform: .pad, screenSize: screenSize, majorOSVersion: 27)
        #expect(try #require(canvas[.extraLargePortrait]).canvasSize == portrait)
        let lock = WidgetSize.frames(platform: .pad, screenSize: screenSize, majorOSVersion: 27, placement: .lockScreen)
        #expect(try #require(lock[.small]).canvasSize == lockScreenSmall)
    }

    /// A Display Zoom row is not scaled, so its canvas and Home Screen frames are the same. Apple publishes them identically and measurement agrees.
    @Test(arguments: [CGSize(width: 1192, height: 1590), CGSize(width: 970, height: 1389), CGSize(width: 954, height: 1373)])
    func displayZoomRowsAreUnscaled(screenSize: CGSize) throws {
        let frames = WidgetSize.frames(platform: .pad, screenSize: screenSize, majorOSVersion: 27)
        for size in [WidgetSize.small, .medium, .large, .extraLarge, .extraLargePortrait] {
            let frame = try #require(frames[size])
            #expect(frame.canvasSize == frame.renderedSize, "\(screenSize) \(size)")
            #expect(frame.scaleFactor == 1, "\(screenSize) \(size)")
        }
    }

    /// The measured case, kept as its own assertion so the value that was confirmed on device is pinned separately from the ones derived from the grid.
    @Test func theMeasuredExtraLargePortraitRenderedFrame() throws {
        let frames = WidgetSize.frames(
            platform: .pad,
            screenSize: CGSize(width: 820, height: 1180),
            majorOSVersion: 27
        )
        #expect(try #require(frames[.extraLargePortrait]).renderedSize == CGSize(width: 300, height: 464))
    }

    /// extraLargePortrait arrived in iPadOS 27, so an earlier lookup has no frame for it.
    @Test func extraLargePortraitStartsAtiPadOS27() throws {
        let screen = CGSize(width: 820, height: 1180)
        let before = WidgetSize.frames(platform: .pad, screenSize: screen, majorOSVersion: 26)
        let after = WidgetSize.frames(platform: .pad, screenSize: screen, majorOSVersion: 27)
        #expect(before[.extraLargePortrait] == nil)
        #expect(try #require(after[.extraLargePortrait]).canvasSize == CGSize(width: 342, height: 529))
    }
}
