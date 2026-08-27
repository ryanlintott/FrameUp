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
/// | iPhone | none |
/// | iPad | none. The accessory sizes and the Lock Screen `small` frame appear only on the design canvas target, because a Lock Screen widget is drawn at its canvas size rather than scaled into the Home Screen grid. |
/// | macOS, Mac Catalyst | `extraLargePortrait`, which arrives in macOS 27 and could not be measured on macOS 26. Earlier than macOS 26 no size has a frame, since Apple publishes none and iOS frames are known to have changed at 26. |
/// | visionOS | none |
/// | Apple Watch | `accessoryInline`, which reports a small square that never renders rather than a usable frame. `accessoryCircular` has a watch face frame but none in the Smart Stack, where it does not appear. `accessoryCorner` is supported too but has no ``WidgetSize`` case. |
/// | CarPlay | every size |
///
/// Frames are also known for two of the places a widget can appear, the Home Screen and the Lock Screen, and for the Apple Watch Smart Stack. The other ``WidgetPlacement`` cases have no frames: StandBy and CarPlay cannot be reached in a simulator, and the rest have not been measured.
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
///
/// The scaling is a Home Screen and Today View behaviour, not something iPad does to every widget. A widget on the iPad Lock Screen is drawn at its design canvas size: placing the probe there and measuring the pixels gives 63x63, 152x63 and 152x152 on a 820x1180 iPad, exactly the canvas values, where the Home Screen scale factor would have produced fractional pixels. So the two targets differ only where a widget is laid into the Home Screen grid, and the Lock Screen sizes have one frame rather than two.
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
    /// Every size iPhone supports has a measured frame on every screen size iOS 26 and later runs on, including the accessory sizes, which changed in iOS 26 by more than the system sizes did, and `extraLargePortrait`, which arrived in iOS 27 and which Apple publishes no row for on any platform.
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
    /// > Note: `extraLargePortrait` has both targets, though on iPad it is offered in Today View rather than on the Home Screen grid. The accessory sizes and the Lock Screen `small` frame are design canvas only, and that is the whole story rather than a gap: a Lock Screen widget is not scaled, so its canvas frame is the size it draws at. See ``WidgetTarget``.
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

    /// Widget sizes for macOS and Mac Catalyst.
    ///
    /// Apple publishes no widget specifications for macOS, so these are measured. Widgets in a Mac Catalyst app are hosted by macOS and use the same frames.
    ///
    /// > Note: measured on macOS 26 and applying from there. Earlier versions report no frame, since Apple publishes none and the iOS frames are known to have changed at 26. `extraLargePortrait` arrives in macOS 27 and could not be measured on a Mac running 26. The accessory sizes do not exist on macOS.
    /// - Parameter majorOSVersion: Major macOS version to look up frames for. Nil uses the version currently running.
    /// - Returns: A dictionary of sizes based on widget size. Sizes with no known frame are omitted.
    static func sizesForMac(majorOSVersion: Int? = nil) -> [WidgetSize: CGSize] {
        WidgetFrame.frames(
            platform: .mac,
            /// A Mac widget is not placed on a screen grid, so there is no screen size to look up.
            screenSize: .zero,
            majorOSVersion: majorOSVersion ?? WidgetFrame.currentMajorOSVersion
        )
    }

    /// Widget sizes for visionOS.
    ///
    /// Measured rather than published. Apple's table has a visionOS row but only `small` matches what the system reports, and the frames measure the same on visionOS 26.5 and 27.0, so the published values were never right rather than having changed. There is no accessory row published at all.
    ///
    /// > Note: `accessoryCircular` and `accessoryRectangular` arrive in visionOS 27, so they are omitted for earlier versions. visionOS has no `accessoryInline`, and widgets themselves arrive in visionOS 26, so every size is omitted before that.
    /// - Parameter majorOSVersion: Major visionOS version to look up frames for. Nil uses the version currently running.
    /// - Returns: A dictionary of sizes based on widget size. Sizes with no known frame are omitted.
    static func sizesForVisionOS(majorOSVersion: Int? = nil) -> [WidgetSize: CGSize] {
        WidgetFrame.frames(
            platform: .vision,
            /// visionOS widgets are placed on surfaces rather than a screen, so there is no screen size to look up.
            screenSize: .zero,
            majorOSVersion: majorOSVersion ?? WidgetFrame.currentMajorOSVersion
        )
    }

    /// Apple Watch case size in mm for the supplied screen size.
    internal static func watchSize(screenSize: CGSize) -> CGFloat? {
        WidgetFrame.watchDevices.first { $0.screenSize == screenSize }?.caseSize
    }
    
    /// Sizes of widgets in smart stack for Apple Watch.
    ///
    /// Measured on watchOS 27 for the five case sizes with a simulator, and Apple's published values elsewhere. Apple publishes one Smart Stack frame per case size and nothing for the watch face, so a complication frame is measured only.
    ///
    /// > Note: `accessoryInline` has no frame. It reports a small square, 11x11 to 13.5x13.5, that never renders. `accessoryCircular` only appears on the watch face, so a Smart Stack lookup omits it.
    /// - Parameter screenSize: Apple Watch screen size in points.
    /// - Parameter placement: Where the widget appears. Nil reports the Smart Stack frame for `accessoryRectangular`, which is where Apple's published values apply, and the watch face frame for `accessoryCircular`.
    /// - Returns: A dictionary of sizes based on widget size. Sizes with no known frame are omitted. Empty if the screen size does not match a known Apple Watch, which will be the case for any watch released after this table was last updated.
    static func sizesForWatch(screenSize: CGSize, placement: WidgetPlacement? = nil) -> [WidgetSize: CGSize] {
        WidgetFrame.frames(
            platform: .watch,
            screenSize: screenSize,
            majorOSVersion: WidgetFrame.currentMajorOSVersion,
            placement: placement
        )
    }
    
    /// Sizes of widgets in smart stack for Apple Watch.
    ///
    /// All sizes are sourced from [Apple Human Interface Guidelines: widget specifications](https://developer.apple.com/design/human-interface-guidelines/widgets#Specifications)
    ///
    /// > Important: a case size does not identify a watch. The Ultra 2 and Ultra 3 are both 49mm but report 205x251 and 211x257 screens and different frames, and this lookup returns Apple's published 49mm row for both. ``sizesForWatch(screenSize:)`` distinguishes them. This overload also returns only the published Smart Stack values, so it does not carry the measured corrections for the 42mm, 46mm and Ultra 3 watches.
    ///
    /// > Note: `accessoryCircular` and `accessoryInline` are omitted. Apple publishes only the Smart Stack rectangular row.
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
    /// Derived from the frame tables rather than listed separately, so a new measurement is reflected here without a second edit. The iPad design canvas is used rather than the smaller Home Screen frame, since the design canvas is the size widget content is laid out in. Where no candidate is smaller on both axes the one with the smallest area is used, which is why `extraLarge` is the 634.5x305.5 iPad canvas rather than the narrower but taller 550x354 visionOS frame.
    var minimumSize: CGSize {
        /// Every widget size has at least one frame on some platform, which `WidgetSizeExtremesTests` enforces, so the fallback is unreachable.
        WidgetFrame.extremes[self]?.minimum ?? .zero
    }
    
    /// Largest size for this widget size across every device that supports it.
    ///
    /// Useful for checking a widget in its roomiest frame, and as a fallback when a `sizeFor` lookup returns nil because no frame is known for that platform.
    ///
    /// Derived from the frame tables the same way ``minimumSize`` is, and using the same iPad design canvas. Where no candidate is larger on both axes the one with the largest area is used.
    var maximumSize: CGSize {
        WidgetFrame.extremes[self]?.maximum ?? .zero
    }
    
    /// Size for this widget on an iPhone with the specified screen size.
    ///
    /// Every size iPhone supports has a measured frame, so this returns nil only for a size iPhone does not support, such as `extraLarge`.
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
    /// > Note: the accessory sizes and the Lock Screen `small` frame return nil for the Home Screen target. They are not scaled and do not appear on the Home Screen, so the design canvas frame is the only one they have. See ``WidgetTarget``.
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

    /// Size for this widget on macOS or Mac Catalyst.
    ///
    /// > Note: measured on macOS 26 and applying from there. Earlier versions return nil, as does `extraLargePortrait`, which arrives in macOS 27 and could not be measured on a Mac running 26.
    /// - Parameter majorOSVersion: Major macOS version to look up frames for. Nil uses the version currently running.
    /// - Returns: Size for this widget. Nil if no frame is known.
    func sizeForMac(majorOSVersion: Int? = nil) -> CGSize? {
        Self.sizesForMac(majorOSVersion: majorOSVersion)[self]
    }

    /// Size for this widget on visionOS.
    ///
    /// > Note: `accessoryCircular` and `accessoryRectangular` arrive in visionOS 27, so they return nil for earlier versions. `accessoryInline` does not exist on visionOS at all.
    /// - Parameter majorOSVersion: Major visionOS version to look up frames for. Nil uses the version currently running.
    /// - Returns: Size for this widget. Nil if no frame is known, either because the platform does not support this widget size or because the frame has not been added to FrameUp yet.
    func sizeForVisionOS(majorOSVersion: Int? = nil) -> CGSize? {
        Self.sizesForVisionOS(majorOSVersion: majorOSVersion)[self]
    }
    
    /// Size for this widget on a watch with the specified screen size.
    ///
    /// > Note: `accessoryInline` returns nil; it reports a small square that never renders rather than a usable frame. A screen size that does not match a known Apple Watch resolves to the nearest one.
    /// - Parameter screenSize: Apple Watch screen size in points.
    /// - Parameter placement: Where the widget appears. Nil reports the Smart Stack frame for `accessoryRectangular` and the watch face frame for `accessoryCircular`, which is where each of them appears.
    /// - Returns: Size for this widget. Nil if no frame is known, either because the platform does not support this widget size or because the frame has not been added to FrameUp yet.
    func sizeForWatch(screenSize: CGSize, placement: WidgetPlacement? = nil) -> CGSize? {
        Self.sizesForWatch(screenSize: screenSize, placement: placement)[self]
    }
    
    /// Size for this widget on a watch of the specified case size.
    ///
    /// > Important: see ``sizesForWatch(watchSize:)``. A case size cannot distinguish the Ultra 2 from the Ultra 3.
    /// - Parameter watchSize: Apple Watch size in mm.
    /// - Returns: Size for this widget. Nil if no frame is known, either because the platform does not support this widget size or because the frame has not been added to FrameUp yet.
    func sizeForWatch(watchSize: CGFloat) -> CGSize? {
        Self.sizesForWatch(watchSize: watchSize)[self]
    }
    
    /// How much the widget is scaled down to fit on the Home Screen.
    ///
    /// Home Screen width divided by design canvas width
    /// - Parameter screenSize: iPad screen size ignoring orientation.
    /// - Parameter majorOSVersion: Major iPadOS version to look up frames for. Nil uses the version currently running. Needed for a size that arrives in a later version than the one running, such as `extraLargePortrait`.
    /// - Returns: Widget scale factor between design canvas and Home Screen. Nil if no iPad frame is known for this widget size.
    func scaleFactorForiPad(screenSize: CGSize, majorOSVersion: Int? = nil) -> CGFloat? {
        guard let homeScreen = sizeForiPad(screenSize: screenSize, target: .homeScreen, majorOSVersion: majorOSVersion),
              let designCanvas = sizeForiPad(screenSize: screenSize, target: .designCanvas, majorOSVersion: majorOSVersion)
        else { return nil }
        return homeScreen.width / designCanvas.width
    }
}
