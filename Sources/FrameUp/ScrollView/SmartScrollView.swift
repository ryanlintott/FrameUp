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
    
    @State private var contentSize: CGSize? = nil
    @State private var recommendedAxes: Axis.Set? = nil
    
    var activeAxes: Axis.Set {
        guard optionalScrolling else {
            return axes
        }
        return recommendedAxes?.intersection(axes) ?? axes
    }
    
    var maxWidth: CGFloat? {
        if axes.contains(.vertical) || shrinkToFit {
            if recommendedAxes?.contains(.horizontal) == false {
                return contentSize?.width
            }
        }
        return nil
    }
    
    var maxHeight: CGFloat? {
        if axes.contains(.horizontal) || shrinkToFit {
            if recommendedAxes?.contains(.vertical) == false {
                return contentSize?.height
            }
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
//                    .anchorPreference(key: EdgeInsetKey.self, value: .bounds) {
//                        let rect = proxy[$0]
//                        let top = rect.minY
//                        let bottom = proxy.size.height - rect.maxY
//                        let leading = rect.minX
//                        let trailing = proxy.size.width - rect.maxX
//                        return EdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing)
//                    }
                    .anchorPreference(key: SmartScrollViewKey.self, value: .bounds) {
//                        let size = CGSize(width: min(proxy.size.width, proxy[$0].width), height: min(proxy.size.height, proxy[$0].height))
                        
                        let contentSize = CGSize(width: proxy[$0].width, height: proxy[$0].height)
                        let frameSize = proxy.size
                        
                        var recommendedAxes: Axis.Set = []
                        switch (axes, self.recommendedAxes) {
                        case (.vertical, []):
                            if contentSize.height > frameSize.height {
                                recommendedAxes = [.vertical, .horizontal]
                            }
                        case (.vertical, .vertical):
                            if contentSize.height > frameSize.height && contentSize.width <= frameSize.width {
                                recommendedAxes = .vertical
                            }
                        case (.vertical, [.vertical, .horizontal]):
                            if contentSize.height > frameSize.height {
                                recommendedAxes.update(with: .vertical)
                            }
                            
                        }
                        
                        if contentSize.height > frameSize.height || contentSize.width > frameSize.width {
                            recommendedAxes = [.vertical, .horizontal]
                        }
                        if contentSize.width < frameSize.width {
                            recommendedAxes.remove(.horizontal)
                        }
                        if contentSize.height < frameSize.height {
                            recommendedAxes.remove(.vertical)
                        }
                        
//                        if axes == .vertical && recommendedAxes {
//                            recommendedAxes.remove(.horizontal)
//                        }
//                        if contentSize.width > frameSize.width {
//                            recommendedAxes.update(with: .horizontal)
//                        }
                        
                        return SmartScrollViewSettings(recommendedAxes: recommendedAxes, contentSize: contentSize)
                    }
                    .fixedSize(horizontal: axes.contains(.horizontal), vertical: axes.contains(.vertical))
            }
            .background(Color.red.opacity(0.5))
//            .anchorPreference(key: SizeKey.self, value: .bounds) {
//                proxy[$0].size
//            }
        }
//        .frame(width: width, height: height)
        .frame(maxWidth: maxWidth, maxHeight: maxHeight)
//        .onPreferenceChange(EdgeInsetKey.self) { value in
//            edgeInsets = value
//        }
        .onPreferenceChange(SmartScrollViewKey.self) { value in
            recommendedAxes = value.recommendedAxes
            contentSize = value.contentSize
        }
    }
}
