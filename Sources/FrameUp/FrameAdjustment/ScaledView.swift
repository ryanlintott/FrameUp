//
//  ScaledView.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-11-22.
//

import SwiftUI

/// Used by `ScaledView`
public enum ScaleMode: String, CaseIterable {
    case shrink, grow, both
}

/// A view modifier that scales a view using `scaleEffect` to match a frame size.
///
/// View must have an intrinsic content size or be provided a specific frame size. Final frame size may be different depending on modes chosen.
/// Used in `scaleToFrame`
public struct ScaledView: ViewModifier {
    let frameSize: CGSize
    let contentMode: ContentMode?
    let scaleMode: ScaleMode
    
    /// Creates a view modifier that scales a view using `scaleEffect` to match a desired frame size
    ///
    /// Used in `WidgetDemoFrame`
    /// - Parameters:
    ///   - frameSize: A preferred frame size for the final view. Actual frame size may be different depending on modes chosen.
    ///   - contentMode: A flag that indicates whether this view fits, fills, or stretches to fit the parent context.
    ///   - scaleMode: A flag that indicates whether this view can grow, shrink, or both.
    init(_ frameSize: CGSize, contentMode: ContentMode? = nil, scaleMode: ScaleMode? = nil) {
        self.frameSize = frameSize
        self.contentMode = contentMode
        self.scaleMode = scaleMode ?? .both
    }
    
    @State private var contentSize: CGSize = .zero
    
    var scaleEffect: CGPoint {
        guard contentSize != .zero && contentSize != frameSize else {
            return CGPoint(x: 1, y: 1)
        }
        let x = clampScale(frameSize.width / contentSize.width)
        let y = clampScale(frameSize.height / contentSize.height)
        
        switch contentMode {
        case .fit:
            return CGPoint(x: min(x,y), y: min(x,y))
        case .fill:
            return CGPoint(x: max(x,y), y: max(x,y))
        case nil:
            return CGPoint(x: x, y: y)
        }
    }
    
    func clampScale(_ value: CGFloat) -> CGFloat {
        switch scaleMode {
        case .shrink:
            return min(value, 1)
        case .grow:
            return max(value, 1)
        case .both:
            return value
        }
    }
    
    var scaledSize: CGSize? {
        contentSize == .zero ? nil : CGSize(width: contentSize.width * scaleEffect.x, height: contentSize.height * scaleEffect.y)
    }
    
    public func body(content: Content) -> some View {
        content
            .onSizeChange { size in
                contentSize = size
            }
            .scaleEffect(x: scaleEffect.x, y: scaleEffect.y)
            .frame(scaledSize)
    }
}

public extension View {
    /// Scales this view using `scaleEffect` to match a desired frame size.
    ///
    /// View must have an intrinsic content size. Final frame size may be different depending on modes chosen.
    /// - Parameters:
    ///   - size: A preferred frame size for the final view.
    ///   - contentMode: A flag that indicates whether this view fits, fills, or stretches to fit the parent context.
    ///   - scaleMode: A flag that indicates whether this view can grow, shrink, or both.
    /// - Returns: A view scaled to match a preferred size.
    func scaledToFrame(_ size: CGSize, contentMode: ContentMode? = nil, scaleMode: ScaleMode? = nil) -> some View {
        self.modifier(ScaledView(size, contentMode: contentMode, scaleMode: scaleMode))
    }
    
    /// Scales this view using `scaleEffect` to match a desired width and height.
    ///
    /// View must have an intrinsic content size. Final frame size may be different depending on modes chosen.
    /// - Parameters:
    ///   - width: Preferred width.
    ///   - height: Preferred height.
    ///   - contentMode: A flag that indicates whether this view fits, fills, or stretches to fit the parent context.
    ///   - scaleMode: A flag that indicates whether this view can grow, shrink, or both.
    /// - Returns: A view scaled to match a preferred width and height.
    func scaledToFrame(width: CGFloat, height: CGFloat, contentMode: ContentMode? = nil, scaleMode: ScaleMode? = nil) -> some View {
        scaledToFrame(CGSize(width: width, height: height), contentMode: contentMode, scaleMode: scaleMode)
    }
    
    /// Scales this view using `scaleEffect` to fit a desired size.
    ///
    /// View must have an intrinsic content size. Final frame size may be different depending on modes chosen.
    /// - Parameters:
    ///   - size: A preferred frame size for the final view.
    ///   - scaleMode: A flag that indicates whether this view can grow, shrink, or both.
    /// - Returns: A view scaled to match a preferred size.
    func scaledToFit(_ size: CGSize, scaleMode: ScaleMode? = nil) -> some View {
        scaledToFrame(size, contentMode: .fit, scaleMode: scaleMode)
    }
    
    /// Scales this view using `scaleEffect` to fit a desired width and height.
    ///
    /// View must have an intrinsic content size. Final frame size may be different depending on modes chosen.
    /// - Parameters:
    ///   - width: Preferred width.
    ///   - height: Preferred height.
    ///   - scaleMode: A flag that indicates whether this view can grow, shrink, or both.
    /// - Returns: A view scaled to match a preferred width and height.
    func scaledToFit(width: CGFloat, height: CGFloat, scaleMode: ScaleMode? = nil) -> some View {
        scaledToFrame(width: width, height: height, contentMode: .fit, scaleMode: scaleMode)
    }
    
    /// Scales this view using `scaleEffect` to fill a desired size.
    ///
    /// View must have an intrinsic content size. Final frame size may be different depending on modes chosen.
    /// - Parameters:
    ///   - size: A preferred frame size for the final view.
    ///   - scaleMode: A flag that indicates whether this view can grow, shrink, or both.
    /// - Returns: A view scaled to match a preferred size.
    func scaledToFill(_ size: CGSize, scaleMode: ScaleMode? = nil) -> some View {
        scaledToFrame(size, contentMode: .fill, scaleMode: scaleMode)
    }
    
    /// Scales this view using `scaleEffect` to fill a desired width and height.
    ///
    /// View must have an intrinsic content size or be provided a specific frame size. Final frame size may be different depending on modes chosen.
    /// - Parameters:
    ///   - width: Preferred width.
    ///   - height: Preferred height.
    ///   - scaleMode: A flag that indicates whether this view can grow, shrink, or both.
    /// - Returns: A view scaled to match a preferred width and height.
    func scaledToFill(width: CGFloat, height: CGFloat, scaleMode: ScaleMode? = nil) -> some View {
        scaledToFrame(width: width, height: height, contentMode: .fill, scaleMode: scaleMode)
    }
    
    /// Scales this view using `scaleEffect` to fit a desired width.
    ///
    /// View must have an intrinsic content size. Final frame size may be different depending on modes chosen.
    /// - Parameters:
    ///   - width: Preferred width.
    ///   - scaleMode: A flag that indicates whether this view can grow, shrink, or both.
    /// - Returns: A view scaled to match a preferred width.
    func scaledToFit(width: CGFloat, scaleMode: ScaleMode? = nil) -> some View {
        scaledToFit(width: width, height: .infinity, scaleMode: scaleMode)
    }
    
    /// Scales this view using `scaleEffect` to fit a desired height.
    ///
    /// View must have an intrinsic content size. Final frame size may be different depending on modes chosen.
    /// - Parameters:
    ///   - height: Preferred height.
    ///   - scaleMode: A flag that indicates whether this view can grow, shrink, or both.
    /// - Returns: A view scaled to match a preferred height.
    func scaledToFit(height: CGFloat, scaleMode: ScaleMode? = nil) -> some View {
        scaledToFit(width: .infinity, height: height, scaleMode: scaleMode)
    }
}
