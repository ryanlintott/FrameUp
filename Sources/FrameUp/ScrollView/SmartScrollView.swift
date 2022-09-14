//
//  SmartScrollView.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-09-24.
//

import SwiftUI

/// Settings used in `SmartScrollView`
public struct SmartScrollViewMeasurements: Equatable {
    /// ScrollviewFrame
    public var scrollViewSize: CGSize
    /// Frame of content insize scrollview.
    public var contentFrame: CGRect
    
    /// Edge insets based on the content frame and scroll view size.
    var edgeInsets: EdgeInsets {
        EdgeInsets(
            top: contentFrame.minY,
            leading: contentFrame.minX,
            bottom: scrollViewSize.height - contentFrame.maxY,
            trailing: scrollViewSize.width - contentFrame.maxX
        )
    }
}

/// A PreferenceKey used to pass SmartScrollViewSettings up the view hierarchy
public struct SmartScrollViewKey: PreferenceKey {
    public typealias Value = SmartScrollViewMeasurements?
    public static let defaultValue: SmartScrollViewMeasurements? = nil
    public static func reduce(value: inout SmartScrollViewMeasurements?, nextValue: () -> SmartScrollViewMeasurements?) {
        value = nextValue()
    }
}

public struct SmartScrollViewState {
    /// Maximum frame size
    let max: CGSize
    /// Content size
    let content: CGSize
    /// Scroll view size
    let scrollView: CGSize
    
    /// A recommended set axes for scrolling based on a the maximum frame size and content size.
    var recommendedAxes: Axis.Set {
        var axes = Axis.Set()
        if max.height < content.height {
            axes.update(with: .vertical)
        }
        if max.width < content.width {
            axes.update(with: .horizontal)
        }
        return axes
    }
}

/**
 A ScrollView with optional scrolling, a frame that can shrink to fit the content, and a way to know when the view has been scrolled and track edge insets.
 
 If the content or frame change size, it may update its size and scroll to the top.
 
 Limitations:
 - If placed directly inside a NavigationView with a resizing header, this view may behave strangely when scrolling. To avoid this add 1 point of padding to the top of this view.
 - If the available space for this view grows for any reason other than screen rotation, this view will not grow to fill the space. If you know the value that causes this change, add an `.id(value)` modifier below this view to trigger the view to recalculate. This will cause it to scroll to the top.
*/
public struct SmartScrollView<Content: View>: View {
    /// The scroll view’s scrollable axis. The default axis is the vertical axis.
    let axes: Axis.Set
    /// A Boolean value that indicates whether the scroll view displays the scrollable component of the content offset, in a way suitable for the platform. The default value for this parameter is true.
    let showsIndicators: Bool
    /// A Boolean value that indicates whether scrolling should be disabled if the content fits the available space. The default value is false.
    let optionalScrolling: Bool
    /// A Boolean value that indicates whether the outer frame should shrink to fit the content. The default value is false.
    let shrinkToFit: Bool
    let content: Content
    let onScroll: ((EdgeInsets?) -> Void)?
    
    /// Creates a ScrollView with several smart options
    /// - Parameters:
    ///   - axes: The scroll view’s scrollable axis. The default axis is the vertical axis.
    ///   - showsIndicators: A Boolean value that indicates whether the scroll view displays the scrollable component of the content offset, in a way suitable for the platform. The default value for this parameter is true.
    ///   - optionalScrolling: A Boolean value that indicates whether scrolling should be disabled if the content fits the available space. The default value is true.
    ///   - shrinkToFit: A Boolean value that indicates whether the outer frame should shrink to fit the content. The default value is true.
    ///   - content: The view builder that creates the scrollable view.
    ///   - onScroll: An action that will be run when the view has been scrolled. Edge insets are passed as a parameter.
    public init(
        _ axes: Axis.Set = .vertical,
        showsIndicators: Bool = true,
        optionalScrolling: Bool = true,
        shrinkToFit: Bool = true,
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
    
    /// Sizes required for displaying scrollview
    @State private var state: SmartScrollViewState? = nil
    
    /// Axes that will be used on ScrollView
    var scrollViewAxes: Axis.Set {
        guard optionalScrolling else { return axes }
        return state?.recommendedAxes.intersection(axes) ?? []
    }
    
    func updateValues(_ settings: SmartScrollViewMeasurements?) {
        guard let settings else {
            /// Settings have not been set or have for some unknown reason been set to nil
            if state != nil {
                Task {
                    state = nil
                }
            }
            return
        }
        
        guard let state else {
            /// The state is unknown so define a new state.
            let maxSize = settings.scrollViewSize
            let contentSize = settings.contentFrame.size
            let scrollViewSize = CGSize(
                width: min(maxSize.width, axes.contains(.vertical) || shrinkToFit ? contentSize.width : .infinity),
                height: min(maxSize.height, axes.contains(.horizontal) || shrinkToFit ? contentSize.height : .infinity)
            )
            self.state = .init(max: maxSize, content: contentSize, scrollView: scrollViewSize)
            return
        }
        
        guard state.content.equals(settings.contentFrame.size, precision: 0.01),
           state.scrollView.equals(settings.scrollViewSize, precision: 0.01) else {
            /// Sizes have changed so reset state.
            Task {
                self.state = nil
            }
            return
        }
        
        /// State is stable so just update onScroll
        onScroll?(settings.edgeInsets)
    }
    
    let randomNumber = Int.random(in: 0...1000)
    
    public var body: some View {
        GeometryReader { proxy in
            ScrollView(scrollViewAxes, showsIndicators: showsIndicators) {
                content
                    .anchorPreference(key: SmartScrollViewKey.self, value: .bounds) { anchor in
                        let scrollViewSize = proxy.size
                        let contentFrame = proxy[anchor]
                        return SmartScrollViewMeasurements(scrollViewSize: scrollViewSize, contentFrame: contentFrame)
                    }
                    .fixedSize(horizontal: axes.contains(.horizontal), vertical: axes.contains(.vertical))
            }
        }
        /// A frame that's able to shrink the scroll view is applied only when the state is known.
        .frame(maxWidth: state?.scrollView.width, maxHeight: state?.scrollView.height)
        /// Hide everything when the state is unknown.
        .opacity(state == nil ? 0 : 1)
        /// When measurements change, update values.
        .onPreferenceChange(SmartScrollViewKey.self, perform: updateValues)
        /// If any parameters change, reset the state.
        .onChange(of: axes) { newValue in
            if newValue != axes {
                state = nil
            }
        }
        .onChange(of: optionalScrolling) { newValue in
            if newValue != optionalScrolling {
                state = nil
            }
        }
        .onChange(of: shrinkToFit) { newValue in
            if newValue != shrinkToFit {
                state = nil
            }
        }
        /// If the screen rotates or the app returns from the background, reset the state
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            if let deviceOrientation = UIDevice.current.orientation.interfaceOrientation, InfoDictionary.supportedInterfaceOrientations.contains(deviceOrientation) {
                ///
                state = nil
            }
        }
        /// Debugging overlay
//        .overlay(
//            VStack(alignment: .trailing) {
//                Text("axes: \(axes.rawValue)")
//                Text("active: \(scrollViewAxes.rawValue)")
//                Text("contentSize: \(contentSize?.width ?? -1)  \(contentSize?.height ?? -1)")
//            }
//                .background(Color.gray.opacity(0.5))
//                .allowsHitTesting(false)
//
//            , alignment: .bottomTrailing
//        )
    }
}

struct SmartScrollView_Previews: PreviewProvider {
    static var previews: some View {
        SmartScrollView([.vertical], optionalScrolling: false, shrinkToFit: false) {
            Text("Hello")
//                .frame(height: 1000)
                .background(Color.blue)
                .fixedSize(horizontal: false, vertical: true)
        }
        .background(Color.red)
    }
}
