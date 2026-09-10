//
//  CGPoint+extensions.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-09-10.
//

import SwiftUI

internal extension CGPoint {
    /// This point turned around the origin by the supplied angle.
    ///
    /// Turns the same way a `rotationEffect` does, which is clockwise for a positive angle as the y axis points down.
    /// - Parameter angle: Rotation to apply.
    /// - Returns: The point the rotation moves this one to.
    func rotated(by angle: Angle) -> CGPoint {
        let cosine = CGFloat(cos(angle.radians))
        let sine = CGFloat(sin(angle.radians))
        return CGPoint(
            x: x * cosine - y * sine,
            y: x * sine + y * cosine
        )
    }
}
