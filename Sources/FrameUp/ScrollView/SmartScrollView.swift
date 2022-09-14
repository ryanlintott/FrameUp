//
//  SmartScrollView.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-09-24.
//

import SwiftUI

/// Settings used in `SmartScrollView`
public struct SmartScrollViewMeasurements: Equatable {
    /// State of scroll view dimensions
    public var state: SmartScrollViewState
    
    /// Edge insets based on the content frame and scroll view size.
    public var edgeInsets: EdgeInsets
}

extension SmartScrollViewMeasurements {
    static func edgeInsets(contentFrame: CGRect, scrollViewSize: CGSize) -> EdgeInsets {
        EdgeInsets(
            top: contentFrame.minY,
            leading: contentFrame.minX,
            bottom: scrollViewSize.height - contentFrame.maxY,
            trailing: scrollViewSize.width - contentFrame.maxX
        )
    }
    
    init(contentFrame: CGRect, scrollViewSize: CGSize) {
        state = SmartScrollViewState(content: contentFrame.size, scrollView: scrollViewSize)
        edgeInsets = Self.edgeInsets(contentFrame: contentFrame, scrollViewSize: scrollViewSize)
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

public struct SmartScrollViewState: Equatable {
    /// Content size
    let content: CGSize
    /// Scroll view size
    let scrollView: CGSize
    
    /// A recommended set axes for scrolling based on a the maximum frame size and content size.
    var recommendedAxes: Axis.Set {
        var axes = Axis.Set()
        if scrollView.height < content.height {
            axes.update(with: .vertical)
        }
        if scrollView.width < content.width {
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
    
    func resetStateTask() {
        Task {
            state = nil
        }
    }
    
    func updateValues(_ measurements: SmartScrollViewMeasurements?) {
        guard let measurements else {
            /// Settings have not been set or have for some unknown reason been set to nil
            if state != nil {
                resetStateTask()
            }
            return
        }
        
        let contentSize = measurements.state.content
        
        guard state?.content.equals(contentSize, precision: 0.01) ?? true else {
            /// Content size has changed so reset state.
            resetStateTask()
            return
        }
        
        let scrollViewSize = CGSize(
            width: min(measurements.state.scrollView.width, axes.contains(.vertical) || shrinkToFit ? contentSize.width : .infinity),
            height: min(measurements.state.scrollView.height, axes.contains(.horizontal) || shrinkToFit ? contentSize.height : .infinity)
        )
        
        guard let state else {
            /// State is nil so initialize state
            self.state = .init(content: contentSize, scrollView: scrollViewSize)
            return
        }
        
        guard state.scrollView.equals(scrollViewSize, precision: 0.01) else {
            /// Scroll view size has changed (it can only shrink) so update state.
            self.state = .init(content: contentSize, scrollView: scrollViewSize)
            return
        }
        
        /// State is stable so just update onScroll
        onScroll?(measurements.edgeInsets)
    }
    
    let randomNumber = Int.random(in: 0...1000)
    
    public var body: some View {
        GeometryReader { proxy in
            ScrollView(scrollViewAxes, showsIndicators: showsIndicators) {
                content
                    .anchorPreference(key: SmartScrollViewKey.self, value: .bounds) { anchor in
                        let contentFrame = proxy[anchor]
                        let scrollViewSize = proxy.size
                        return .init(contentFrame: contentFrame, scrollViewSize: scrollViewSize)
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
