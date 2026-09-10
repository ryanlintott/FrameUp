//
//  WidgetSize+CurrentDevice.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-01-25.
//

import SwiftUI

#if os(iOS) || os(visionOS)
extension UIUserInterfaceIdiom {
    var platform: WidgetSize.Platform {
        switch self {
        case .phone: .phone
        case .pad: .pad
        case .carPlay: .carPlay
        case .mac: .macCatalyst
        case .vision: .vision
        case .tv, .unspecified: .unsupported
        @unknown default: .unsupported
        }
    }
}
#endif

extension WidgetSize.Platform {
    @preconcurrency @MainActor
    public static var current: Self {
        #if os(iOS) || os(visionOS)
        UIDevice.current.userInterfaceIdiom.platform
        #elseif os(macOS)
        .mac
        #elseif os(watchOS)
        .watch
        #else
        .unsupported
        #endif
    }
}

#if os(iOS)
public extension WidgetSize {
    /// The screen size ignoring orientation.
    @available(iOS, deprecated: 26)
    @MainActor
    internal static let currentScreenSize =
        UIScreen.main.fixedCoordinateSpace.bounds.size

    /// Pixels per point on the current display.
    ///
    /// Needed because a 414x896 screen is 2x on an iPhone 11 and 3x on an iPhone 11 Pro Max, and from iOS 26 those report different widget frames.
    @available(iOS, deprecated: 26)
    @MainActor
    internal static let currentDisplayScale = UIScreen.main.scale

    /// Find the supported sizes for a specified device
    /// - Parameter device: iPhone or iPad
    /// - Returns: An array of widget sizes
    @available(*, deprecated, message: "Getting the supported size for a specific device is no longer supported. Use `supportedSizes(platform:majorOSVersion:)` or `supportedSizesForCurrentDevice` instead.")
    static func supportedSizes(for device: UIUserInterfaceIdiom) -> [WidgetSize] {
        switch device {
        case .pad, .phone: supportedSizes(platform: device.platform)
        default: []
        }
    }

    /// The frame for this widget on the current device.
    ///
    /// On iPad, ``WidgetFrame/canvasSize`` and ``WidgetFrame/renderedSize`` differ on the Home Screen and ``WidgetFrame/scaleFactor`` is the ratio between them. Everywhere else the two are equal.
    ///
    /// > Note: CarPlay supports widgets but has no frames here yet, so it returns nil for every widget size.
    /// - Parameter placement: Where the widget appears. Nil reports Home Screen frames for the system sizes and Lock Screen frames for the accessory sizes, which is where each of them actually appears.
    /// - Returns: The frame for this widget on the current device. Nil if no frame is known, either because the current device does not support this widget size or because it has not been measured yet.
    @MainActor
    func frameForCurrentDevice(placement: WidgetPlacement? = nil) -> WidgetFrame? {
        frame(
            platform: .current,
            screenSize: Self.currentScreenSize,
            displayScale: Self.currentDisplayScale,
            placement: placement
        )
    }
}
#elseif os(macOS)
public extension WidgetSize {
    /// The frame for this widget on the current device.
    ///
    /// A Mac widget is not placed on a screen grid, so its frame does not depend on the screen size, and it is not scaled, so ``WidgetFrame/canvasSize`` and ``WidgetFrame/renderedSize`` are equal.
    ///
    /// > Note: measured on macOS 26 and applying from there. Earlier versions return nil, as does `extraLargePortrait`, which arrives in macOS 27 and could not be measured on a Mac running 26. The accessory sizes do not exist on macOS.
    /// - Returns: The frame for this widget on the current device. Nil if no frame is known, either because the current device does not support this widget size or because it has not been measured yet.
    func frameForCurrentDevice() -> WidgetFrame? {
        frame(platform: .mac)
    }
}
#elseif os(visionOS)
public extension WidgetSize {
    /// The frame for this widget on the current device.
    ///
    /// A visionOS widget is placed on a surface rather than a screen grid, so its frame does not depend on the screen size, and it is not scaled, so ``WidgetFrame/canvasSize`` and ``WidgetFrame/renderedSize`` are equal.
    ///
    /// > Note: `accessoryCircular` and `accessoryRectangular` arrive in visionOS 27, so they return nil on earlier versions. `accessoryInline` does not exist on visionOS at all.
    /// - Returns: The frame for this widget on the current device. Nil if no frame is known, either because the current device does not support this widget size or because it has not been measured yet.
    func frameForCurrentDevice() -> WidgetFrame? {
        frame(platform: .vision)
    }
}
#elseif os(watchOS)
import WatchKit

public extension WidgetSize {
    /// The frame for this widget on the current device.
    ///
    /// An Apple Watch widget is not scaled, so ``WidgetFrame/canvasSize`` and ``WidgetFrame/renderedSize`` are equal.
    ///
    /// > Note: `accessoryInline` and `accessoryCorner` return nil, having no stored frame. A watch released after this table was last updated resolves to the nearest known screen size.
    /// - Parameter placement: Where the widget appears. Nil reports the Smart Stack frame for `accessoryRectangular` and the watch face frame for `accessoryCircular`, which is where each of them appears.
    /// - Returns: The frame for this widget on the current device. Nil if no frame is known, either because the current device does not support this widget size or because it has not been measured yet.
    func frameForCurrentDevice(placement: WidgetPlacement? = nil) -> WidgetFrame? {
        frame(
            platform: .watch,
            screenSize: WKInterfaceDevice.current().screenBounds.size,
            placement: placement
        )
    }
}
#endif
