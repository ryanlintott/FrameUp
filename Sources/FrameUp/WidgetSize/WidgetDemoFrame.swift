//
//  WidgetDemoFrame.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-11-23.
//

import SwiftUI

/// A frame used for presenting widgets with their correct device size within an iOS app.
///
/// For iPad, widget views use a design size and are scaled to a smaller Home Screen size. This demo frame using the same scaling to properly preview the widget. All sizes will work on all devices and all versions of iOS (even extraLarge on iPhone with iOS 14.0).
public struct WidgetDemoFrame<Content: View>: View {
    public typealias SizeAndCornerRadius = (CGSize, CGFloat) -> Content
    let cornerRadiusDefault: CGFloat = 20
    
    let designCanvasSize: CGSize
    let homeScreenSize: CGSize
    let cornerRadius: CGFloat
    let content: SizeAndCornerRadius
    
    /// Creates a widget demo view with the design canvas frame size scaled to the Home Screen frame size and applies a corner radius.
    /// - Parameters:
    ///   - designCanvasSize: Size used by content (can be larger than homeScreenSize)
    ///   - homeScreenSize: Size presented on home screen (content will scale down to fit inside this)
    ///   - cornerRadius: Size of the corner radius relative to homeScreenSize
    ///   - content: view with parameters for the designCanvasSize and designCornerRadius
    public init(designCanvasSize: CGSize, homeScreenSize: CGSize, cornerRadius: CGFloat? = nil, content: @escaping SizeAndCornerRadius) {
        self.designCanvasSize = designCanvasSize
        self.homeScreenSize = homeScreenSize
        self.cornerRadius = cornerRadius ?? cornerRadiusDefault
        self.content = content
    }
    
    var designCornerRadius: CGFloat {
        cornerRadius * (designCanvasSize.width / homeScreenSize.width)
    }
    
    var widgetShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: designCornerRadius, style: .continuous)
    }
    
    public var body: some View {
        Group {
            if #available(iOS 15.0, *) {
                content(designCanvasSize, designCornerRadius)
                    .containerShape(widgetShape)
            } else {
                content(designCanvasSize, designCornerRadius)
            }
        }
        .clipShape(widgetShape)
        .contentShape(widgetShape)
        .frame(designCanvasSize)
        .scaledToFrame(homeScreenSize, contentMode: .fit)    }
}

public extension WidgetDemoFrame {
    /// Creates a widget demo view for a specified widget size and corner radius for the current device.
    /// - Parameters:
    ///   - widgetSize: Size of widget (all sizes are supported regardless of iOS version or device type)
    ///   - cornerRadius: Size of the corner radius relative to homeScreenSize
    ///   - content: view with parameters for the designCanvasSize and designCornerRadius
    init(_ widgetSize: WidgetSize, cornerRadius: CGFloat? = nil, content: @escaping SizeAndCornerRadius) {
        self.init(
            designCanvasSize: widgetSize.sizeForCurrentDevice(iPadTarget: .designCanvas),
            homeScreenSize: widgetSize.sizeForCurrentDevice(iPadTarget: .homeScreen),
            cornerRadius: cornerRadius,
            content: content
        )
    }
}
