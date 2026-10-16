//
//  Angle+extensions.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-08-24.
//

import SwiftUI

internal extension Angle {
    /// An angle equivalent to the supplied angle that is closest to this angle.
    ///
    /// Useful when animating rotation as the shortest path will always be taken.
    ///
    ///     Angle.degrees(-90).closestEquivalent(to: .degrees(180)) // -180 degrees
    ///
    /// - Parameter angle: Angle to find an equivalent for.
    /// - Returns: An angle equivalent to the supplied angle and no more than 180 degrees from this angle.
    func closestEquivalent(to angle: Angle) -> Angle {
        .degrees(degrees + (angle.degrees - degrees).remainder(dividingBy: 360))
    }
    
    /// The angle equivalent to another that's closest to this one relative to an enclosing frame that turns by `enclosingChange` at the same time.
    ///
    /// Content inside a turning frame is seen to turn by its change less the frame's, so that's the change kept under half a turn. With no enclosing change it's the same as `closestEquivalent(to:)`.
    func closestEquivalent(to angle: Angle, enclosingChange: Angle) -> Angle {
        (self + enclosingChange).closestEquivalent(to: angle)
    }
}
