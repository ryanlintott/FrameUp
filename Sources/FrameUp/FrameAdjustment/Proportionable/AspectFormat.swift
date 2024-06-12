//
//  AspectFormat.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-09-11.
//

import SwiftUI

/// An enumeration to indicate the aspect format of a frame.
///
/// Used in `Proportionable` protocol
public enum AspectFormat: CaseIterable, Sendable {
    case portrait, square, landscape
    
    /// The aspect ratio format for a given aspect ratio
    /// - Parameter aspectRatio: Aspect ratio (width / height)
    /// - Returns: Aspect ratio format
    public static func forRatio(_ aspectRatio: CGFloat) -> Self {
        switch aspectRatio {
        case 1:
            return .square
        case ..<1:
            return .portrait
        default:
            return .landscape
        }
    }
}
