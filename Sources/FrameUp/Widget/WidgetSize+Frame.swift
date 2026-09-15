//
//  WidgetSize+Frame.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-09-09.
//

import SwiftUI

public extension WidgetSize {
    /// The frame this widget size takes on a specified device.
    ///
    /// One lookup for every platform. Parameters that a platform does not vary by can be left out: macOS and visionOS take only a platform, since their frames do not depend on a screen size.
    ///
    /// Frames for iOS 18 and earlier and the iPad system frames are sourced from [Apple Human Interface Guidelines: widget specifications](https://developer.apple.com/design/human-interface-guidelines/widgets#Specifications). Apple has not updated that table since iOS 18, and iOS 26 changed the frame of every iPhone widget, so iPhone frames from iOS 26, every macOS, visionOS and current Apple Watch frame, the iPad Lock Screen and `extraLargePortrait` everywhere are measured instead. See `Measurements/` in the repository.
    ///
    /// A screen size with no exact entry resolves to the nearest known one by width, then by height, so a device released after this table was last updated still returns a usable frame.
    /// - Parameters:
    ///   - platform: Platform the widget appears on. `.macCatalyst` resolves to the same frames as `.mac`, since widgets in a Mac Catalyst app are hosted by macOS.
    ///   - screenSize: Screen size in points, ignoring orientation. Not needed on macOS or visionOS, where a widget is not placed on a screen grid.
    ///   - majorOSVersion: Major OS version to look up frames for. Nil uses the version currently running.
    ///   - displayScale: Pixels per point on the display, matching SwiftUI's `displayScale` environment value. Only needed for a 414x896 screen, which is 2x on an iPhone 11 and 3x on an iPhone 11 Pro Max and from iOS 26 gives different frames for each. Nil still returns a stable answer, preferring the 2x frames for that screen size.
    ///   - placement: Where the widget appears. Nil reports Home Screen frames for the system sizes and Lock Screen frames for the accessory sizes, which is where each of them actually appears.
    /// - Returns: The frame for this widget size. Nil if no frame is known, either because the platform does not support this widget size or because it has not been measured yet. ``minimumSize`` and ``maximumSize`` are a useful fallback in that case.
    func frame(
        platform: Platform,
        screenSize: CGSize = .zero,
        majorOSVersion: Int? = nil,
        displayScale: CGFloat? = nil,
        placement: WidgetPlacement? = nil
    ) -> WidgetFrame? {
        Self.frames(
            platform: platform,
            screenSize: screenSize,
            majorOSVersion: majorOSVersion,
            displayScale: displayScale,
            placement: placement
        )[self]
    }

    /// The frames every widget size takes on a specified device.
    ///
    /// The plural form of ``frame(platform:screenSize:majorOSVersion:displayScale:placement:)``, which resolves every widget size together rather than once per size. See that method for what each parameter does.
    /// - Returns: Frames by widget size. Sizes with no known frame are omitted.
    static func frames(
        platform: Platform,
        screenSize: CGSize = .zero,
        majorOSVersion: Int? = nil,
        displayScale: CGFloat? = nil,
        placement: WidgetPlacement? = nil
    ) -> [WidgetSize: WidgetFrame] {
        let majorOSVersion = majorOSVersion ?? WidgetFrameRecord.currentMajorOSVersion

        func lookup(_ target: WidgetTarget) -> [WidgetSize: CGSize] {
            WidgetFrameRecord.frames(
                platform: platform,
                screenSize: screenSize,
                majorOSVersion: majorOSVersion,
                displayScale: displayScale,
                placement: placement,
                target: target
            )
        }

        let canvas = lookup(.designCanvas)
        /// Only the iPad Home Screen scales a canvas into a smaller slot. Everywhere else this is empty and the canvas size is the size the widget is drawn at, which is also true of an iPad Lock Screen widget.
        let rendered = lookup(.homeScreen)

        return Dictionary(uniqueKeysWithValues: canvas.map { widgetSize, canvasSize in
            (widgetSize, WidgetFrame(canvasSize: canvasSize, renderedSize: rendered[widgetSize]))
        })
    }

    /// Smallest frame this widget size takes across every device that has one.
    ///
    /// Useful for checking a widget in its tightest frame, and as a fallback when a `frame` lookup returns nil because no frame is known for that platform.
    ///
    /// Compares design canvas sizes only, since the canvas is the size widget content is laid out in and the iPad Home Screen frame is that canvas scaled down. Derived from the frame tables rather than listed separately, so a new measurement is reflected here without a second edit. A size with no frame in those tables has no minimum, so ``accessoryCorner`` returns zero.
    ///
    /// Where no candidate is smaller on both axes the one with the smallest area is used, which is why `extraLarge` is the 634.5x305.5 iPad canvas rather than the narrower but taller 550x354 visionOS frame.
    var minimumSize: CGSize {
        /// Every widget size has at least one frame on some platform, which `WidgetSizeExtremesTests` enforces, so the fallback is unreachable.
        WidgetFrameRecord.extremes[self]?.minimum ?? .zero
    }

    /// Largest frame this widget size takes across every device that has one.
    ///
    /// Useful for checking a widget in its roomiest frame, and as a fallback when a `frame` lookup returns nil because no frame is known for that platform.
    ///
    /// Derived from design canvas sizes the same way ``minimumSize`` is. Where no candidate is larger on both axes the one with the largest area is used.
    var maximumSize: CGSize {
        WidgetFrameRecord.extremes[self]?.maximum ?? .zero
    }
}
