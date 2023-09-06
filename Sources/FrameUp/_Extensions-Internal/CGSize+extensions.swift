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

    var minDimension: CGFloat {
        proportionableSize.minDimension
    }

    var maxDimension: CGFloat {
        proportionableSize.maxDimension
    }
    
    func scaledToFit(_ frame: CGSize) -> CGSize {
        if self == .zero { return .zero }
        switch aspectRatio - frame.aspectRatio {
        case 0: return frame
        case ..<0: return .init(width: frame.height * aspectRatio, height: frame.height)
        default: return .init(width: frame.width, height: frame.height / aspectRatio)
        }
    }
    
    func scaledToFill(_ frame: CGSize) -> CGSize {
        if self == .zero { return .zero }
        switch aspectRatio - frame.aspectRatio {
        case 0: return frame
        case ..<0: return .init(width: frame.width, height: frame.height / aspectRatio)
        default: return .init(width: frame.height * aspectRatio, height: frame.height)
        }
    }
}
