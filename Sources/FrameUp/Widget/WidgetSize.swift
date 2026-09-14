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
/// - ``frame(platform:screenSize:majorOSVersion:displayScale:placement:)`` answers what frame that widget gets, and returns nil when no measurement has been added to FrameUp yet.
///
/// A size can therefore be supported and still have no frame. Sizes that are supported but have no frame yet:
///
/// | Platform | Unknown Frame Sizes |
/// | --- | --- |
/// | iPhone | none |
/// | iPad | none |
/// | macOS, Mac Catalyst | none from macOS 26. Earlier than macOS 26 no size has a frame, since Apple publishes none and iOS frames are known to have changed at 26. |
/// | visionOS | none |
/// | Apple Watch | `accessoryInline`, which reports a small square that never renders rather than a usable frame, and `accessoryCorner`, whose reported size does not bound what it draws. `accessoryCircular` has a watch face frame but none in the Smart Stack, where it does not appear. |
/// | CarPlay | every size |
///
/// Frames are also known for two of the places a widget can appear, the Home Screen and the Lock Screen, and for the Apple Watch Smart Stack. The other ``WidgetPlacement`` cases have no frames: StandBy and CarPlay cannot be reached in a simulator, and the rest have not been measured.
///
/// ``minimumSize`` and ``maximumSize`` return a value for every case that has a frame somewhere, so they are a useful fallback when no device frame is known. ``accessoryCorner`` is the exception and returns zero, because no frame is stored for it on any platform.
public enum WidgetSize: String, Identifiable, CaseIterable, Sendable {
    case small
    case medium
    case large
    case extraLarge
    case extraLargePortrait
    case accessoryCircular
    case accessoryRectangular
    case accessoryInline
    /// A complication in a corner of an Apple Watch face. Apple Watch only, and the only widget size that appears on no other platform.
    ///
    /// It has no frame. A corner complication is roughly triangular rather than rectangular, and a label can curve around its frame and extend past it, so the size WidgetKit reports does not bound what the complication draws. ``minimumSize`` and ``maximumSize`` return zero for it.
    case accessoryCorner
    
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

/// The two frames that may be required for presenting an accurate widget frame.
///
/// Every platform lays a widget out on a design canvas. iPad widgets are then scaled down to present on the Home Screen or Lock Screen in a smaller rendered frame.
///
/// ``WidgetFrame`` reports both sizes at once, so this is only needed by the deprecated lookups that made the caller pick one.
///
/// The scaling is a Home Screen and Today View behaviour, not something iPad does to every widget. A widget on the iPad Lock Screen is drawn at its design canvas size: placing the probe there and measuring the pixels gives 63x63, 152x63 and 152x152 on a 820x1180 iPad, exactly the canvas values, where the Home Screen scale factor would have produced fractional pixels.
public enum WidgetTarget: Sendable {
    /// The frame used for laying out widget content in points
    case designCanvas
    /// The size the canvas is scaled to for presentation on the Home Screen or Today View
    case homeScreen
}
