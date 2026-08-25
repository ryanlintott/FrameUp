//
//  WidgetFrameTests.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-08-25.
//

import CoreGraphics
import Testing
@testable import FrameUp

struct WidgetFrameTests {
    /// One expected lookup result.
    struct Expectation: Sendable, CustomStringConvertible {
        let screenSize: CGSize
        let majorOSVersion: Int
        let displayScale: CGFloat?
        let small: CGSize
        let medium: CGSize
        let large: CGSize

        init(_ width: CGFloat, _ height: CGFloat, os majorOSVersion: Int, displayScale: CGFloat? = nil, small: CGSize, medium: CGSize, large: CGSize) {
            self.screenSize = CGSize(width: width, height: height)
            self.majorOSVersion = majorOSVersion
            self.displayScale = displayScale
            self.small = small
            self.medium = medium
            self.large = large
        }

        var description: String {
            let scale = displayScale.map { " @\(Int($0))x" } ?? ""
            return "\(Int(screenSize.width))x\(Int(screenSize.height))\(scale) on iOS \(majorOSVersion)"
        }
    }

    static func size(_ width: CGFloat, _ height: CGFloat) -> CGSize {
        CGSize(width: width, height: height)
    }

    /// Values published by Apple, which spot checks on iOS 18.6 confirmed for 440x956, 402x874 and 390x844.
    static let published: [Expectation] = [
        .init(430, 932, os: 18, small: size(170, 170), medium: size(364, 170), large: size(364, 382)),
        .init(428, 926, os: 18, small: size(170, 170), medium: size(364, 170), large: size(364, 382)),
        .init(414, 896, os: 18, small: size(169, 169), medium: size(360, 169), large: size(360, 379)),
        .init(414, 736, os: 18, small: size(159, 159), medium: size(348, 157), large: size(348, 357)),
        .init(393, 852, os: 18, small: size(158, 158), medium: size(338, 158), large: size(338, 354)),
        .init(390, 844, os: 18, small: size(158, 158), medium: size(338, 158), large: size(338, 354)),
        .init(375, 812, os: 18, small: size(155, 155), medium: size(329, 155), large: size(329, 345)),
        .init(375, 667, os: 18, small: size(148, 148), medium: size(321, 148), large: size(321, 324)),
        .init(360, 780, os: 18, small: size(155, 155), medium: size(329, 155), large: size(329, 345)),
        .init(320, 568, os: 18, small: size(141, 141), medium: size(292, 141), large: size(292, 311))
    ]

    /// Values measured on iOS 26.5, expressed as pixels over the device scale factor so the repeating decimals stay exact.
    static let measured: [Expectation] = [
        .init(440, 956, os: 26, small: size(530/3, 530/3), medium: size(1134/3, 530/3), large: size(1134/3, 1182/3)),
        .init(430, 932, os: 26, small: size(524/3, 524/3), medium: size(1116/3, 524/3), large: size(1116/3, 1164/3)),
        .init(428, 926, os: 26, small: size(523/3, 523/3), medium: size(1115/3, 523/3), large: size(1115/3, 1161/3)),
        .init(420, 912, os: 26, small: size(518/3, 518/3), medium: size(1100/3, 518/3), large: size(1100/3, 1146/3)),
        .init(414, 896, os: 26, displayScale: 2, small: size(333/2, 333/2), medium: size(712/2, 333/2), large: size(712/2, 743/2)),
        .init(414, 896, os: 26, displayScale: 3, small: size(514/3, 514/3), medium: size(1088/3, 514/3), large: size(1088/3, 1134/3)),
        .init(402, 874, os: 26, small: size(493/3, 493/3), medium: size(1049/3, 493/3), large: size(1049/3, 1095/3)),
        .init(393, 852, os: 26, small: size(488/3, 488/3), medium: size(1034/3, 488/3), large: size(1034/3, 1080/3)),
        .init(390, 844, os: 26, small: size(486/3, 486/3), medium: size(1026/3, 486/3), large: size(1026/3, 1074/3)),
        .init(375, 812, os: 26, small: size(477/3, 477/3), medium: size(1001/3, 477/3), large: size(1001/3, 1047/3)),
        .init(375, 667, os: 26, small: size(292/2, 292/2), medium: size(638/2, 292/2), large: size(638/2, 636/2))
    ]

    @Test(arguments: published + measured)
    func systemFramesMatchTheTable(expectation: Expectation) throws {
        let frames = WidgetSize.sizesForiPhone(
            screenSize: expectation.screenSize,
            majorOSVersion: expectation.majorOSVersion,
            displayScale: expectation.displayScale
        )
        #expect(try #require(frames[.small]) == expectation.small)
        #expect(try #require(frames[.medium]) == expectation.medium)
        #expect(try #require(frames[.large]) == expectation.large)
    }

    /// The bug this table was built to fix. Every 402 point wide iPhone resolved through the 393 arm and reported an iOS 18 frame.
    @Test func modernFramesDifferFromPublishedOnes() {
        let modern = WidgetSize.sizesForiPhone(screenSize: CGSize(width: 402, height: 874), majorOSVersion: 26)
        let legacy = WidgetSize.sizesForiPhone(screenSize: CGSize(width: 402, height: 874), majorOSVersion: 18)
        #expect(legacy[.small] == CGSize(width: 158, height: 158))
        #expect(modern[.small] != legacy[.small])
    }

    /// Screen width alone is ambiguous. 375 points is both an iPhone SE and an iPhone 11 Pro, and their frames differ.
    @Test func screenHeightBreaksWidthTies() throws {
        let tall = WidgetSize.sizesForiPhone(screenSize: CGSize(width: 375, height: 812), majorOSVersion: 26)
        let short = WidgetSize.sizesForiPhone(screenSize: CGSize(width: 375, height: 667), majorOSVersion: 26)
        #expect(try #require(tall[.small]).width == 159)
        #expect(try #require(short[.small]).width == 146)
    }

    /// An unknown screen size resolves to the nearest known width rather than the next smaller one.
    @Test(arguments: [
        (CGFloat(405), CGFloat(402)),
        (CGFloat(399), CGFloat(402)),
        (CGFloat(435), CGFloat(430)),
        (CGFloat(445), CGFloat(440))
    ])
    func unknownWidthsResolveToTheNearestKnownWidth(width: CGFloat, expectedMatch: CGFloat) throws {
        let unknown = WidgetSize.sizesForiPhone(screenSize: CGSize(width: width, height: 900), majorOSVersion: 26)
        let known = WidgetSize.sizesForiPhone(screenSize: CGSize(width: expectedMatch, height: 900), majorOSVersion: 26)
        #expect(try #require(unknown[.small]) == #require(known[.small]))
    }

    /// A newer frame only has to list what changed. A widget size with no frame for the newer OS keeps the one from the older OS.
    @Test func newerFramesLayerOverOlderOnes() throws {
        let screen = CGSize(width: 402, height: 874)
        let onTwentySix = WidgetSize.sizesForiPhone(screenSize: screen, majorOSVersion: 26, displayScale: 3)
        let onTwentySeven = WidgetSize.sizesForiPhone(screenSize: screen, majorOSVersion: 27, displayScale: 3)
        /// No iOS 27 system frames were measured, so they carry over from iOS 26.
        #expect(try #require(onTwentySeven[.small]) == #require(onTwentySix[.small]))
        #expect(try #require(onTwentySeven[.accessoryCircular]) == #require(onTwentySix[.accessoryCircular]))
        /// extraLargePortrait exists only from iOS 27.
        #expect(onTwentySix[.extraLargePortrait] == nil)
        #expect(onTwentySeven[.extraLargePortrait] != nil)
    }

    /// An OS older than every set still returns frames rather than nothing.
    @Test func versionsBelowEverySetFallBackToTheOldestOne() {
        let frames = WidgetSize.sizesForiPhone(screenSize: CGSize(width: 390, height: 844), majorOSVersion: 15)
        #expect(frames[.small] == CGSize(width: 158, height: 158))
    }

    @Test func everyStoredFrameResolvesToItself() throws {
        for stored in WidgetFrame.all where stored.platform == .phone {
            let frames = WidgetSize.sizesForiPhone(
                screenSize: stored.screenSize,
                majorOSVersion: stored.minMajorOSVersion,
                displayScale: stored.displayScale,
                placement: stored.placement
            )
            #expect(
                try #require(frames[stored.widgetSize]) == stored.frame,
                "\(stored.screenSize) \(stored.widgetSize) \(stored.placement)"
            )
        }
    }

    /// Widget frames always land on a whole number of pixels. Multiplying by six covers both 2x and 3x devices and catches a mistyped decimal.
    @Test func everyStoredFrameLandsOnAWholePixel() {
        for stored in WidgetFrame.all {
            for value in [stored.frame.width, stored.frame.height] {
                let pixels = value * 6
                #expect(
                    abs(pixels - pixels.rounded()) < 0.0001,
                    "\(stored.screenSize) \(stored.widgetSize) has \(value) points, which is not a whole pixel"
                )
            }
        }
    }

    @Test func noTwoFramesShareTheSameKey() {
        var seen = Set<String>()
        for stored in WidgetFrame.all {
            let key = [
                "\(stored.platform)",
                "\(stored.widgetSize)",
                "\(stored.screenSize)",
                String(describing: stored.displayScale),
                "\(stored.placement)",
                String(describing: stored.target),
                "\(stored.minMajorOSVersion)"
            ].joined(separator: "-")
            #expect(seen.contains(key) == false, "duplicate frame for \(key)")
            seen.insert(key)
        }
    }

    /// Every stored frame must be reachable. A frame with a display scale or target no real device reports would silently never match.
    @Test func everyStoredFrameIsReachable() {
        for stored in WidgetFrame.all {
            let frames = WidgetFrame.frames(
                platform: stored.platform,
                screenSize: stored.screenSize,
                majorOSVersion: stored.minMajorOSVersion,
                displayScale: stored.displayScale,
                placement: stored.placement,
                target: stored.target
            )
            #expect(
                frames[stored.widgetSize] != nil,
                "\(stored.platform) \(stored.screenSize) \(stored.widgetSize) \(stored.placement) is unreachable"
            )
        }
    }

    /// Accessory widgets appear on the Lock Screen, so their frames are stored against that placement, but a lookup that does not name a placement still reports them.
    @Test func accessoryFramesComeFromTheLockScreenByDefault() throws {
        let screen = CGSize(width: 390, height: 844)
        let merged = WidgetSize.sizesForiPhone(screenSize: screen, majorOSVersion: 26)
        let lock = WidgetSize.sizesForiPhone(screenSize: screen, majorOSVersion: 26, placement: .lockScreen)
        #expect(try #require(merged[.accessoryCircular]) == #require(lock[.accessoryCircular]))
        #expect(try #require(merged[.accessoryInline]) == #require(lock[.accessoryInline]))
    }

    /// The Home Screen wins for a size that appears in more than one place.
    @Test func homeScreenWinsForSizesThatAppearInBothPlaces() throws {
        let screen = CGSize(width: 390, height: 844)
        let merged = WidgetSize.sizesForiPhone(screenSize: screen, majorOSVersion: 26)
        let home = WidgetSize.sizesForiPhone(screenSize: screen, majorOSVersion: 26, placement: .homeScreen)
        #expect(try #require(merged[.small]) == #require(home[.small]))
    }

    /// Naming a placement returns only what appears there.
    @Test func namingAPlacementExcludesOtherPlacements() {
        let screen = CGSize(width: 390, height: 844)
        let home = WidgetSize.sizesForiPhone(screenSize: screen, majorOSVersion: 26, placement: .homeScreen)
        let lock = WidgetSize.sizesForiPhone(screenSize: screen, majorOSVersion: 26, placement: .lockScreen)
        #expect(home[.accessoryCircular] == nil)
        #expect(lock[.small] == nil)
    }

    /// Accessory widgets arrived in iOS 16, so an iOS 15 lookup has no accessory frames.
    @Test func accessoryFramesStartAtiOS16() {
        let frames = WidgetSize.sizesForiPhone(screenSize: CGSize(width: 390, height: 844), majorOSVersion: 15)
        #expect(frames[.accessoryCircular] == nil)
        #expect(frames[.small] == CGSize(width: 158, height: 158))
    }

    /// The iPhone accessory frames changed in iOS 26, so a lookup on that OS must not return the published values.
    @Test(arguments: [
        (CGFloat(402), CGFloat(874), CGFloat(3), CGSize(width: 174.0/3, height: 174.0/3)),
        (CGFloat(440), CGFloat(956), CGFloat(3), CGSize(width: 60, height: 60)),
        (CGFloat(375), CGFloat(667), CGFloat(2), CGSize(width: 56, height: 56)),
        (CGFloat(414), CGFloat(896), CGFloat(2), CGSize(width: 60, height: 60)),
        (CGFloat(414), CGFloat(896), CGFloat(3), CGSize(width: 191.0/3, height: 191.0/3))
    ])
    func accessoryCircularOniOS26(width: CGFloat, height: CGFloat, displayScale: CGFloat, expected: CGSize) throws {
        let screen = CGSize(width: width, height: height)
        let modern = WidgetSize.sizesForiPhone(screenSize: screen, majorOSVersion: 26, displayScale: displayScale)
        let published = WidgetSize.sizesForiPhone(screenSize: screen, majorOSVersion: 18, displayScale: displayScale)
        #expect(try #require(modern[.accessoryCircular]) == expected)
        #expect(try #require(modern[.accessoryCircular]) != #require(published[.accessoryCircular]))
    }

    /// Every iPhone reports a 36 point tall inline accessory widget on iOS 26, where Apple publishes 26.
    @Test func inlineAccessoryHeightIsThirtySixOniOS26() throws {
        for stored in WidgetFrame.all
        where stored.platform == .phone
            && stored.widgetSize == .accessoryInline
            && stored.minMajorOSVersion >= 26 {
            #expect(stored.frame.height == 36, "\(stored.screenSize)")
        }
    }

    /// extraLargePortrait arrived in iOS 27, so an iOS 26 lookup has no frame for it.
    @Test func extraLargePortraitStartsAtiOS27() throws {
        let screen = CGSize(width: 402, height: 874)
        let onTwentySix = WidgetSize.sizesForiPhone(screenSize: screen, majorOSVersion: 26, displayScale: 3)
        let onTwentySeven = WidgetSize.sizesForiPhone(screenSize: screen, majorOSVersion: 27, displayScale: 3)
        #expect(onTwentySix[.extraLargePortrait] == nil)
        #expect(try #require(onTwentySeven[.extraLargePortrait]) == CGSize(width: 1049.0/3, height: 1697.0/3))
    }
}
