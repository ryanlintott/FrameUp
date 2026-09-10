//
//  WidgetDemoFrame.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-11-23.
//

import SwiftUI

/// A frame used for presenting widgets with their correct device size inside an app.
///
/// For iPad, widget views use a design size and are scaled to a smaller Home Screen size using `ScaledView`. This demo frame uses the same scaling to properly preview the widget.
///
/// ``init(_:cornerRadius:content:)`` builds a frame only for a widget the current device can show, so a demo never presents a widget the device would never display. ``minimumSize(_:cornerRadius:content:)`` builds one for any size on any device, which is the way to preview `extraLarge` on an iPhone or a size that arrives in a later OS than the one running.
public struct WidgetDemoFrame<Content: View>: View {
    public typealias SizeAndCornerRadius = (CGSize, CGFloat) -> Content
    let cornerRadiusDefault: CGFloat = 20
    
    let widgetSize: WidgetSize
    let designCanvasSize: CGSize
    let homeScreenSize: CGSize
    let cornerRadius: CGFloat
    let content: SizeAndCornerRadius
    
    /// Creates a widget demo view with the design canvas frame size scaled to the Home Screen frame size and applies a corner radius.
    /// - Parameters:
    ///   - widgetSize: Size of widget to display
    ///   - designCanvasSize: Size used by content (can be larger than homeScreenSize)
    ///   - homeScreenSize: Size presented on home screen (content will scale down to fit inside this)
    ///   - cornerRadius: Size of the corner radius relative to homeScreenSize
    ///   - content: view with parameters for the designCanvasSize and designCornerRadius
    public init(widgetSize: WidgetSize, designCanvasSize: CGSize, homeScreenSize: CGSize, cornerRadius: CGFloat? = nil, content: @escaping SizeAndCornerRadius) {
        self.widgetSize = widgetSize
        self.designCanvasSize = designCanvasSize
        self.homeScreenSize = homeScreenSize
        self.cornerRadius = cornerRadius ?? cornerRadiusDefault
        self.content = content
    }
    
    var designCornerRadius: CGFloat {
        cornerRadius * (designCanvasSize.width / homeScreenSize.width)
    }
    
    var widgetShape: RoundedRectangle {
        switch widgetSize {
        case .accessoryCircular:
            return RoundedRectangle(cornerRadius: .infinity, style: .circular)
        case .accessoryInline:
            return RoundedRectangle(cornerRadius: 0, style: .continuous)
        default:
            return RoundedRectangle(cornerRadius: designCornerRadius, style: .continuous)
        }
    }
    
    public var body: some View {
        Group {
            if #available(iOS 15.0, macOS 12, watchOS 8, tvOS 15, *) {
                content(designCanvasSize, designCornerRadius)
                    .containerShape(widgetShape)
            } else {
                content(designCanvasSize, designCornerRadius)
            }
        }
        .clipShape(widgetShape)
        .contentShape(widgetShape)
        .frame(designCanvasSize)
        .scaledToFrame(homeScreenSize, contentMode: .fit)
    }
}

public extension WidgetDemoFrame {
    /// Creates a widget demo view for a specified widget size and corner radius for the current device.
    /// - Parameters:
    ///   - widgetSize: Size of widget (all sizes are supported regardless of iOS version or device type)
    ///   - cornerRadius: Size of the corner radius relative to homeScreenSize
    ///   - content: view with parameters for the designCanvasSize and designCornerRadius
    static func minimumSize(_ widgetSize: WidgetSize, cornerRadius: CGFloat? = nil, content: @escaping SizeAndCornerRadius) -> Self {
        self.init(
            widgetSize: widgetSize,
            designCanvasSize: widgetSize.minimumSize,
            homeScreenSize: widgetSize.minimumSize,
            cornerRadius: cornerRadius,
            content: content
        )
    }
}

/// tvOS has no widgets and so no current device to ask. It is the one platform with no `frameForCurrentDevice`, which is why this initialiser is unavailable there.
#if os(iOS) || os(macOS) || os(visionOS) || os(watchOS)
public extension WidgetDemoFrame {
    /// Creates a widget demo view for a specified widget size and corner radius for the current device.
    ///
    /// Only builds a frame for a widget the current platform and OS version can actually show, so a demo never presents a widget the device would never display. `extraLarge` on an iPhone, or `extraLargePortrait` before the version it arrives in, return nil rather than a frame borrowed from somewhere it does apply.
    ///
    /// Returns nil when the current device does not support this widget size, and when it does but no frame has been measured for it yet. Use ``minimumSize(_:cornerRadius:content:)`` to demo any size on any device regardless.
    /// - Parameters:
    ///   - widgetSize: Size of widget to display, which must be one the current device supports
    ///   - cornerRadius: Size of the corner radius relative to homeScreenSize
    ///   - content: view with parameters for the designCanvasSize and designCornerRadius
    init?(_ widgetSize: WidgetSize, cornerRadius: CGFloat? = nil, content: @escaping SizeAndCornerRadius) {
        guard WidgetSize.supportedSizesForCurrentDevice.contains(widgetSize),
              let frame = widgetSize.frameForCurrentDevice()
        else { return nil }

        self.init(
            widgetSize: widgetSize,
            designCanvasSize: frame.canvasSize,
            homeScreenSize: frame.renderedSize,
            cornerRadius: cornerRadius,
            content: content
        )
    }
}
#endif
