//
//  FUInterfaceTurn.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-16.
//

#if os(iOS)
import SwiftUI

/// How a view is turned relative to the interface the system laid out, whatever the interface's orientation. The interface's top is always the top.
///
/// Read it from ``SwiftUICore/EnvironmentValues/interfaceTurn``. Outside any `AutoRotatingView` it's ``none``, and inside one it's how that view's content is turned. Content that an `AutoRotatingView` turns back to upright, such as an item that stays upright in a turned frame, sees ``none`` again.
///
///     @Environment(\.interfaceTurn) var turn
///     @Environment(\.layoutDirection) var layoutDirection
///
///     // The edge of this view at the top of the interface, to list items top to bottom.
///     let firstEdge = turn.localEdge(of: .top, layoutDirection: layoutDirection)
///
/// Edges are layout-relative, so the layout direction resolves leading and trailing.
public enum FUInterfaceTurn: Hashable, Sendable, CaseIterable {
    /// Upright in the interface.
    case none
    /// A quarter turn clockwise: the view's top is at the interface's right.
    case quarterClockwise
    /// Upside down in the interface.
    case half
    /// A quarter turn anticlockwise: the view's top is at the interface's left.
    case quarterCounterclockwise

    /// The turn nearest an angle, clockwise positive.
    init(_ angle: Angle) {
        switch (Int((angle.degrees / 90).rounded()) % 4 + 4) % 4 {
        case 1: self = .quarterClockwise
        case 2: self = .half
        case 3: self = .quarterCounterclockwise
        default: self = .none
        }
    }

    /// Quarter turns clockwise, 0 to 3.
    private var quarterTurns: Int {
        switch self {
        case .none: 0
        case .quarterClockwise: 1
        case .half: 2
        case .quarterCounterclockwise: 3
        }
    }

    /// The turn as an angle, clockwise positive, for drawing.
    public var angle: Angle {
        .degrees(Double(quarterTurns) * 90)
    }

    /// True when the view is a quarter turn either way, so its width runs up and down the interface.
    public var isSideways: Bool {
        quarterTurns % 2 == 1
    }

    /// Where one of this view's edges is in the interface. `interfaceEdge(of: .top)` is where this view's top points.
    /// - Parameters:
    ///   - localEdge: An edge of this view.
    ///   - layoutDirection: The layout direction both edges are named in.
    public func interfaceEdge(of localEdge: Edge, layoutDirection: LayoutDirection) -> Edge {
        Self.edge(clockwiseIndex: Self.clockwiseIndex(localEdge, layoutDirection) + quarterTurns, layoutDirection)
    }

    /// Which of this view's edges is at an edge of the interface. `localEdge(of: .top)` is the end to start from to list items top to bottom.
    /// - Parameters:
    ///   - interfaceEdge: An edge of the interface.
    ///   - layoutDirection: The layout direction both edges are named in.
    public func localEdge(of interfaceEdge: Edge, layoutDirection: LayoutDirection) -> Edge {
        Self.edge(clockwiseIndex: Self.clockwiseIndex(interfaceEdge, layoutDirection) - quarterTurns, layoutDirection)
    }

    /// An edge's place in clockwise order from the top: top, right, bottom, left.
    private static func clockwiseIndex(_ edge: Edge, _ layoutDirection: LayoutDirection) -> Int {
        switch edge.physical(layoutDirection) {
        case .top: 0
        case .trailing: 1
        case .bottom: 2
        case .leading: 3
        }
    }

    /// The edge at a place in clockwise order from the top, named for the layout direction.
    private static func edge(clockwiseIndex: Int, _ layoutDirection: LayoutDirection) -> Edge {
        let physical: Edge = switch (clockwiseIndex % 4 + 4) % 4 {
        case 1: .trailing
        case 2: .bottom
        case 3: .leading
        default: .top
        }
        /// Swapping leading and trailing turns a physical name into a layout-relative one, as it does the other way.
        return physical.physical(layoutDirection)
    }
}

private struct InterfaceTurnKey: EnvironmentKey {
    static let defaultValue: FUInterfaceTurn = .none
}

public extension EnvironmentValues {
    /// How this view is turned relative to the interface: ``FUInterfaceTurn/none`` outside any `AutoRotatingView`, and inside one, how its content is turned.
    var interfaceTurn: FUInterfaceTurn {
        get { self[InterfaceTurnKey.self] }
        set { self[InterfaceTurnKey.self] = newValue }
    }
}
#endif
