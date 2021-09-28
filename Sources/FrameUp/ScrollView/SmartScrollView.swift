//
//  SmartScrollView.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-09-24.
//

import SwiftUI

public struct SmartScrollViewSettings: Equatable {
    public var recommendedAxes: Axis.Set?
    public var contentSize: CGSize?

    public static var defaultValue: Self {
        SmartScrollViewSettings(recommendedAxes: nil, contentSize: nil)
    }
}

public struct SmartScrollViewKey: PreferenceKey {
    public typealias Value = SmartScrollViewSettings
    public static let defaultValue: SmartScrollViewSettings = .defaultValue
    public static func reduce(value: inout SmartScrollViewSettings, nextValue: () -> SmartScrollViewSettings) {
        value = nextValue()
    }
}

/// Do not use directly inside a NavigationView
public struct SmartScrollView<Content: View>: View {
    let axes: Axis.Set
    let showsIndicators: Bool
    let optionalScrolling: Bool
    let shrinkToFit: Bool
    @Binding var edgeInsets: EdgeInsets?
    let content: () -> Content
    
    @State private var recommendedAxes: Axis.Set? = nil
    @State private var contentSize: CGSize? = nil
    @State private var frameSize: CGSize? = nil
    
    var activeAxes: Axis.Set {
        guard optionalScrolling, let recommendedAxes = recommendedAxes else {
            return axes
        }
        return recommendedAxes.intersection(axes)
    }
    
    var maxWidth: CGFloat? {
        if axes.contains(.vertical) || shrinkToFit {
            return contentSize?.width
        }
        return nil
    }
    
    var maxHeight: CGFloat? {
        if axes.contains(.horizontal) || shrinkToFit {
            return contentSize?.height
        }
        return nil
    }
    
    public init(
        _ axes: Axis.Set = .vertical,
        showsIndicators: Bool = true,
        optionalScrolling: Bool = false,
        shrinkToFit: Bool = false,
        edgeInsets: Binding<EdgeInsets?> = .constant(nil),
        content: @escaping () -> Content)
    {
        self.axes = axes
        self.showsIndicators = showsIndicators
        self.optionalScrolling = optionalScrolling
        self.shrinkToFit = shrinkToFit
        self._edgeInsets = edgeInsets
        self.content = content
    }
    
    public var body: some View {
        GeometryReader { proxy in
            ScrollView(activeAxes, showsIndicators: showsIndicators) {
                content()
                    .anchorPreference(key: SmartScrollViewKey.self, value: .bounds) {
                        let contentSize = CGSize(width: proxy[$0].width, height: proxy[$0].height)
                        let frameSize = proxy.size
                        
                        var recommendedAxes: Axis.Set = []
                        if contentSize.height > frameSize.height && !recommendedAxes.contains(.vertical) {
                            recommendedAxes.update(with: .vertical)
                        }
                        
                        if contentSize.width > frameSize.width {
                            recommendedAxes.update(with: .horizontal)
                        }
                        
                        if shrinkToFit {
                            if let previousContentSize = self.contentSize {
                                if contentSize.height > previousContentSize.height || contentSize.width > previousContentSize.width {
                                    return SmartScrollViewSettings(recommendedAxes: recommendedAxes, contentSize: nil)
                                }
                            }
                        }
                        
                        return SmartScrollViewSettings(recommendedAxes: recommendedAxes, contentSize: contentSize)
                    }
                    .anchorPreference(key: EdgeInsetKey.self, value: .bounds) {
                        let rect = proxy[$0]
                        let top = rect.minY
                        let bottom = proxy.size.height - rect.maxY
                        let leading = rect.minX
                        let trailing = proxy.size.width - rect.maxX
                        return EdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing)
                    }
                    .fixedSize(horizontal: axes.contains(.horizontal), vertical: axes.contains(.vertical))
            }
        }
        .frame(maxWidth: maxWidth, maxHeight: maxHeight)
        .onPreferenceChange(EdgeInsetKey.self) { value in
            edgeInsets = value
        }
        .onPreferenceChange(SmartScrollViewKey.self) { value in
            recommendedAxes = value.recommendedAxes
            contentSize = value.contentSize
        }
        /// Debugging overlay
//        .overlay(
//            VStack(alignment: .trailing) {
//                Text("axes: \(axes.rawValue)")
//                Text("recommended: \(recommendedAxes?.rawValue ?? -1)")
//                Text("active: \(activeAxes.rawValue)")
//                Text("contentSize: \(contentSize?.width ?? -1)  \(contentSize?.height ?? -1)")
//            }
//                .background(Color.gray.opacity(0.5))
//                .allowsHitTesting(false)
//
//            , alignment: .bottomTrailing
//        )
    }
}
