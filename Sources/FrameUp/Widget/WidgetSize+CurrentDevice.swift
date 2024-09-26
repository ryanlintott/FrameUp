//
//  WidgetSize+CurrentDevice.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-01-25.
//


#if os(iOS)
import SwiftUI

public extension WidgetSize {
    /// The screen size ignoring orientation.
    @preconcurrency @MainActor
    private static let currentScreenSize =
        UIScreen.main.fixedCoordinateSpace.bounds.size
    
    /// The current device.
    @preconcurrency @MainActor
    private static let currentDevice = UIDevice.current.userInterfaceIdiom
    
    /// Find the supported sizes for a specified device
    /// - Parameter device: iPhone, iPad, etc
    /// - Returns: An array of widget sizes
    static func supportedSizes(for device: UIUserInterfaceIdiom) -> [WidgetSize] {
        switch device {
        case .pad:
            if #available(iOS 15.0, *) {
                return [.small, .medium, .large, .extraLarge]
            } else {
                return [.small, .medium, .large]
            }
        case .phone:
            if #available(iOS 16, *) {
                return [.small, .medium, .large, .accessoryCircular, .accessoryRectangular, .accessoryInline]
            } else {
                return [.small, .medium, .large]
            }
        default:
            return []
        }
    }
    
    /// Supported widget sizes for the current device.
    @preconcurrency @MainActor
    static var supportedSizesForCurrentDevice: [WidgetSize] {
        supportedSizes(for: currentDevice)
    }
    
    /// Size for this widget on the current device.
    /// - Parameter iPadTarget: Widget frame target. iPad widgets have a design canvas frame used for laying out the content, and a smaller Home Screen frame that the content is scaled to fit.
    /// - Returns: Size for this widget for the current device. Zero if device does not have widgets or if no size is available.
    @preconcurrency @MainActor
    func sizeForCurrentDevice(iPadTarget: WidgetTarget) -> CGSize? {
        switch Self.currentDevice {
        case .pad:
            return sizeForiPad(screenSize: Self.currentScreenSize, target: iPadTarget)
        case .phone:
            return sizeForiPhone(screenSize: Self.currentScreenSize)
        default:
            return nil
        }
    }
    
    /// How much the widget is scaled down to fit on the Home Screen.
    ///
    /// Home Screen width divided by design canvas width. iPhone value will always be 1.
    @preconcurrency @MainActor
    var scaleFactorForCurrentDevice: CGFloat? {
        switch Self.currentDevice {
        case .pad:
            return scaleFactorForiPad(screenSize: Self.currentScreenSize)
        case .phone:
            return 1
        default:
            return nil
        }
    }
}
#endif
