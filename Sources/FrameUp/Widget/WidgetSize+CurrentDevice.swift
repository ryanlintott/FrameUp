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
        case .tv: .tv
        case .carPlay: .carPlay
        case .mac: .macCatalyst
        case .vision: .vision
        case .unspecified: .unspecified
        @unknown default: .unspecified
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
        .unspecified
        #endif
    }
    
    #if os(iOS) || os(visionOS)
    var userInterfaceIdiom: UIUserInterfaceIdiom? {
        switch self {
        case .phone: .phone
        case .pad: .pad
        case .mac: nil
        case .macCatalyst: .mac
        case .watch: nil
        case .vision:
            if #available(iOS 17, *) {
                .vision
            } else {
                nil
            }
        case .tv: .tv
        case .carPlay: .carPlay
        case .unspecified: .unspecified
        }
    }
    #endif
    
    public var supportedSizes: [WidgetSize] {
        switch self {
        case .phone, .pad, .macCatalyst:
            if #available(iOS 27, *) {
                [.small, .medium, .large, .extraLargePortrait, .accessoryCircular, .accessoryRectangular, .accessoryInline]
            } else if #available(iOS 16, *) {
                [.small, .medium, .large, .accessoryCircular, .accessoryRectangular, .accessoryInline]
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
            [.accessoryCircular, .accessoryRectangular, .accessoryInline]
            //.accessoryCorner is supported as well but no size is known
        case .carPlay:
            if #available(iOS 26, *) {
                [.small, .medium, .accessoryCircular, .accessoryRectangular, .accessoryInline]
            } else {
                []
            }
        case .tv:
            []
        case .unspecified:
            []
        @unknown default:
            []
        }
    }
}

public extension WidgetSize {
    /// Supported widget sizes for the current device.
    @preconcurrency @MainActor
    static var supportedSizesForCurrentDevice: [WidgetSize] {
        Platform.current.supportedSizes
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
    
    /// Find the supported sizes for a specified device
    /// - Parameter device: iPhone or iPad
    /// - Returns: An array of widget sizes
    @available(*, deprecated, message: "Use ``WidgetSize.Platform.supportedSizes`` instead.")
    static func supportedSizes(for device: UIUserInterfaceIdiom) -> [WidgetSize] {
        device.platform.supportedSizes
    }
    
    /// Size for this widget on the current device.
    /// - Parameter iPadTarget: Widget frame target. iPad widgets have a design canvas frame used for laying out the content, and a smaller Home Screen frame that the content is scaled to fit.
    /// - Returns: Size for this widget for the current device. Zero if device does not have widgets or if no size is available.
    @preconcurrency @MainActor
    func sizeForCurrentDevice(iPadTarget: WidgetTarget) -> CGSize? {
        switch Platform.current {
        case .phone:
            sizeForiPhone(screenSize: Self.currentScreenSize)
        case .pad:
            sizeForiPad(screenSize: Self.currentScreenSize, target: iPadTarget)
        case .macCatalyst:
            nil
        default:
            nil
        }
    }
    
    /// How much the widget is scaled down to fit on the Home Screen.
    ///
    /// Home Screen width divided by design canvas width. iPhone value will always be 1.
    @preconcurrency @MainActor
    var scaleFactorForCurrentDevice: CGFloat? {
        switch Platform.current {
        case .pad:
            scaleFactorForiPad(screenSize: Self.currentScreenSize)
        case .phone:
            1
        case .macCatalyst:
            nil
        default:
            nil
        }
    }
}
#elseif os(visionOS)
public extension WidgetSize {
    /// Size for this widget on the current device.
    func sizeForCurrentDevice() -> CGSize? {
        sizeForVisionOS()
    }
}
#elseif os(watchOS)
import WatchKit

public extension WidgetSize {
    /// Size for this widget on the current device.
    func sizeForCurrentDevice() -> CGSize? {
        sizeForWatch(screenSize: WKInterfaceDevice.current().screenBounds.size)
    }
}
#endif
