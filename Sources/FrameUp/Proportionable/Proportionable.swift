//
//  Proportionable.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-09-03.
//

import SwiftUI

/// A type that has a width and height.
///
/// Adds helpful parameters like `aspectFormat`, `aspectRatio`, `minDimension`, and `maxDimension`
///
/// Useful with `CGSize`
public protocol Proportionable {
    init(width: CGFloat, height: CGFloat)
    var width: CGFloat { get }
    var height: CGFloat { get }
}

public extension Proportionable {
    /// Aspect format based on the aspect ratio.
    var aspectFormat: AspectFormat {
        .forRatio(aspectRatio)
    }
    
    /// Aspect ratio (width / height).
    var aspectRatio: CGFloat {
        width / height
    }
    
    var swappingWidthAndHeight: Self {
        Self(width: height, height: width)
    }
    
    /// Minimum dimension between width and height.
    var minDimension: CGFloat {
        return Swift.min(width, height)
    }
    
    /// Maximum dimension between width and height.
    var maxDimension: CGFloat {
        return Swift.max(width, height)
    }
}
