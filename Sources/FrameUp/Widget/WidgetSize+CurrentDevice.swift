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

public extension WidgetSize {
    /// Supported widget sizes for the current device.
    ///
    /// This reports what the current platform and OS version support, not what FrameUp can measure. A size listed here may still have no frame, in which case `sizeForCurrentDevice` returns nil and ``minimumSize`` or ``maximumSize`` can be used as a fallback. See ``WidgetSize`` for the sizes that are supported but not yet measured.
    @preconcurrency @MainActor
    static var supportedSizesForCurrentDevice: [WidgetSize] {
        switch Platform.current {
        case .phone:
            if #available(iOS 27, *) {
                [.small, .medium, .large, .extraLargePortrait, .accessoryCircular, .accessoryRectangular, .accessoryInline]
            } else if #available(iOS 16, *) {
                [.small, .medium, .large, .accessoryCircular, .accessoryRectangular, .accessoryInline]
            } else {
                [.small, .medium, .large]
            }
        case .pad:
            if #available(iOS 27, *) {
                [.small, .medium, .large, .extraLarge, .extraLargePortrait, .accessoryCircular, .accessoryRectangular, .accessoryInline]
            } else if #available(iOS 16, *) {
                [.small, .medium, .large, .extraLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline]
            } else {
                [.small, .medium, .large, .extraLarge]
            }
        case .macCatalyst:
            // Widgets in a Mac Catalyst app are hosted by macOS so the sizes match `mac` and no accessory sizes are available.
            // Mac Catalyst versions track iOS, so macCatalyst 17 is macOS 14 and macCatalyst 27 is macOS 27.
            if #available(macCatalyst 27, *) {
                [.small, .medium, .large, .extraLarge, .extraLargePortrait]
            } else if #available(macCatalyst 17, *) {
                [.small, .medium, .large, .extraLarge]
            } else {
                [.small, .medium, .large]
            }
        case .mac:
            if #available(macOS 27, *) {
                [.small, .medium, .large, .extraLarge, .extraLargePortrait]
            } else if #available(macOS 14, *) {
                [.small, .medium, .large, .extraLarge]
            } else {
                [.small, .medium, .large]
            }
        case .vision:
            if #available(visionOS 27, *) {
                [.small, .medium, .large, .extraLarge, .extraLargePortrait, .accessoryCircular, .accessoryRectangular]
            } else if #available(visionOS 26, *) {
                [.small, .medium, .large, .extraLarge, .extraLargePortrait]
            } else {
                []
            }
        case .watch:
            [.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner]
        case .carPlay:
            if #available(iOS 26, *) {
                [.small, .medium, .accessoryCircular, .accessoryRectangular, .accessoryInline]
            } else {
                []
            }
        case .unsupported:
            []
        }
    }
}

#if os(iOS)
public extension WidgetSize {
    /// The screen size ignoring orientation.
    @available(iOS, deprecated: 26)
    @MainActor
    private static let currentScreenSize =
        UIScreen.main.fixedCoordinateSpace.bounds.size
    
    /// The current device.
    @MainActor
    private static let currentDevice = UIDevice.current.userInterfaceIdiom

    /// Pixels per point on the current display.
    ///
    /// Needed because a 414x896 screen is 2x on an iPhone 11 and 3x on an iPhone 11 Pro Max, and from iOS 26 those report different widget frames.
    @available(iOS, deprecated: 26)
    @MainActor
    private static let currentDisplayScale = UIScreen.main.scale
    
    /// Find the supported sizes for a specified device
    /// - Parameter device: iPhone or iPad
    /// - Returns: An array of widget sizes
    @available(*, deprecated, message: "Getting the supported size for a specific device is no longer supported. Use `supportedSizesForCurrentDevice` to get supported sizes for the current device instead.")
    static func supportedSizes(for device: UIUserInterfaceIdiom) -> [WidgetSize] {
        switch device {
        case .pad:
            if #available(iOS 27, *) {
                [.small, .medium, .large, .extraLarge, .extraLargePortrait, .accessoryCircular, .accessoryRectangular, .accessoryInline]
            } else if #available(iOS 16, *) {
                [.small, .medium, .large, .extraLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline]
            } else {
                [.small, .medium, .large, .extraLarge]
            }
        case .phone:
            if #available(iOS 27, *) {
                [.small, .medium, .large, .extraLargePortrait, .accessoryCircular, .accessoryRectangular, .accessoryInline]
            } else if #available(iOS 16, *) {
                [.small, .medium, .large, .accessoryCircular, .accessoryRectangular, .accessoryInline]
            } else {
                [.small, .medium, .large]
            }
        default:
            []
        }
    }
    
    /// Size for this widget on the current device.
    ///
    /// > Note: CarPlay supports widgets but has no frames here yet, so it returns nil for every widget size. On iPad the accessory sizes, the Lock Screen `small` frame and `extraLargePortrait` are only known for the design canvas, so asking for the Home Screen target returns nil for those.
    /// - Parameter iPadTarget: Widget frame target. iPad widgets have a design canvas frame used for laying out the content, and a smaller Home Screen frame that the content is scaled to fit.
    /// - Returns: Size for this widget for the current device. Nil if no frame is known, either because the current device does not support this widget size or because the frame has not been added to FrameUp yet.
    @preconcurrency @MainActor
    func sizeForCurrentDevice(iPadTarget: WidgetTarget) -> CGSize? {
        switch Platform.current {
        case .phone:
            sizeForiPhone(screenSize: Self.currentScreenSize, displayScale: Self.currentDisplayScale)
        case .pad:
            sizeForiPad(screenSize: Self.currentScreenSize, target: iPadTarget)
        case .macCatalyst:
            /// Widgets in a Mac Catalyst app are hosted by macOS, so they take the macOS frames.
            sizeForMac()
        default:
            nil
        }
    }
    
    /// How much the widget is scaled down to fit on the Home Screen.
    ///
    /// Home Screen width divided by design canvas width. Only iPad scales its widgets, so every other platform is 1.
    ///
    /// Nil if the current platform has no frames, or if no frame is known for this widget size.
    @preconcurrency @MainActor
    var scaleFactorForCurrentDevice: CGFloat? {
        switch Platform.current {
        case .pad:
            scaleFactorForiPad(screenSize: Self.currentScreenSize)
        case .phone:
            1
        case .macCatalyst:
            /// A Mac widget is not laid out on a canvas and scaled into a grid slot the way an iPad widget is.
            sizeForMac() == nil ? nil : 1
        default:
            nil
        }
    }
}
#elseif os(visionOS)
public extension WidgetSize {
    /// Size for this widget on the current device.
    ///
    /// > Note: `accessoryCircular` and `accessoryRectangular` arrive in visionOS 27, so they return nil on earlier versions. `accessoryInline` does not exist on visionOS at all.
    /// - Returns: Size for this widget for the current device. Nil if no frame is known, either because the current device does not support this widget size or because the frame has not been added to FrameUp yet.
    func sizeForCurrentDevice() -> CGSize? {
        sizeForVisionOS()
    }
}
#elseif os(watchOS)
import WatchKit

public extension WidgetSize {
    /// Size for this widget on the current device.
    ///
    /// > Note: `accessoryInline` and `accessoryCorner` return nil, having no stored frame. A watch released after this table was last updated resolves to the nearest known screen size.
    /// - Returns: Size for this widget for the current device. Nil if no frame is known, either because the current device does not support this widget size or because the frame has not been added to FrameUp yet.
    func sizeForCurrentDevice() -> CGSize? {
        sizeForWatch(screenSize: WKInterfaceDevice.current().screenBounds.size)
    }
}
#endif
