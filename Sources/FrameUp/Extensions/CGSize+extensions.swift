//
//  ProportionableSize.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-09-16.
//

import SwiftUI

/// Used to easily add internal Proportionable conformance to CGSize
fileprivate struct ProportionableSize: Proportionable {
    var width: CGFloat
    var height: CGFloat
    
    init(_ cgSize: CGSize) {
        width = cgSize.width
        height = cgSize.height
    }
}

internal extension CGSize {
    fileprivate var proportionableSize: ProportionableSize {
        ProportionableSize(self)
    }
    
    var aspectFormat: AspectFormat {
        proportionableSize.aspectFormat
    }
    
    var aspectRatio: CGFloat {
        proportionableSize.aspectRatio
    }

    var minDimension: CGFloat {
        proportionableSize.minDimension
    }

    var maxDimension: CGFloat {
        proportionableSize.maxDimension
    }
}
