//
//  ScaledView.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2021-11-22.
//

import SwiftUI

public enum ScaleMode: String, CaseIterable {
    case shrink, grow, both
}

public struct ScaledView: ViewModifier {
    let frameSize: CGSize
    let contentMode: ContentMode?
    let scaleMode: ScaleMode
    
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
    func scaledToFrame(_ size: CGSize, contentMode: ContentMode? = nil, scaleMode: ScaleMode? = nil) -> some View {
        self.modifier(ScaledView(size, contentMode: contentMode, scaleMode: scaleMode))
    }
    
    func scaledToFrame(width: CGFloat, height: CGFloat, contentMode: ContentMode? = nil, scaleMode: ScaleMode? = nil) -> some View {
        scaledToFrame(CGSize(width: width, height: height), contentMode: contentMode, scaleMode: scaleMode)
    }
    
    func scaledToFit(_ size: CGSize, scaleMode: ScaleMode? = nil) -> some View {
        scaledToFrame(size, contentMode: .fit, scaleMode: scaleMode)
    }
    
    func scaledToFit(width: CGFloat, height: CGFloat, scaleMode: ScaleMode? = nil) -> some View {
        scaledToFrame(width: width, height: height, contentMode: .fit, scaleMode: scaleMode)
    }
    
    func scaledToFill(_ size: CGSize, scaleMode: ScaleMode? = nil) -> some View {
        scaledToFrame(size, contentMode: .fill, scaleMode: scaleMode)
    }
    
    func scaledToFill(width: CGFloat, height: CGFloat, scaleMode: ScaleMode? = nil) -> some View {
        scaledToFrame(width: width, height: height, contentMode: .fill, scaleMode: scaleMode)
    }
    
    func scaledToFit(width: CGFloat, scaleMode: ScaleMode? = nil) -> some View {
        scaledToFit(width: width, height: .infinity, scaleMode: scaleMode)
    }
    
    func scaledToFit(height: CGFloat, scaleMode: ScaleMode? = nil) -> some View {
        scaledToFit(width: .infinity, height: height, scaleMode: scaleMode)
    }
}
