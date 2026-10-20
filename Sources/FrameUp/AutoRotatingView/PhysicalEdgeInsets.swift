//
//  PhysicalEdgeInsets.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-09-10.
//

import SwiftUI

/// The inset on each edge of a rectangle, named by the side of the screen rather than by layout direction.
///
/// `EdgeInsets` names its sides leading and trailing, so which side one is depends on the layout direction it's read in. Rotating insets needs physical sides, so this type holds them until they're handed back as `EdgeInsets`.
internal struct PhysicalEdgeInsets: Equatable, Sendable {
    var top: CGFloat
    var left: CGFloat
    var bottom: CGFloat
    var right: CGFloat

    init(top: CGFloat = 0, left: CGFloat = 0, bottom: CGFloat = 0, right: CGFloat = 0) {
        self.top = top
        self.left = left
        self.bottom = bottom
        self.right = right
    }

    /// Insets with the value `inset` gives for each edge.
    init(_ inset: (PhysicalEdge) -> CGFloat) {
        self.init(top: inset(.top), left: inset(.left), bottom: inset(.bottom), right: inset(.right))
    }

    subscript(edge: PhysicalEdge) -> CGFloat {
        switch edge {
        case .top: top
        case .right: right
        case .bottom: bottom
        case .left: left
        }
    }

    /// Insets read from `EdgeInsets` named in the supplied layout direction.
    init(_ insets: EdgeInsets, layoutDirection: LayoutDirection) {
        let isLeftToRight = layoutDirection == .leftToRight
        self.init(
            top: insets.top,
            left: isLeftToRight ? insets.leading : insets.trailing,
            bottom: insets.bottom,
            right: isLeftToRight ? insets.trailing : insets.leading
        )
    }

    /// These insets named in the supplied layout direction.
    func edgeInsets(layoutDirection: LayoutDirection) -> EdgeInsets {
        let isLeftToRight = layoutDirection == .leftToRight
        return EdgeInsets(top: top, leading: isLeftToRight ? left : right, bottom: bottom, trailing: isLeftToRight ? right : left)
    }

    /// The insets edge by edge.
    static func + (lhs: PhysicalEdgeInsets, rhs: PhysicalEdgeInsets) -> PhysicalEdgeInsets {
        PhysicalEdgeInsets(top: lhs.top + rhs.top, left: lhs.left + rhs.left, bottom: lhs.bottom + rhs.bottom, right: lhs.right + rhs.right)
    }

    static func - (lhs: PhysicalEdgeInsets, rhs: PhysicalEdgeInsets) -> PhysicalEdgeInsets {
        PhysicalEdgeInsets(top: lhs.top - rhs.top, left: lhs.left - rhs.left, bottom: lhs.bottom - rhs.bottom, right: lhs.right - rhs.right)
    }

    /// These insets as measured in the local space of a view that has been rotated by the supplied number of quarter turns, with each inset moved to the edge it lines up with.
    ///
    /// A `rotationEffect` does not carry a safe area through it, so insets measured outside a rotation have to be moved to the edges they meet inside one.
    ///
    ///     // A view rotated a quarter turn clockwise meets the parent's right inset along its own top edge.
    ///     PhysicalEdgeInsets(right: 20).rotated(quarterTurns: 1) // top: 20
    ///
    /// A rotation part way between two of them turns the safe area rect off square, which insets cannot describe at all, so anything between the resting angles is left to the caller to interpolate.
    /// - Parameter quarterTurns: Quarter turns clockwise applied to the view these insets are being moved into.
    /// - Returns: Insets moved to the edges they line up with after the rotation.
    func rotated(quarterTurns: Int) -> PhysicalEdgeInsets {
        /// An edge takes the inset a quarter turn behind it.
        PhysicalEdgeInsets { self[$0.rotated(quarterTurns: quarterTurns)] }
    }

    /// These insets part way to another.
    func interpolated(to other: PhysicalEdgeInsets, progress: Double) -> PhysicalEdgeInsets {
        func mix(_ a: CGFloat, _ b: CGFloat) -> CGFloat { a + (b - a) * progress }
        return PhysicalEdgeInsets(top: mix(top, other.top), left: mix(left, other.left), bottom: mix(bottom, other.bottom), right: mix(right, other.right))
    }
}
