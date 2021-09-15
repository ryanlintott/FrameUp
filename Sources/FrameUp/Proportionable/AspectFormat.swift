//
//  AspectFormat.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-09-11.
//

import SwiftUI

public enum AspectFormat: CaseIterable {
    case portrait, square, landscape
    
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
