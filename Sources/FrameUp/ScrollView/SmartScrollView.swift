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
                        let contentSize = CGSize(width: proxy[$0].width, height: proxy[$0].height)
                        
                        if optionalScrolling {
                            let frameSize = proxy.size
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
                                return SmartScrollViewSettings(recommendedAxes: recommendedAxes, contentSize: nil)
                            }
                        }
                        
                        return SmartScrollViewSettings(recommendedAxes: recommendedAxes, contentSize: contentSize)
                    }
                    .anchorPreference(key: EdgeInsetKey.self, value: .bounds) {
                        let rect = proxy[$0]
                        var edgeInsets = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
                        if activeAxes.contains(.vertical) {
                            edgeInsets.top = rect.minY
                            edgeInsets.bottom = proxy.size.height - rect.maxY
                        }
                        if activeAxes.contains(.horizontal) {
                            edgeInsets.leading = rect.minX
                            edgeInsets.trailing = proxy.size.width - rect.maxX
                        }
                        return edgeInsets
                    }
                    .fixedSize(horizontal: axes.contains(.horizontal), vertical: axes.contains(.vertical))
            }
        }
        .frame(maxWidth: maxWidth, maxHeight: maxHeight)
        .onPreferenceChange(EdgeInsetKey.self) { value in
            onScroll?(value)
        }
        .onPreferenceChange(SmartScrollViewKey.self) { value in
            if optionalScrolling && recommendedAxes != value.recommendedAxes {
                recommendedAxes = value.recommendedAxes
            }
            if contentSize != value.contentSize {
                contentSize = value.contentSize
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
