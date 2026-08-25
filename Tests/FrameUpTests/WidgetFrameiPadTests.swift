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
        for (target, expected) in [(WidgetTarget.designCanvas, row.canvas), (.homeScreen, row.homeScreen)] {
            let frames = WidgetSize.sizesForiPad(screenSize: row.screenSize, target: target, majorOSVersion: 18)
            for (index, widgetSize) in Self.systemSizes.enumerated() {
                #expect(try #require(frames[widgetSize]) == expected[index], "\(row) \(target) \(widgetSize)")
            }
        }
    }

    /// The design canvas is larger than the Home Screen frame wherever the two differ, never smaller.
    @Test(arguments: published)
    func theDesignCanvasIsNeverSmallerThanTheHomeScreenFrame(row: Row) throws {
        let canvas = WidgetSize.sizesForiPad(screenSize: row.screenSize, target: .designCanvas, majorOSVersion: 18)
        let home = WidgetSize.sizesForiPad(screenSize: row.screenSize, target: .homeScreen, majorOSVersion: 18)
        for widgetSize in Self.systemSizes {
            let canvasSize = try #require(canvas[widgetSize])
            let homeSize = try #require(home[widgetSize])
            #expect(canvasSize.width >= homeSize.width)
            #expect(canvasSize.height >= homeSize.height)
        }
    }

    /// A 820x1180 iPad reports a 155 point small widget on the Home Screen and 152 on the Lock Screen, both measured.
    @Test func theLockScreenSmallFrameDiffersFromTheHomeScreenOne() throws {
        let screen = CGSize(width: 820, height: 1180)
        let home = WidgetSize.sizesForiPad(screenSize: screen, target: .designCanvas, majorOSVersion: 26, placement: .homeScreen)
        let lock = WidgetSize.sizesForiPad(screenSize: screen, target: .designCanvas, majorOSVersion: 26, placement: .lockScreen)
        #expect(try #require(home[.small]) == CGSize(width: 155, height: 155))
        #expect(try #require(lock[.small]) == CGSize(width: 152, height: 152))
    }

    /// Apple publishes no accessory frames for iPad. These were measured.
    @Test(arguments: [
        (WidgetSize.accessoryCircular, CGSize(width: 63, height: 63)),
        (WidgetSize.accessoryRectangular, CGSize(width: 152, height: 63)),
        (WidgetSize.accessoryInline, CGSize(width: 372, height: 36))
    ])
    func accessoryFramesAreAvailable(widgetSize: WidgetSize, expected: CGSize) throws {
        let frames = WidgetSize.sizesForiPad(
            screenSize: CGSize(width: 820, height: 1180),
            target: .designCanvas,
            majorOSVersion: 26
        )
        #expect(try #require(frames[widgetSize]) == expected)
    }

    /// iPad Lock Screen widgets are not known before iPadOS 18, so an older lookup reports none.
    @Test func accessoryFramesAreAbsentBeforeiPadOS18() {
        let frames = WidgetSize.sizesForiPad(
            screenSize: CGSize(width: 820, height: 1180),
            target: .designCanvas,
            majorOSVersion: 17
        )
        #expect(frames[.accessoryCircular] == nil)
        #expect(frames[.small] == CGSize(width: 155, height: 155))
    }

    /// iPad frames did not change in iOS 26, so a lookup returns the same values on either side of that boundary.
    @Test(arguments: published)
    func iPadFramesAreTheSameBeforeAndAfteriOS26(row: Row) throws {
        for target in [WidgetTarget.designCanvas, .homeScreen] {
            let before = WidgetSize.sizesForiPad(screenSize: row.screenSize, target: target, majorOSVersion: 18, placement: .homeScreen)
            let after = WidgetSize.sizesForiPad(screenSize: row.screenSize, target: target, majorOSVersion: 26, placement: .homeScreen)
            for widgetSize in Self.systemSizes {
                #expect(try #require(before[widgetSize]) == #require(after[widgetSize]))
            }
        }
    }

    @Test func everyPublishedFrameLandsOnAWholePixelAtTwoX() {
        for stored in WidgetFrame.all where stored.platform == .pad {
            for value in [stored.frame.width, stored.frame.height] {
                let pixels = value * 2
                #expect(
                    abs(pixels - pixels.rounded()) < 0.0001,
                    "\(stored.screenSize) \(stored.widgetSize) has \(value) points, which is not a whole pixel at 2x"
                )
            }
        }
    }

    /// Resolving per widget size means a frame measured on one iPad still resolves on the others, rather than disappearing because that screen size has no accessory row.
    @Test(arguments: [CGFloat(1024), 834, 768])
    func accessoryFramesResolveOnUnmeasurediPads(width: CGFloat) throws {
        let frames = WidgetSize.sizesForiPad(
            screenSize: CGSize(width: width, height: 1180),
            target: .designCanvas,
            majorOSVersion: 26
        )
        #expect(try #require(frames[.accessoryCircular]) == CGSize(width: 63, height: 63))
        /// The system sizes still come from that iPad's own row rather than the measured one.
        #expect(frames[.small] != CGSize(width: 152, height: 152))
    }
}
