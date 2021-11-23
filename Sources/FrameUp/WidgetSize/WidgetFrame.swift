//
//  WidgetFrame.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2021-11-23.
//

import WidgetKit
import SwiftUI

/// Use at the top level of a Widget View
/// Rescales the content inside in order to fix an issue with ContainerRelativeShape where the corner radius doesn't match.
/// Scale factor is calculated by homeScreenSize / designFrameSize for the current device
@available(iOS, unavailable)
@available(iOSApplicationExtension 14.0, *)
public struct WidgetFrame<Content: View>: View {
    @Environment(\.widgetFamily) var widgetFamily
    let content: () -> Content
    
    public init(content: @escaping () -> Content) {
        self.content = content
    }
    
    var scaleFactor: CGFloat {
        widgetFamily.size?.scaleFactorForCurrentDevice ?? 1
    }
    
    public var body: some View {
        GeometryReader { proxy in
            content()
                .frame(width: proxy.size.width * scaleFactor, height: proxy.size.height * scaleFactor)
                .scaleEffect(1 / scaleFactor, anchor: .topLeading)
        }
    }
}
