//
//  Proportionable.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-09-03.
//

import SwiftUI

/// A type that has a width and height.
///
/// Adds helpful parameters like ``aspectFormat``, ``aspectRatio``, ``minDimension``, and ``maxDimension``
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
    
    /// Create a size with the provided width and aspect ratio.
    /// - Parameters:
    ///   - width: A width value.
    ///   - aspectRatio: Aspect ratio (width / height).
    init(width: CGFloat, aspectRatio: CGFloat) {
        self = .init(width: width, height: width / aspectRatio)
    }
    
    /// Create a size with the provided height and aspect ratio.
    /// - Parameters:
    ///   - height: A height value.
    ///   - aspectRatio: Aspect ratio (width / height).
    init(height: CGFloat, aspectRatio: CGFloat) {
        self = .init(width: height * aspectRatio, height: height)
    }
    
    /// Creates a size with an aspect ratio of 1.
    /// - Parameter width: Used for width and height.
    /// - Returns: A size with an aspect ratio of 1.
    static func square(_ width: CGFloat) -> Self {
        .init(width: width, aspectRatio: 1)
    }
    
    /// Creates a size with the aspect ratio of this size but scaled to fit provided frame.
    /// - Parameter frame: Frame size.
    /// - Returns: A size with the aspect ratio of this size but scaled to fit provided frame.
    func scaledToFit(_ frame: Self) -> Self {
        if width == .zero && height == .zero { return .init(width: 0, height: 0) }
        switch aspectRatio - frame.aspectRatio {
        case 0: return frame
        case ..<0: return .init(width: frame.height * aspectRatio, height: frame.height)
        default: return .init(width: frame.width, height: frame.width / aspectRatio)
        }
    }
    
    /// Creates a size with the aspect ratio of this size but scaled to fill provided frame.
    /// - Parameter frame: Frame size
    /// - Returns: A size with the aspect ratio of this size but scaled to fill provided frame.
    func scaledToFill(_ frame: Self) -> Self {
        if width == .zero && height == .zero { return .init(width: 0, height: 0) }
        switch aspectRatio - frame.aspectRatio {
        case 0: return frame
        case ..<0: return .init(width: frame.width, height: frame.width / aspectRatio)
        default: return .init(width: frame.height * aspectRatio, height: frame.height)
        }
    }
}
