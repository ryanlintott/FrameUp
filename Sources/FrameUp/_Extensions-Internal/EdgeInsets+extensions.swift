//
//  EdgeInsets+extensions.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-09-10.
//

import SwiftUI

internal extension EdgeInsets {
    /// These insets as measured in the local space of a view that has been rotated by the supplied angle.
    ///
    /// A `rotationEffect` does not carry a safe area with it. When insets measured outside a rotation are re-applied inside one they need to be moved to the edges they now line up with.
    ///
    ///     // A view rotated a quarter turn clockwise meets the parent's trailing inset along its own top edge.
    ///     EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 20)
    ///         .rotated(by: .degrees(90), layoutDirection: .leftToRight) // top: 20
    ///
    /// Every angle in between gives insets that place the centre of the inset rect exactly where the rotation puts it, so content stays on the axis of rotation for the whole turn. Interpolating between two quarter turns instead would move that centre in a straight line between two points on a circle, pulling content off axis part way through. ``rotatedBlendingEdges(by:layoutDirection:)`` is the alternative that leaves the centre where the blend puts it.
    /// - Parameters:
    ///   - angle: Rotation applied to the view these insets are being moved into.
    ///   - layoutDirection: Layout direction used to resolve leading and trailing insets into left and right ones before rotating.
    /// - Returns: Insets with each value moved to the edge it lines up with after the rotation.
    func rotated(by angle: Angle, layoutDirection: LayoutDirection) -> EdgeInsets {
        let isLeftToRight = layoutDirection == .leftToRight
        let left = isLeftToRight ? leading : trailing
        let right = isLeftToRight ? trailing : leading
        let cosine = CGFloat(cos(angle.radians))
        let sine = CGFloat(sin(angle.radians))
        
        /// Centre of the inset rect relative to the centre of the whole rect, rotated into the local space of the rotated view.
        let centerX = (left - right) / 2 * cosine + (top - bottom) / 2 * sine
        let centerY = (top - bottom) / 2 * cosine - (left - right) / 2 * sine
        /// Insets on each axis added together, swapping axes over a quarter turn, and never less than the amount needed to place the centre.
        let horizontal = max((left + right) * cosine * cosine + (top + bottom) * sine * sine, abs(centerX) * 2)
        let vertical = max((top + bottom) * cosine * cosine + (left + right) * sine * sine, abs(centerY) * 2)
        
        let newLeft = horizontal / 2 + centerX
        let newRight = horizontal / 2 - centerX
        
        return EdgeInsets(
            top: vertical / 2 + centerY,
            leading: isLeftToRight ? newLeft : newRight,
            bottom: vertical / 2 - centerY,
            trailing: isLeftToRight ? newRight : newLeft
        )
    }
    
    /// These insets as measured in the local space of a view that has been rotated by the supplied angle, moving each inset toward the edge it is turning onto.
    ///
    /// Where ``rotated(by:layoutDirection:)`` builds the insets around the centre of the inset rect so content stays on the axis of rotation, this only blends each edge from the inset it meets at one quarter turn to the inset it meets at the next. It is exact at every quarter turn and never negative, but between them the centre of the inset rect no longer lines up with the centre of the real safe area, so content drifts off axis part way through a turn.
    ///
    ///     // A view rotated a quarter turn clockwise meets the parent's trailing inset along its own top edge.
    ///     EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 20)
    ///         .rotatedBlendingEdges(by: .degrees(90), layoutDirection: .leftToRight) // top: 20
    ///
    /// The blend is weighted by the square of the sine and cosine of the angle past the quarter turn, which is flat at both ends, so an inset changes at the same rate on either side of a quarter turn instead of turning a corner as it passes one.
    /// - Parameters:
    ///   - angle: Rotation applied to the view these insets are being moved into.
    ///   - layoutDirection: Layout direction used to resolve leading and trailing insets into left and right ones before rotating.
    /// - Returns: Insets blended toward the edges they line up with after the rotation.
    func rotatedBlendingEdges(by angle: Angle, layoutDirection: LayoutDirection) -> EdgeInsets {
        let isLeftToRight = layoutDirection == .leftToRight
        /// Insets in clockwise order starting at the top.
        let edges = [top, isLeftToRight ? trailing : leading, bottom, isLeftToRight ? leading : trailing]
        /// Whole quarter turns clockwise, and how far past that quarter turn the angle reaches.
        let turns = (angle.degrees / 90).rounded(.down)
        let quarterTurns = (Int(turns) % 4 + 4) % 4
        let past = Angle.degrees(angle.degrees - turns * 90)
        let blend = CGFloat(sin(past.radians) * sin(past.radians))
        
        /// An edge takes the inset a quarter turn behind it, blending toward the one behind that.
        func inset(edge: Int) -> CGFloat {
            let from = edges[(edge + quarterTurns) % 4]
            let to = edges[(edge + quarterTurns + 1) % 4]
            return from * (1 - blend) + to * blend
        }
        
        return EdgeInsets(
            top: inset(edge: 0),
            leading: inset(edge: isLeftToRight ? 3 : 1),
            bottom: inset(edge: 2),
            trailing: inset(edge: isLeftToRight ? 1 : 3)
        )
    }
}
