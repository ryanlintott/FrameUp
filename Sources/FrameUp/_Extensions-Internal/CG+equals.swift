//
//  CG+equals.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-09-13.
//

import Foundation

internal extension CGRect {
    func equals(_ other: Self, precision: CGFloat) -> Bool {
        origin.equals(other.origin, precision: precision) && size.equals(other.size, precision: precision)
    }
}

internal extension CGPoint {
    func equals(_ other: Self, precision: CGFloat) -> Bool {
        x.equals(other.x, precision: precision) && y.equals(other.y, precision: precision)
    }
}

internal extension CGSize {
    func equals(_ other: Self, precision: CGFloat) -> Bool {
        width.equals(other.width, precision: precision) && height.equals(other.height, precision: precision)
    }
}

internal extension CGFloat {
    func equals(_ other: CGFloat, precision: CGFloat) -> Bool {
        Int((self / precision).rounded()) == Int((other / precision).rounded())
    }
}
