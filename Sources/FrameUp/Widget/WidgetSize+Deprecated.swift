//
//  WidgetSize+Deprecated.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-09-09.
//

import SwiftUI

/// The per-platform lookups these replace encoded the platform in the method name, so there was no way to ask for a frame given a platform. ``WidgetSize/frame(platform:screenSize:majorOSVersion:displayScale:placement:)`` takes it as a parameter instead, and returns a ``WidgetFrame`` carrying both of an iPad's sizes rather than making the caller choose a target and look up the scale factor separately.
///
/// Only the lookups that shipped in 0.9.11 are here. The per-platform lookups added since, for macOS, visionOS and an Apple Watch screen size, were never released, so they are replaced outright rather than shipping deprecated.
///
/// These call the frame tables directly rather than the replacement, so they keep returning exactly what they always did. The replacement differs in one respect: where a widget size has no Home Screen frame because it is never scaled, such as an iPad Lock Screen widget, ``WidgetFrame/renderedSize`` reports the canvas size rather than nothing.
public extension WidgetSize {
    @available(*, deprecated, message: "Use `frame(platform:screenSize:majorOSVersion:displayScale:placement:)` instead.")
    typealias Size = (CGFloat, CGFloat)

    @available(*, deprecated, message: "Use `WidgetSize.frames(platform: .phone, screenSize:majorOSVersion:displayScale:placement:)` and read `canvasSize` on each frame.")
    static func sizesForiPhone(
        screenSize: CGSize,
        majorOSVersion: Int? = nil,
        displayScale: CGFloat? = nil,
        placement: WidgetPlacement? = nil
    ) -> [WidgetSize: CGSize] {
        WidgetFrameRecord.frames(
            platform: .phone,
            screenSize: screenSize,
            majorOSVersion: majorOSVersion ?? WidgetFrameRecord.currentMajorOSVersion,
            displayScale: displayScale,
            placement: placement
        )
    }

    @available(*, deprecated, message: "Use `WidgetSize.frames(platform: .pad, screenSize:majorOSVersion:placement:)` and read `canvasSize` or `renderedSize` on each frame.")
    static func sizesForiPad(
        screenSize: CGSize,
        target: WidgetTarget,
        majorOSVersion: Int? = nil,
        placement: WidgetPlacement? = nil
    ) -> [WidgetSize: CGSize] {
        WidgetFrameRecord.frames(
            platform: .pad,
            screenSize: screenSize,
            majorOSVersion: majorOSVersion ?? WidgetFrameRecord.currentMajorOSVersion,
            placement: placement,
            target: target
        )
    }

    /// A case size cannot identify a watch: the Ultra 2 and Ultra 3 are both 49mm and report different frames. Look up by screen size instead.
    @available(*, deprecated, message: "A case size cannot distinguish an Ultra 2 from an Ultra 3. Use `WidgetSize.frames(platform: .watch, screenSize:)` instead.")
    static func sizesForWatch(watchSize: CGFloat) -> [WidgetSize: CGSize] {
        guard let frame = WidgetFrameRecord.watchRectangular(caseSize: watchSize) else { return [:] }
        return [.accessoryRectangular: frame]
    }

    @available(*, deprecated, message: "Use `frame(platform: .phone, screenSize:majorOSVersion:displayScale:placement:)?.canvasSize` instead.")
    func sizeForiPhone(
        screenSize: CGSize,
        majorOSVersion: Int? = nil,
        displayScale: CGFloat? = nil,
        placement: WidgetPlacement? = nil
    ) -> CGSize? {
        Self.sizesForiPhone(
            screenSize: screenSize,
            majorOSVersion: majorOSVersion,
            displayScale: displayScale,
            placement: placement
        )[self]
    }

    @available(*, deprecated, message: "Use `frame(platform: .pad, screenSize:majorOSVersion:placement:)` and read `canvasSize` or `renderedSize`.")
    func sizeForiPad(
        screenSize: CGSize,
        target: WidgetTarget,
        majorOSVersion: Int? = nil,
        placement: WidgetPlacement? = nil
    ) -> CGSize? {
        Self.sizesForiPad(
            screenSize: screenSize,
            target: target,
            majorOSVersion: majorOSVersion,
            placement: placement
        )[self]
    }

    /// A case size cannot identify a watch: the Ultra 2 and Ultra 3 are both 49mm and report different frames. Look up by screen size instead.
    @available(*, deprecated, message: "A case size cannot distinguish an Ultra 2 from an Ultra 3. Use `frame(platform: .watch, screenSize:)?.canvasSize` instead.")
    func sizeForWatch(watchSize: CGFloat) -> CGSize? {
        Self.sizesForWatch(watchSize: watchSize)[self]
    }

    @available(*, deprecated, message: "Use `frame(platform: .pad, screenSize:majorOSVersion:)?.scaleFactor` instead.")
    func scaleFactorForiPad(screenSize: CGSize, majorOSVersion: Int? = nil) -> CGFloat? {
        guard let homeScreen = sizeForiPad(screenSize: screenSize, target: .homeScreen, majorOSVersion: majorOSVersion),
              let designCanvas = sizeForiPad(screenSize: screenSize, target: .designCanvas, majorOSVersion: majorOSVersion)
        else { return nil }
        return homeScreen.width / designCanvas.width
    }
}

#if os(iOS)
public extension WidgetSize {
    @available(*, deprecated, message: "Use `frameForCurrentDevice()` and read `canvasSize` or `renderedSize`.")
    @preconcurrency @MainActor
    func sizeForCurrentDevice(iPadTarget: WidgetTarget) -> CGSize? {
        switch Platform.current {
        case .phone:
            sizeForiPhone(screenSize: Self.currentScreenSize, displayScale: Self.currentDisplayScale)
        case .pad:
            sizeForiPad(screenSize: Self.currentScreenSize, target: iPadTarget)
        case .macCatalyst:
            /// Widgets in a Mac Catalyst app are hosted by macOS, so they take the macOS frames.
            WidgetFrameRecord.frames(platform: .mac, screenSize: .zero, majorOSVersion: WidgetFrameRecord.currentMajorOSVersion)[self]
        default:
            nil
        }
    }

    @available(*, deprecated, message: "Use `frameForCurrentDevice()?.scaleFactor` instead.")
    @preconcurrency @MainActor
    var scaleFactorForCurrentDevice: CGFloat? {
        switch Platform.current {
        case .pad:
            scaleFactorForiPad(screenSize: Self.currentScreenSize)
        case .phone:
            1
        case .macCatalyst:
            /// Widgets in a Mac Catalyst app are hosted by macOS, so they take the macOS frames.
            WidgetFrameRecord.frames(platform: .mac, screenSize: .zero, majorOSVersion: WidgetFrameRecord.currentMajorOSVersion)[self] == nil ? nil : 1
        default:
            nil
        }
    }
}
#endif
