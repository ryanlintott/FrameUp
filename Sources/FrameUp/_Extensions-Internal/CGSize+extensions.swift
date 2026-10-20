//
//  CGSize+extensions.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-09-16.
//

import SwiftUI

/// An internal alternative type to CGSize
///
/// Used to add Proportionable conformance to CGSize internally only.
fileprivate struct ProportionableSize: Proportionable {
    var width: CGFloat
    var height: CGFloat
    
    var size: CGSize {
        CGSize(width: width, height: height)
    }
}

internal extension CGSize {
    fileprivate var proportionableSize: ProportionableSize {
        ProportionableSize(width: width, height: height)
    }
    
    var aspectFormat: AspectFormat {
        proportionableSize.aspectFormat
    }
    
    var aspectRatio: CGFloat {
        proportionableSize.aspectRatio
    }
    
    var swappingWidthAndHeight: CGSize {
        proportionableSize.swappingWidthAndHeight.size
    }
    
    /// This size as seen from inside a rotation of the supplied number of quarter turns.
    ///
    /// A quarter turn either leaves a size as it is or swaps its width and height.
    /// - Parameter quarterTurns: Quarter turns applied to the view this size is measured in.
    /// - Returns: This size, with its width and height swapped by an odd number of quarter turns.
    func rotated(quarterTurns: Int) -> CGSize {
        quarterTurns % 2 == 0 ? self : swappingWidthAndHeight
    }
    
    init(width: CGFloat, aspectRatio: CGFloat) {
        self = ProportionableSize(width: width, aspectRatio: aspectRatio).size
    }
    
    init(height: CGFloat, aspectRatio: CGFloat) {
        self = ProportionableSize(height: height, aspectRatio: aspectRatio).size
    }
    
    static func square(_ width: CGFloat) -> Self {
        ProportionableSize.square(width).size
    }
    
    func scaledToFit(_ frame: CGSize) -> CGSize {
        proportionableSize.scaledToFit(frame.proportionableSize).size
    }
    
    func scaledToFill(_ frame: CGSize) -> CGSize {
        proportionableSize.scaledToFill(frame.proportionableSize).size
    }
}
