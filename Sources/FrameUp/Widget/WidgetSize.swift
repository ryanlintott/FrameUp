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
public enum WidgetSize: String, Identifiable, CaseIterable {
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
    public enum Platform {
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
public enum WidgetTarget {
    case designCanvas, homeScreen
}

public extension WidgetSize {
    typealias Size = (CGFloat, CGFloat)
    
    /// Widget sizes for iPhone
    ///
    /// All sizes are sourced from [Apple Human Interface Guidelines: widget specifications](https://developer.apple.com/design/human-interface-guidelines/widgets#Specifications)
    ///
    /// > Note: `extraLargePortrait` is supported on iPhone from iOS 27 but has no frame here yet, so it is omitted from the dictionary.
    /// - Parameter screenSize: iPhone screen size ignoring orientation.
    /// - Returns: A dictionary of sizes based on widget size. Sizes with no known frame are omitted.
    static func sizesForiPhone(screenSize: CGSize) -> [WidgetSize: CGSize] {
        let widgetSizes: (Size, Size, Size, Size, Size, Size)
        
        switch (screenSize.width, screenSize.height) {
        case (430..., _): widgetSizes = ((170, 170), (364, 170), (364, 382), (76, 76), (172, 76), (257, 26))
        case (428..., _): widgetSizes = ((170, 170), (364, 170), (364, 382), (76, 76), (172, 76), (257, 26))
        case (414..., 896...): widgetSizes = ((169, 169), (360, 169), (360, 379), (76, 76), (160, 72), (248, 26))
        case (414..., _): widgetSizes = ((159, 159), (348, 157), (348, 357), (76, 76), (170, 76), (248, 26))
        case (393..., _): widgetSizes = ((158, 158), (338, 158), (338, 354), (72, 72), (160, 72), (234, 26))
        case (390..., _): widgetSizes = ((158, 158), (338, 158), (338, 354), (72, 72), (160, 72), (234, 26))
        case (375..., 812...): widgetSizes = ((155, 155), (329, 155), (329, 345), (72, 72), (157, 72), (225, 26))
        case (375..., _): widgetSizes = ((148, 148), (321, 148), (321, 324), (68, 68), (153, 68), (225, 26))
        case (360..., _): widgetSizes = ((155, 155), (329, 155), (329, 345), (72, 72), (157, 72), (225, 26))
        default: widgetSizes = ((141, 141), (292, 141), (292, 311), (72, 72), (157, 72), (225, 26))
        }
        
        return [
            .small: CGSize(width: widgetSizes.0.0, height: widgetSizes.0.1),
            .medium: CGSize(width: widgetSizes.1.0, height: widgetSizes.1.1),
            .large: CGSize(width: widgetSizes.2.0, height: widgetSizes.2.1),
            .accessoryCircular: CGSize(width: widgetSizes.3.0, height: widgetSizes.3.1),
            .accessoryRectangular: CGSize(width: widgetSizes.4.0, height: widgetSizes.4.1),
            .accessoryInline: CGSize(width: widgetSizes.5.0, height: widgetSizes.5.1)
        ]
    }

    /// Widget sizes for iPad
    ///
    /// All sizes are sourced from [Apple Human Interface Guidelines: widget specifications](https://developer.apple.com/design/human-interface-guidelines/widgets#Specifications)
    ///
    /// > Note: `extraLargePortrait` and the accessory sizes are supported on iPad but have no frame here yet, so they are omitted from the dictionary.
    /// - Parameter screenSize: iPad screen size ignoring orientation.
    /// - Parameter target: Widget frame target. iPad widgets have a design canvas frame used for laying out the content, and a smaller Home Screen frame that the content is scaled to fit.
    /// - Returns: A dictionary of sizes based on widget size. Sizes with no known frame are omitted.
    static func sizesForiPad(screenSize: CGSize, target: WidgetTarget) -> [WidgetSize: CGSize] {
        let widgetSizes: ((CGFloat, CGFloat), (CGFloat, CGFloat), (CGFloat, CGFloat), (CGFloat, CGFloat))
        
        switch (screenSize.width, screenSize.height, target) {
        case (1192..., _, .designCanvas): widgetSizes = ((188, 188), (412, 188), (412, 412), (860, 412))
        case (1192..., _, .homeScreen): widgetSizes = ((188, 188), (412, 188), (412, 412), (860, 412))
        case (1024..., _, .designCanvas): widgetSizes = ((170, 170), (378.5, 170), (378.5, 378.5), (795, 378.5))
        case (1024..., _, .homeScreen): widgetSizes = ((160, 160), (356, 160), (356, 356), (748, 356))
        case (970..., _, .designCanvas): widgetSizes = ((162, 162), (350, 162), (350, 350), (726, 350))
        case (970..., _, .homeScreen): widgetSizes = ((162, 162), (350, 162), (350, 350), (726, 350))
        case (954..., _, .designCanvas): widgetSizes = ((162, 162), (350, 162), (350, 350), (726, 350))
        case (954..., _, .homeScreen): widgetSizes = ((162, 162), (350, 162), (350, 350), (726, 350))
        case (834..., 1194..., .designCanvas): widgetSizes = ((155, 155), (342, 155), (342, 342), (715.5, 342))
        case (834..., 1194..., .homeScreen): widgetSizes = ((136, 136), (300, 136), (300, 300), (628, 300))
        case (834..., _, .designCanvas): widgetSizes = ((150, 150), (327.5, 150), (327.5, 327.5), (682, 327.5))
        case (834..., _, .homeScreen): widgetSizes = ((132, 132), (288, 132), (288, 288), (600, 288))
        case (820..., _, .designCanvas): widgetSizes = ((155, 155), (342, 155), (342, 342), (715.5, 342))
        case (820..., _, .homeScreen): widgetSizes = ((136, 136), (300, 136), (300, 300), (628, 300))
        case (810..., _, .designCanvas): widgetSizes = ((146, 146), (320.5, 146), (320.5, 320.5), (669, 320.5))
        case (810..., _, .homeScreen): widgetSizes = ((124, 124), (272, 124), (272, 272), (568, 272))
        case (768..., _, .designCanvas): widgetSizes = ((141, 141), (305.5, 141), (305.5, 305.5), (634.5, 305.5))
        case (768..., _, .homeScreen): widgetSizes = ((120, 120), (260, 120), (260, 260), (540, 260))
        case (_, _, .designCanvas): widgetSizes = ((141, 141), (305.5, 141), (305.5, 305.5), (634.5, 305.5))
        case (_, _, .homeScreen): widgetSizes = ((120, 120), (260, 120), (260, 260), (540, 260))
        }
        
        return [
            .small: CGSize(width: widgetSizes.0.0, height: widgetSizes.0.1),
            .medium: CGSize(width: widgetSizes.1.0, height: widgetSizes.1.1),
            .large: CGSize(width: widgetSizes.2.0, height: widgetSizes.2.1),
            .extraLarge: CGSize(width: widgetSizes.3.0, height: widgetSizes.3.1)
        ]
    }

    /// Widget sizes for visionOS.
    ///
    /// All sizes are sourced from [Apple Human Interface Guidelines: widget specifications](https://developer.apple.com/design/human-interface-guidelines/widgets#Specifications)
    ///
    /// > Note: `accessoryCircular` and `accessoryRectangular` are supported from visionOS 27 but have no frame here yet, so they are omitted from the dictionary.
    /// - Returns: A dictionary of sizes based on widget size. Sizes with no known frame are omitted.
    static func sizesForVisionOS() -> [WidgetSize: CGSize] {
        [
            .small: CGSize(width: 158, height: 158),
            .medium: CGSize(width: 338, height: 158),
            .large: CGSize(width: 338, height: 354),
            .extraLarge: CGSize(width: 450, height: 338),
            .extraLargePortrait: CGSize(width: 338, height: 450)
        ]
    }
    
    /// Apple Watch case size in mm for the supplied screen size.
    internal static func watchSize(screenSize: CGSize) -> CGFloat? {
        switch (screenSize.width, screenSize.height) {
        case (136, 170): 38
        case (156, 195): 42   // Series 1–3
        case (162, 197): 40
        case (176, 215): 41
        case (184, 224): 44
        case (187, 223): 42   // Series 10/11
        case (198, 242): 45
        case (205, 251): 49   // Ultra, Ultra 2
        case (208, 248): 46   // Series 10/11
        case (211, 257): 49   // Ultra 3
        default: nil
        }
    }
    
    /// Sizes of widgets in smart stack for Apple Watch.
    ///
    /// > Note: `accessoryCircular` and `accessoryInline` are supported on Apple Watch but have no frame here yet, so they are omitted from the dictionary.
    /// - Parameter screenSize: Apple Watch screen size in points.
    /// - Returns: A dictionary of sizes based on widget size. Sizes with no known frame are omitted. Empty if the screen size does not match a known Apple Watch, which will be the case for any watch released after this table was last updated.
    static func sizesForWatch(screenSize: CGSize) -> [WidgetSize: CGSize] {
        guard let watchSize = watchSize(screenSize: screenSize) else { return [:] }
        return sizesForWatch(watchSize: watchSize)
    }
    
    /// Sizes of widgets in smart stack for Apple Watch.
    ///
    /// All sizes are sourced from [Apple Human Interface Guidelines: widget specifications](https://developer.apple.com/design/human-interface-guidelines/widgets#Specifications)
    ///
    /// > Note: `accessoryCircular` and `accessoryInline` are supported on Apple Watch but have no frame here yet, so they are omitted from the dictionary. `accessoryCorner` is supported too but has no ``WidgetSize`` case.
    /// - Parameter watchSize: Apple Watch size in mm.
    /// - Returns: A dictionary of sizes based on widget size. Sizes with no known frame are omitted.
    static func sizesForWatch(watchSize: CGFloat) -> [WidgetSize: CGSize] {
        let size: (CGFloat, CGFloat)
        
        switch watchSize {
        case 49...: size = (191, 81.5)
        case 45...: size = (184, 80.5)
        case 44...: size = (173, 76.5)
        case 41...: size = (165, 72.5)
        default: size = (152, 69.5)
        }
        
        return [.accessoryRectangular: .init(width: size.0, height: size.1)]
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
    func sizeForiPhone(screenSize: CGSize) -> CGSize? {
        Self.sizesForiPhone(screenSize: screenSize)[self]
    }
    
    /// Size for this widget on an iPad with the specified screen size.
    ///
    /// > Note: `extraLargePortrait` and the accessory sizes are supported on iPad but have no frame here yet, so they return nil.
    /// - Parameter screenSize: iPad screen size ignoring orientation.
    /// - Parameter target: Widget frame target. iPad widgets have a design canvas frame used for laying out the content, and a smaller Home Screen frame that the content is scaled to fit.
    /// - Returns: Size for this widget. Nil if no frame is known, either because the platform does not support this widget size or because the frame has not been added to FrameUp yet.
    func sizeForiPad(screenSize: CGSize, target: WidgetTarget) -> CGSize? {
        Self.sizesForiPad(screenSize: screenSize, target: target)[self]
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
