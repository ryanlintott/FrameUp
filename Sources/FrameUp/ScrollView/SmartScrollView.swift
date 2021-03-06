//
//  SmartScrollView.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-09-24.
//

import SwiftUI

/// Settings used in `SmartScrollView`
public struct SmartScrollViewSettings: Equatable {
    /// Axes where content is larger than available space and scrolling is recommended.
    public var recommendedAxes: Axis.Set?
    /// Size of the content.
    public var contentSize: CGSize?
    /// Insets from the scroll view edge to the content edge. Insets are negative when content edges are beyond the scroll view edges.
    public var edgeInsets: EdgeInsets?

    public static var defaultValue: Self {
        SmartScrollViewSettings(recommendedAxes: nil, contentSize: nil, edgeInsets: nil)
    }
}

/// A PreferenceKey used to pass SmartScrollViewSettings up the view hierarchy
public struct SmartScrollViewKey: PreferenceKey {
    public typealias Value = SmartScrollViewSettings
    public static let defaultValue: SmartScrollViewSettings = .defaultValue
    public static func reduce(value: inout SmartScrollViewSettings, nextValue: () -> SmartScrollViewSettings) {
        value = nextValue()
    }
}

/// A ScrollView with optional scrolling, a frame that can shrink to fit the content, and a way to track edge insets as the view is scrolled.
public struct SmartScrollView<Content: View>: View {
    let axes: Axis.Set
    let showsIndicators: Bool
    let optionalScrolling: Bool
    let shrinkToFit: Bool
    let content: Content
    let onScroll: ((EdgeInsets?) -> Void)?
    
    @State private var recommendedAxes: Axis.Set? = nil
    @State private var contentSize: CGSize? = nil
    
    var activeAxes: Axis.Set {
        guard optionalScrolling else {
            return axes
        }
        return recommendedAxes?.intersection(axes) ?? axes
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
    
    /// Creates a ScrollView with several smart options
    /// - Parameters:
    ///   - axes: The scroll view???s scrollable axis. The default axis is the vertical axis.
    ///   - showsIndicators: A Boolean value that indicates whether the scroll view displays the scrollable component of the content offset, in a way suitable for the platform. The default value for this parameter is true.
    ///   - optionalScrolling: A Boolean value that indicates whether scrolling should be disabled if the content fits the available space. The default value is false.
    ///   - shrinkToFit: A Boolean value that indicates whether the outer frame should shrink to fit the content. The default value is false.
    ///   - content: The view builder that creates the scrollable view.
    ///   - onScroll: An action that will be run when the view has been scrolled. Edge insets are passed as a parameter.
    public init(
        _ axes: Axis.Set = .vertical,
        showsIndicators: Bool = true,
        optionalScrolling: Bool = false,
        shrinkToFit: Bool = false,
        content: () -> Content,
        onScroll: ((EdgeInsets?) -> Void)? = nil
    ) {
        self.axes = axes
        self.showsIndicators = showsIndicators
        self.optionalScrolling = optionalScrolling
        self.shrinkToFit = shrinkToFit
        self.content = content()
        self.onScroll = onScroll
    }
    
    public var body: some View {
        GeometryReader { proxy in
            ScrollView(activeAxes, showsIndicators: showsIndicators) {
                content
                    .anchorPreference(key: SmartScrollViewKey.self, value: .bounds) {
                        let rect = proxy[$0]
                        var newRecommendedAxes: Axis.Set = []
                        let newContentSize = rect.size
                        let frameSize = proxy.size
                        
                        if optionalScrolling {
                            if newContentSize.height > frameSize.height && !newRecommendedAxes.contains(.vertical) {
                                newRecommendedAxes.update(with: .vertical)
                            }
                            
                            if newContentSize.width > frameSize.width {
                                newRecommendedAxes.update(with: .horizontal)
                            }
                        }
                        
                        var newEdgeInsets = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
                        if activeAxes.contains(.vertical) && (!optionalScrolling || newRecommendedAxes.contains(.vertical)) {
                            newEdgeInsets.top = rect.minY
                            newEdgeInsets.bottom = frameSize.height - rect.maxY
                        }
                        
                        if activeAxes.contains(.horizontal) && (!optionalScrolling || newRecommendedAxes.contains(.horizontal)) {
                            newEdgeInsets.leading = rect.minX
                            newEdgeInsets.trailing = frameSize.width - rect.maxX
                        }
                        
                        if let contentSize = self.contentSize {
                            let heightReset = (axes.contains(.horizontal) || shrinkToFit) && newContentSize.height > contentSize.height
                            let widthReset = (axes.contains(.vertical) || shrinkToFit) && newContentSize.width > contentSize.width
                            
                            if heightReset || widthReset {
                                return SmartScrollViewSettings(recommendedAxes: newRecommendedAxes, contentSize: nil, edgeInsets: newEdgeInsets)
                            }
                        }
                        
                        return SmartScrollViewSettings(recommendedAxes: newRecommendedAxes, contentSize: newContentSize, edgeInsets: newEdgeInsets)
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
