//
//  WidgetFramePairingTests.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-09-09.
//

import CoreGraphics
import Testing
@testable import FrameUp

/// A ``WidgetFrame`` carries both of an iPad's sizes, so these check the pairing: which lookups produce two different sizes and which produce one.
struct WidgetFramePairingTests {
    /// The iPad Home Screen is the only place that scales a widget, so every other platform reports one size twice.
    @Test(arguments: [
        (WidgetSize.Platform.phone, CGSize(width: 402, height: 874)),
        (.mac, .zero),
        (.vision, .zero),
        (.watch, CGSize(width: 184, height: 224))
    ])
    func onlyTheiPadHasTwoSizes(platform: WidgetSize.Platform, screenSize: CGSize) {
        let frames = WidgetSize.frames(platform: platform, screenSize: screenSize, majorOSVersion: 27)
        #expect(frames.isEmpty == false)
        for (widgetSize, frame) in frames {
            #expect(frame.canvasSize == frame.renderedSize, "\(platform) \(widgetSize)")
            #expect(frame.scaleFactor == 1, "\(platform) \(widgetSize)")
        }
    }

    /// An iPad Lock Screen widget is drawn at its design canvas size rather than scaled into the Home Screen grid, so it reports one size too. Before this it had no rendered size at all, which read as a gap in the tables rather than as the widget not being scaled.
    @Test(arguments: [
        CGSize(width: 1024, height: 1366),
        CGSize(width: 834, height: 1112),
        CGSize(width: 820, height: 1180),
        CGSize(width: 744, height: 1133)
    ])
    func theiPadLockScreenIsNotScaled(screenSize: CGSize) {
        let frames = WidgetSize.frames(platform: .pad, screenSize: screenSize, majorOSVersion: 27, placement: .lockScreen)
        #expect(frames.isEmpty == false)
        for (widgetSize, frame) in frames {
            #expect(frame.canvasSize == frame.renderedSize, "\(screenSize) \(widgetSize)")
            #expect(frame.scaleFactor == 1, "\(screenSize) \(widgetSize)")
        }
    }

    /// An iPad scales every widget on its Home Screen by one factor, so a frame's scale factor does not depend on which size it is.
    @Test(arguments: [
        CGSize(width: 1024, height: 1366),
        CGSize(width: 834, height: 1194),
        CGSize(width: 820, height: 1180),
        CGSize(width: 810, height: 1080),
        CGSize(width: 768, height: 1024)
    ])
    func oneiPadScalesEverySizeAlike(screenSize: CGSize) throws {
        let frames = WidgetSize.frames(platform: .pad, screenSize: screenSize, majorOSVersion: 27)
        let small = try #require(frames[.small]).scaleFactor
        #expect(small < 1, "\(screenSize) is not a Display Zoom row, so it scales")
        /// Only the sizes laid into the Home Screen grid are scaled. The accessory sizes come from the Lock Screen, which draws a widget at its canvas size, so their scale factor is 1.
        for widgetSize in [WidgetSize.medium, .large, .extraLarge, .extraLargePortrait] {
            let frame = try #require(frames[widgetSize], "\(screenSize) \(widgetSize)")
            /// The published Home Screen values are a grid rather than an exact multiple of the canvas, so they agree to within a rounding error rather than exactly.
            #expect(abs(frame.scaleFactor - small) < 0.001, "\(screenSize) \(widgetSize)")
        }
    }

    /// The iPad Pro 13-inch M4 has a measured `extraLargePortrait` canvas of its own but no published Home Screen row, so its rendered size resolves to the nearest screen size the way its system sizes do.
    @Test func theThirteenInchProResolvesItsRenderedFrameByNearestScreen() throws {
        let frame = try #require(
            WidgetSize.extraLargePortrait.frame(
                platform: .pad,
                screenSize: CGSize(width: 1032, height: 1376),
                majorOSVersion: 27
            )
        )
        /// Measured on an iPad Pro 13-inch M4 at 757x1173 pixels.
        #expect(frame.canvasSize == CGSize(width: 378.5, height: 586.5))
        /// Taken from the 1024x1366 iPad, which measured an identical canvas.
        #expect(frame.renderedSize == CGSize(width: 356, height: 552))
    }

    /// A lookup that names no placement reports the Home Screen frames for the system sizes, so those keep both of their sizes rather than collapsing to one.
    @Test func theDefaultPlacementKeepsTheiPadScaling() throws {
        let frame = try #require(
            WidgetSize.small.frame(platform: .pad, screenSize: CGSize(width: 820, height: 1180), majorOSVersion: 27)
        )
        #expect(frame.canvasSize == CGSize(width: 155, height: 155))
        #expect(frame.renderedSize == CGSize(width: 136, height: 136))
        #expect(frame.canvasSize != frame.renderedSize)
    }

    /// Widgets in a Mac Catalyst app are hosted by macOS, so the platform folds to `.mac` inside the lookup rather than reporting nothing.
    @Test func macCatalystResolvesToTheMacFrames() {
        let mac = WidgetSize.frames(platform: .mac, majorOSVersion: 26)
        let catalyst = WidgetSize.frames(platform: .macCatalyst, majorOSVersion: 26)
        #expect(catalyst.isEmpty == false)
        #expect(mac == catalyst)
    }

    /// A platform with no frames reports none rather than falling back to another platform's.
    @Test func unsupportedPlatformsHaveNoFrames() {
        #expect(WidgetSize.frames(platform: .carPlay, majorOSVersion: 27).isEmpty)
        #expect(WidgetSize.frames(platform: .unsupported, majorOSVersion: 27).isEmpty)
    }

    /// The singular lookup is the plural one subscripted, so the two never disagree.
    @Test(arguments: WidgetSize.allCases)
    func theSingularLookupMatchesThePluralOne(widgetSize: WidgetSize) {
        let screenSize = CGSize(width: 820, height: 1180)
        let frames = WidgetSize.frames(platform: .pad, screenSize: screenSize, majorOSVersion: 27)
        #expect(widgetSize.frame(platform: .pad, screenSize: screenSize, majorOSVersion: 27) == frames[widgetSize])
    }
}

/// `WidgetDemoFrame.init?(_:cornerRadius:content:)` builds a frame only for a widget the current device can show, so these check the two tables that decision rests on: what a platform supports, and what has a frame.
struct WidgetSizeSupportTests {
    static let platforms: [WidgetSize.Platform] = [.phone, .pad, .mac, .macCatalyst, .watch, .vision, .carPlay, .unsupported]

    /// Every screen size stored for a platform, so the sweep below asks about real devices rather than one representative.
    static func screenSizes(for platform: WidgetSize.Platform) -> [CGSize] {
        /// `CGSize` is only `Hashable` from macOS 15, so these are deduplicated by description.
        var seen: Set<String> = []
        let stored = WidgetFrameRecord.all
            .filter { $0.platform == (platform == .macCatalyst ? .mac : platform) }
            .map(\.screenSize)
            .filter { seen.insert("\($0)").inserted }
        return stored.isEmpty ? [.zero] : stored
    }

    /// A widget size with a frame must be one the platform can actually show. Where these disagree, a demo frame would present a widget the device never displays, or a supported size would silently have no frame.
    @Test(arguments: platforms, 15...28)
    func everyFrameBelongsToASupportedSize(platform: WidgetSize.Platform, majorOSVersion: Int) {
        let supported = Set(WidgetSize.supportedSizes(platform: platform, majorOSVersion: majorOSVersion))
        for screenSize in Self.screenSizes(for: platform) {
            let framed = WidgetSize.frames(platform: platform, screenSize: screenSize, majorOSVersion: majorOSVersion)
            for widgetSize in framed.keys {
                #expect(
                    supported.contains(widgetSize),
                    "\(platform) \(majorOSVersion) \(screenSize) has a frame for \(widgetSize), which it does not support"
                )
            }
        }
    }

    /// The sizes iPhone and iPad never show, checked from the other direction so a table that grew a stray row is caught.
    @Test func sizesAPlatformNeverShows() {
        #expect(WidgetSize.supportedSizes(platform: .phone, majorOSVersion: 27).contains(.extraLarge) == false)
        #expect(WidgetSize.supportedSizes(platform: .mac, majorOSVersion: 27).contains(.accessoryCircular) == false)
        #expect(WidgetSize.supportedSizes(platform: .vision, majorOSVersion: 27).contains(.accessoryInline) == false)
        #expect(WidgetSize.supportedSizes(platform: .watch, majorOSVersion: 27).contains(.small) == false)
    }

    /// A version below the one a size arrives in does not report it.
    @Test func sizesArriveWithTheirOSVersion() {
        #expect(WidgetSize.supportedSizes(platform: .phone, majorOSVersion: 26).contains(.extraLargePortrait) == false)
        #expect(WidgetSize.supportedSizes(platform: .phone, majorOSVersion: 27).contains(.extraLargePortrait))
        #expect(WidgetSize.supportedSizes(platform: .phone, majorOSVersion: 15).contains(.accessoryCircular) == false)
        #expect(WidgetSize.supportedSizes(platform: .phone, majorOSVersion: 16).contains(.accessoryCircular))
        #expect(WidgetSize.supportedSizes(platform: .vision, majorOSVersion: 25).isEmpty)
        #expect(WidgetSize.supportedSizes(platform: .vision, majorOSVersion: 26).isEmpty == false)
    }

    /// Widgets in a Mac Catalyst app are hosted by macOS, so a Catalyst process supports the macOS sizes. A Catalyst process reports the macOS version it runs on, which is what the lookup compares.
    @Test(arguments: 14...28)
    func macCatalystSupportsTheSameSizesAsMac(majorOSVersion: Int) {
        #expect(
            WidgetSize.supportedSizes(platform: .mac, majorOSVersion: majorOSVersion)
            == WidgetSize.supportedSizes(platform: .macCatalyst, majorOSVersion: majorOSVersion)
        )
    }
}
