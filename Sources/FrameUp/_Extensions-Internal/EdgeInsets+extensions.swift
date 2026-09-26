//
//  EdgeInsets+extensions.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-09-10.
//

import SwiftUI

internal extension EdgeInsets {
    /// These insets as measured in the local space of a view that has been rotated by the supplied angle, with each inset moved to the edge it lines up with.
    ///
    /// A `rotationEffect` does not carry a safe area through it, so insets measured outside a rotation have to be moved to the edges they meet inside one.
    ///
    ///     // A view rotated a quarter turn clockwise meets the parent's trailing inset along its own top edge.
    ///     EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 20)
    ///         .rotated(by: .degrees(90), layoutDirection: .leftToRight) // top: 20
    ///
    /// Angles are matched to the nearest quarter turn. A rotation part way between two of them turns the safe area rect off square, which insets cannot describe at all, so anything between the resting angles is left to the caller to interpolate.
    /// - Parameters:
    ///   - angle: Rotation applied to the view these insets are being moved into.
    ///   - layoutDirection: Layout direction used to resolve leading and trailing insets into left and right ones before rotating.
    /// - Returns: Insets moved to the edges they line up with after the rotation.
    func rotated(by angle: Angle, layoutDirection: LayoutDirection) -> EdgeInsets {
        let isLeftToRight = layoutDirection == .leftToRight
        /// Insets in clockwise order starting at the top.
        let edges = [top, isLeftToRight ? trailing : leading, bottom, isLeftToRight ? leading : trailing]
        /// Quarter turns clockwise in the range 0 to 3.
        let quarterTurns = (Int((angle.degrees / 90).rounded()) % 4 + 4) % 4
        
        /// An edge takes the inset a quarter turn behind it.
        func inset(edge: Int) -> CGFloat {
            edges[(edge + quarterTurns) % 4]
        }
        
        return EdgeInsets(
            top: inset(edge: 0),
            leading: inset(edge: isLeftToRight ? 3 : 1),
            bottom: inset(edge: 2),
            trailing: inset(edge: isLeftToRight ? 1 : 3)
        )
    }
    
    /// These insets with leading and trailing swapped, as seen from the opposite layout direction.
    var flippedHorizontally: EdgeInsets {
        EdgeInsets(top: top, leading: trailing, bottom: bottom, trailing: leading)
    }
    
    /// These insets named for the supplied layout direction, where they're named for left to right.
    func named(for layoutDirection: LayoutDirection) -> EdgeInsets {
        layoutDirection == .rightToLeft ? flippedHorizontally : self
    }
}
