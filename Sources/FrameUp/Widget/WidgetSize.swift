//
//  WidgetSize.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-09-17.
//

import SwiftUI

/// A template with similar elements to WidgetFamily that can be used without importing WidgetKit
///
/// Used to specify widget sizes for preview purposes inside an app.
///
/// There is a case for every widget size Apple publishes, but whether a platform *supports* a size and whether FrameUp *knows the frame* for it are two separate questions:
///
/// - ``supportedSizesForCurrentDevice`` answers whether the current platform and OS version can show a widget of this size.
/// - The `sizeFor` lookups answer what frame that widget gets, and return nil when no measurement has been added to FrameUp yet.
///
/// A size can therefore be supported and still have no frame. Sizes that are supported but have no frame yet:
///
/// | Platform | Unknown Frame Sizes |
/// | --- | --- |
/// | iPhone | `extraLargePortrait` |
/// | iPad | `extraLargePortrait` and every accessory size |
/// | visionOS | `accessoryCircular` and `accessoryRectangular` |
/// | Apple Watch | `accessoryCircular` and `accessoryInline` |
/// | macOS, Mac Catalyst, CarPlay | every size |
///
/// ``minimumSize`` and ``maximumSize`` always return a value for every case, so they are a useful fallback when no device frame is known.
public enum WidgetSize: String, Identifiable, CaseIterable, Sendable {
    case small
    case medium
    case large
    case extraLarge
    case extraLargePortrait
    case accessoryCircular
    case accessoryRectangular
    case accessoryInline
    
    public var id: String {
        self.rawValue
    }
}

extension WidgetSize {
    /// All Apple platforms that support widgets.
    ///
    /// Supporting a widget size does not mean FrameUp has a frame for it. See ``WidgetSize`` for the sizes that are supported but not yet measured.
    public enum Platform: Sendable {
        case phone
        case pad
        case mac
        case macCatalyst
        case watch
        case vision
        case carPlay
        /// A platform that does not support widgets
        case unsupported
    }
}

/// iPad widget frame target.
///
/// iPad widgets have a design canvas frame used for laying out the content, and a smaller Home Screen frame that the content is scaled to fit. This parameter can be used to specify which size you want.
public enum WidgetTarget: Sendable {
    case designCanvas, homeScreen
}

public extension WidgetSize {
    typealias Size = (CGFloat, CGFloat)
    
    /// Widget sizes for iPhone
    ///
    /// Frames for iOS 25 and earlier are sourced from [Apple Human Interface Guidelines: widget specifications](https://developer.apple.com/design/human-interface-guidelines/widgets#Specifications). iOS 26 changed the frame of every iPhone widget, and Apple has not updated that table, so frames for iOS 26 and later are measured instead. See ``WidgetFrame`` and `Measurements/` in the repository.
    ///
    /// A screen size with no exact entry resolves to the nearest known screen size by width, then by height. Screen sizes that Apple never published a row for, such as the 402 and 440 point wide iPhones, are included.
    ///
    /// > Note: `extraLargePortrait` is supported on iPhone from iOS 27 but has no frame here yet, so it is omitted from the dictionary. The accessory sizes have not been measured on iOS 26 yet, so those frames are the published iOS 18 values and may be out of date.
    /// - Parameter screenSize: iPhone screen size ignoring orientation.
    /// - Parameter majorOSVersion: Major iOS version to look up frames for. Nil uses the version currently running.
    /// - Parameter displayScale: Pixels per point on the display, matching SwiftUI's `displayScale` environment value. Only needed for a 414x896 screen, which is 2x on an iPhone 11 and 3x on an iPhone 11 Pro Max and from iOS 26 gives different frames for each. Nil still returns a stable answer, preferring the 2x frames for that screen size.
    /// - Parameter placement: Where the widget appears. Nil reports Home Screen frames for the system sizes and Lock Screen frames for the accessory sizes, which is where each of them actually appears.
    /// - Returns: A dictionary of sizes based on widget size. Sizes with no known frame are omitted.
    static func sizesForiPhone(
        screenSize: CGSize,
        majorOSVersion: Int? = nil,
        displayScale: CGFloat? = nil,
        placement: WidgetPlacement? = nil
    ) -> [WidgetSize: CGSize] {
        WidgetFrame.frames(
            platform: .phone,
            screenSize: screenSize,
            majorOSVersion: majorOSVersion ?? WidgetFrame.currentMajorOSVersion,
            displayScale: displayScale,
            placement: placement
        )
    }

    /// Widget sizes for iPad
    ///
    /// Frames are sourced from [Apple Human Interface Guidelines: widget specifications](https://developer.apple.com/design/human-interface-guidelines/widgets#Specifications), with the 820x1180 values confirmed by measurement. Unlike iPhone, iPad frames did not change in iOS 26.
    ///
    /// A screen size with no exact entry resolves to the nearest known screen size by width, then by height.
    ///
    /// > Note: `extraLargePortrait` is supported on iPad from iOS 27 but has no frame here yet, so it is omitted. The accessory sizes and the smaller Lock Screen `small` frame are only known for a 820x1180 iPad and only for the design canvas target.
    /// - Parameter screenSize: iPad screen size ignoring orientation.
    /// - Parameter target: Widget frame target. iPad widgets have a design canvas frame used for laying out the content, and a smaller Home Screen frame that the content is scaled to fit.
    /// - Parameter majorOSVersion: Major iPadOS version to look up frames for. Nil uses the version currently running.
    /// - Parameter placement: Where the widget appears. Nil reports Home Screen frames for the system sizes and Lock Screen frames for the accessory sizes, which is where each of them actually appears.
    /// - Returns: A dictionary of sizes based on widget size. Sizes with no known frame are omitted.
    static func sizesForiPad(
        screenSize: CGSize,
        target: WidgetTarget,
        majorOSVersion: Int? = nil,
        placement: WidgetPlacement? = nil
    ) -> [WidgetSize: CGSize] {
        WidgetFrame.frames(
            platform: .pad,
            screenSize: screenSize,
            majorOSVersion: majorOSVersion ?? WidgetFrame.currentMajorOSVersion,
            placement: placement,
            target: target
        )
    }

    /// Widget sizes for visionOS.
    ///
    /// All sizes are sourced from [Apple Human Interface Guidelines: widget specifications](https://developer.apple.com/design/human-interface-guidelines/widgets#Specifications)
    ///
    /// > Note: `accessoryCircular` and `accessoryRectangular` are supported from visionOS 27 but have no frame here yet, so they are omitted from the dictionary.
    /// - Returns: A dictionary of sizes based on widget size. Sizes with no known frame are omitted.
    static func sizesForVisionOS() -> [WidgetSize: CGSize] {
        WidgetFrame.frames(
            platform: .vision,
            /// visionOS widgets are placed on surfaces rather than a screen, so there is no screen size to look up.
            screenSize: .zero,
            majorOSVersion: WidgetFrame.currentMajorOSVersion
        )
    }

    /// Apple Watch case size in mm for the supplied screen size.
    internal static func watchSize(screenSize: CGSize) -> CGFloat? {
        WidgetFrame.watchDevices.first { $0.screenSize == screenSize }?.caseSize
    }
    
    /// Sizes of widgets in smart stack for Apple Watch.
    ///
    /// > Note: `accessoryCircular` and `accessoryInline` are supported on Apple Watch but have no frame here yet, so they are omitted from the dictionary.
    /// - Parameter screenSize: Apple Watch screen size in points.
    /// - Returns: A dictionary of sizes based on widget size. Sizes with no known frame are omitted. Empty if the screen size does not match a known Apple Watch, which will be the case for any watch released after this table was last updated.
    static func sizesForWatch(screenSize: CGSize) -> [WidgetSize: CGSize] {
        WidgetFrame.frames(
            platform: .watch,
            screenSize: screenSize,
            majorOSVersion: WidgetFrame.currentMajorOSVersion
        )
    }
    
    /// Sizes of widgets in smart stack for Apple Watch.
    ///
    /// All sizes are sourced from [Apple Human Interface Guidelines: widget specifications](https://developer.apple.com/design/human-interface-guidelines/widgets#Specifications)
    ///
    /// > Note: `accessoryCircular` and `accessoryInline` are supported on Apple Watch but have no frame here yet, so they are omitted from the dictionary. `accessoryCorner` is supported too but has no ``WidgetSize`` case.
    /// - Parameter watchSize: Apple Watch size in mm.
    /// - Returns: A dictionary of sizes based on widget size. Sizes with no known frame are omitted.
    static func sizesForWatch(watchSize: CGFloat) -> [WidgetSize: CGSize] {
        guard let frame = WidgetFrame.watchRectangular(caseSize: watchSize) else { return [:] }
        return [.accessoryRectangular: frame]
    }
    
    /// Smallest size for this widget size across every device that supports it.
    ///
    /// Useful for checking a widget in its tightest frame, and as a fallback when a `sizeFor` lookup returns nil because no frame is known for that platform.
    ///
    /// Values are taken from the size tables above, using the iPad design canvas rather than the smaller Home Screen frame since the design canvas is the size widget content is laid out in. Where no candidate is smaller on both axes the one with the smallest area is used, which is why `extraLarge` is the visionOS frame rather than the wider iPad canvas, and why `accessoryRectangular` is the iPhone frame rather than the narrower but taller 38mm watch frame.
    var minimumSize: CGSize {
        switch self {
        case .small: .init(width: 141, height: 141)
        case .medium: .init(width: 292, height: 141)
        case .large: .init(width: 292, height: 311)
        case .extraLarge: .init(width: 450, height: 338)
        case .extraLargePortrait: .init(width: 338, height: 450)
        case .accessoryCircular: .init(width: 68, height: 68)
        case .accessoryRectangular: .init(width: 153, height: 68)
        case .accessoryInline: .init(width: 225, height: 26)
        }
    }
    
    /// Largest size for this widget size across every device that supports it.
    ///
    /// Useful for checking a widget in its roomiest frame, and as a fallback when a `sizeFor` lookup returns nil because no frame is known for that platform.
    ///
    /// Values are taken from the size tables above, using the iPad design canvas rather than the smaller Home Screen frame since the design canvas is the size widget content is laid out in. Where no candidate is larger on both axes the one with the largest area is used.
    var maximumSize: CGSize {
        switch self {
        case .small: .init(width: 188, height: 188)
        case .medium: .init(width: 412, height: 188)
        case .large: .init(width: 412, height: 412)
        case .extraLarge: .init(width: 860, height: 412)
        case .extraLargePortrait: .init(width: 338, height: 450)
        case .accessoryCircular: .init(width: 76, height: 76)
        case .accessoryRectangular: .init(width: 191, height: 81.5)
        case .accessoryInline: .init(width: 257, height: 26)
        }
    }
    
    /// Size for this widget on an iPhone with the specified screen size.
    ///
    /// > Note: `extraLargePortrait` is supported on iPhone from iOS 27 but has no frame here yet, so it returns nil.
    /// - Parameter screenSize: iPhone screen size ignoring orientation.
    /// - Returns: Size for this widget. Nil if no frame is known, either because the platform does not support this widget size or because the frame has not been added to FrameUp yet.
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
    
    /// Size for this widget on an iPad with the specified screen size.
    ///
    /// > Note: `extraLargePortrait` and the accessory sizes are supported on iPad but have no frame here yet, so they return nil.
    /// - Parameter screenSize: iPad screen size ignoring orientation.
    /// - Parameter target: Widget frame target. iPad widgets have a design canvas frame used for laying out the content, and a smaller Home Screen frame that the content is scaled to fit.
    /// - Returns: Size for this widget. Nil if no frame is known, either because the platform does not support this widget size or because the frame has not been added to FrameUp yet.
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

    /// Size for this widget on visionOS.
    ///
    /// > Note: `accessoryCircular` and `accessoryRectangular` are supported from visionOS 27 but have no frame here yet, so they return nil.
    /// - Returns: Size for this widget. Nil if no frame is known, either because the platform does not support this widget size or because the frame has not been added to FrameUp yet.
    func sizeForVisionOS() -> CGSize? {
        Self.sizesForVisionOS()[self]
    }
    
    /// Size for this widget on a watch with the specified screen size.
    ///
    /// > Note: `accessoryCircular` and `accessoryInline` are supported on Apple Watch but have no frame here yet, so they return nil. A screen size that does not match a known Apple Watch also returns nil for every widget size.
    /// - Parameter screenSize: Apple Watch screen size in points.
    /// - Returns: Size for this widget. Nil if no frame is known, either because the platform does not support this widget size or because the frame has not been added to FrameUp yet.
    func sizeForWatch(screenSize: CGSize) -> CGSize? {
        Self.sizesForWatch(screenSize: screenSize)[self]
    }
    
    /// Size for this widget on a watch of the specified case size.
    ///
    /// > Note: `accessoryCircular` and `accessoryInline` are supported on Apple Watch but have no frame here yet, so they return nil.
    /// - Parameter watchSize: Apple Watch size in mm.
    /// - Returns: Size for this widget. Nil if no frame is known, either because the platform does not support this widget size or because the frame has not been added to FrameUp yet.
    func sizeForWatch(watchSize: CGFloat) -> CGSize? {
        Self.sizesForWatch(watchSize: watchSize)[self]
    }
    
    /// How much the widget is scaled down to fit on the Home Screen.
    ///
    /// Home Screen width divided by design canvas width
    /// - Parameter screenSize: iPad screen size ignoring orientation.
    /// - Returns: Widget scale factor between design canvas and Home Screen. Nil if no iPad frame is known for this widget size.
    func scaleFactorForiPad(screenSize: CGSize) -> CGFloat? {
        guard let homeScreen = sizeForiPad(screenSize: screenSize, target: .homeScreen),
              let designCanvas = sizeForiPad(screenSize: screenSize, target: .designCanvas)
        else { return nil }
        return homeScreen.width / designCanvas.width
    }
}
