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
    public var edgeInsets: EdgeInsets?

    public static var defaultValue: Self {
        SmartScrollViewSettings(recommendedAxes: nil, contentSize: nil, edgeInsets: nil)
    }
}

public struct SmartScrollViewKey: PreferenceKey {
    public typealias Value = SmartScrollViewSettings
    public static let defaultValue: SmartScrollViewSettings = .defaultValue
    public static func reduce(value: inout SmartScrollViewSettings, nextValue: () -> SmartScrollViewSettings) {
        value = nextValue()
    }
}

public struct EdgeInsetKey: PreferenceKey {
    public static var defaultValue: EdgeInsets? = nil
    public static func reduce(value: inout EdgeInsets?, nextValue: () -> EdgeInsets?) {
        value = nextValue()
    }
}

public struct SmartScrollView<Content: View>: View {
    let axes: Axis.Set
    let showsIndicators: Bool
    let optionalScrolling: Bool
    let shrinkToFit: Bool
    let content: () -> Content
    let onScroll: ((EdgeInsets?) -> Void)?
    
    @State private var recommendedAxes: Axis.Set? = nil
    @State private var contentSize: CGSize? = nil
    
    var activeAxes: Axis.Set {
        recommendedAxes?.intersection(axes) ?? axes
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
        content: @escaping () -> Content,
        onScroll: ((EdgeInsets?) -> Void)? = nil
    ) {
        self.axes = axes
        self.showsIndicators = showsIndicators
        self.optionalScrolling = optionalScrolling
        self.shrinkToFit = shrinkToFit
        self.content = content
        self.onScroll = onScroll
    }
    
    public var body: some View {
        GeometryReader { proxy in
            ScrollView(activeAxes, showsIndicators: showsIndicators) {
                content()
                    .anchorPreference(key: SmartScrollViewKey.self, value: .bounds) {
                        var recommendedAxes: Axis.Set = []
                        let rect = proxy[$0]
                        let contentSize = rect.size
                        var edgeInsets = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
                        let frameSize = proxy.size
                        
                        if activeAxes.contains(.vertical) {
                            edgeInsets.top = rect.minY
                            edgeInsets.bottom = frameSize.height - rect.maxY
                        }
                        if activeAxes.contains(.horizontal) {
                            edgeInsets.leading = rect.minX
                            edgeInsets.trailing = frameSize.width - rect.maxX
                        }
                        
                        if optionalScrolling {
                            if contentSize.height > frameSize.height && !recommendedAxes.contains(.vertical) {
                                recommendedAxes.update(with: .vertical)
                            }
                            
                            if contentSize.width > frameSize.width {
                                recommendedAxes.update(with: .horizontal)
                            }
                        }
                        
                        if shrinkToFit, let previousContentSize = self.contentSize {
                            if contentSize.height > previousContentSize.height || contentSize.width > previousContentSize.width {
                                /// set contentsize to nil as content may grow vertically when it really needs to grow horizontally but can't
                                return SmartScrollViewSettings(recommendedAxes: recommendedAxes, contentSize: nil, edgeInsets: edgeInsets)
                            }
                        }
                        
                        return SmartScrollViewSettings(recommendedAxes: recommendedAxes, contentSize: contentSize, edgeInsets: edgeInsets)
                    }
                    .fixedSize(horizontal: axes.contains(.horizontal), vertical: axes.contains(.vertical))
            }
        }
        .frame(maxWidth: maxWidth, maxHeight: maxHeight)
        .onPreferenceChange(SmartScrollViewKey.self) { value in
            onScroll?(value.edgeInsets)
            
            if (optionalScrolling && recommendedAxes != value.recommendedAxes) || contentSize != value.contentSize {
                DispatchQueue.main.async {
                    contentSize = value.contentSize
                    recommendedAxes = value.recommendedAxes
                }
            }
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
