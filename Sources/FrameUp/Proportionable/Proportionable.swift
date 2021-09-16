//
//  Proportionable.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-09-03.
//

import SwiftUI

public protocol Proportionable {
    var width: CGFloat { get }
    var height: CGFloat { get }
}

public extension Proportionable {
    var aspectFormat: AspectFormat {
        .forRatio(aspectRatio)
    }
    
    var aspectRatio: CGFloat {
        width / height
    }

    var minDimension: CGFloat {
        return Swift.min(width, height)
    }

    var maxDimension: CGFloat {
        return Swift.max(width, height)
    }
}
