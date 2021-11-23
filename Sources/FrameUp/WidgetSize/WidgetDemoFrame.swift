//
//  WidgetDemoFrame.swift
//  
//
//  Created by Ryan Lintott on 2021-11-23.
//

import SwiftUI

/// Used for presenting widgets with their correct device size within an iOS app.
public struct WidgetDemoFrame<Content: View>: View {
    public typealias SizeAndCornerRadius = (CGSize, CGFloat) -> Content
    let cornerRadiusDefault: CGFloat = 20
    
    let designCanvasSize: CGSize
    let homeScreenSize: CGSize
    let cornerRadius: CGFloat
    let content: SizeAndCornerRadius
    
    /// Provide custom values
    /// - Parameters:
    ///   - designCanvasSize: Size used by content (can be larger than homeScreenSize)
    ///   - homeScreenSize: Size presented on home screen (content will scale down to fit inside this)
    ///   - cornerRadius: Relative to homeScreenSize
    ///   - content: view
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
    /// Use widgetSize to determine designCanvasSize and homeScreenSize for the current device
    /// - Parameters:
    ///   - widgetSize: All sizes will work on all devices (even extraLarge on iPhone)
    ///   - cornerRadius: relative to homeScreenSize
    ///   - content: view
    init(_ widgetSize: WidgetSize, cornerRadius: CGFloat? = nil, content: @escaping SizeAndCornerRadius) {
        self.init(
            designCanvasSize: widgetSize.sizeForCurrentDevice(iPadTarget: .designCanvas),
            homeScreenSize: widgetSize.sizeForCurrentDevice(iPadTarget: .homeScreen),
            cornerRadius: cornerRadius,
            content: content
        )
    }
}
