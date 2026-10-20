//
//  PhysicalEdge.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-20.
//

import SwiftUI

/// An edge of a rectangle named by the side of the screen rather than by layout direction, in clockwise order from the top.
///
/// SwiftUI's `Edge` names its sides leading and trailing, so which side one is depends on the layout direction it's read in.
internal enum PhysicalEdge: Int, CaseIterable, Sendable {
    case top, right, bottom, left

    /// The edge reached by going the supplied number of quarter turns clockwise round the rectangle from this one.
    func rotated(quarterTurns: Int) -> PhysicalEdge {
        Self.allCases[(rawValue + quarterTurns).positiveRemainder(dividingBy: 4)]
    }

    /// The edge a SwiftUI edge is on, when it's named in the supplied layout direction.
    init(_ edge: Edge, layoutDirection: LayoutDirection) {
        let isLeftToRight = layoutDirection == .leftToRight
        self = switch edge {
        case .top: .top
        case .bottom: .bottom
        case .leading: isLeftToRight ? .left : .right
        case .trailing: isLeftToRight ? .right : .left
        }
    }

    /// This edge as a SwiftUI edge named in the supplied layout direction.
    func edge(layoutDirection: LayoutDirection) -> Edge {
        let isLeftToRight = layoutDirection == .leftToRight
        return switch self {
        case .top: .top
        case .bottom: .bottom
        case .left: isLeftToRight ? .leading : .trailing
        case .right: isLeftToRight ? .trailing : .leading
        }
    }
}
