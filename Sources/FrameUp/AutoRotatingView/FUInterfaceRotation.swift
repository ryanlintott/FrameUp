//
//  FUInterfaceRotation.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-16.
//

#if os(iOS)
import SwiftUI

/// How far a view is rotated clockwise relative to the interface the system laid out.
///
/// Read it from ``SwiftUICore/EnvironmentValues/interfaceRotation``. It's ``zero`` outside any `AutoRotatingView`.
///
///     @Environment(\.interfaceRotation) var rotation
///     @Environment(\.layoutDirection) var layoutDirection
///
///     // The edge of this view at the top of the interface.
///     let firstEdge = rotation.localEdge(of: .top, layoutDirection: layoutDirection)
public enum FUInterfaceRotation: Hashable, Sendable, CaseIterable {
    /// Upright in the interface.
    case zero
    /// Rotated a quarter turn clockwise: the view's top is at the interface's right.
    case degrees90
    /// Upside down in the interface.
    case degrees180
    /// Rotated three quarter turns clockwise: the view's top is at the interface's left.
    case degrees270

    /// The rotation of the supplied number of quarter turns clockwise, negative for anticlockwise and any number of turns.
    init(quarterTurns: Int) {
        self = Self.allCases[quarterTurns.positiveRemainder(dividingBy: 4)]
    }

    /// The rotation nearest an angle, clockwise positive.
    init(_ angle: Angle) {
        self.init(quarterTurns: angle.quarterTurns)
    }

    /// The rotation nearest an angle, or nil if the angle is more than a degree from a quarter turn.
    init?(exactly angle: Angle) {
        guard abs(angle.degrees - Double(angle.quarterTurns) * 90) < 1 else { return nil }
        self.init(angle)
    }

    /// Quarter turns clockwise, 0 to 3.
    var quarterTurns: Int {
        switch self {
        case .zero: 0
        case .degrees90: 1
        case .degrees180: 2
        case .degrees270: 3
        }
    }

    /// Quarter turns in whichever direction is shorter, 0 to 2.
    var shortestQuarterTurns: Int {
        min(quarterTurns, 4 - quarterTurns)
    }

    /// The rotation as an angle, clockwise positive.
    public var angle: Angle {
        .degrees(Double(quarterTurns) * 90)
    }

    /// True when the view is a quarter turn either way.
    public var isSideways: Bool {
        quarterTurns % 2 == 1
    }

    /// Where one of this view's edges is in the interface. `interfaceEdge(of: .top)` is where this view's top points.
    /// - Parameters:
    ///   - localEdge: An edge of this view.
    ///   - layoutDirection: The layout direction both edges are named in.
    public func interfaceEdge(of localEdge: Edge, layoutDirection: LayoutDirection) -> Edge {
        PhysicalEdge(localEdge, layoutDirection: layoutDirection).rotated(by: self).edge(layoutDirection: layoutDirection)
    }

    /// Which of this view's edges is at an edge of the interface.
    /// - Parameters:
    ///   - interfaceEdge: An edge of the interface.
    ///   - layoutDirection: The layout direction both edges are named in.
    public func localEdge(of interfaceEdge: Edge, layoutDirection: LayoutDirection) -> Edge {
        PhysicalEdge(interfaceEdge, layoutDirection: layoutDirection).rotated(quarterTurns: -quarterTurns).edge(layoutDirection: layoutDirection)
    }
}

extension FUInterfaceRotation: AdditiveArithmetic {
    public static func - (lhs: FUInterfaceRotation, rhs: FUInterfaceRotation) -> FUInterfaceRotation {
        .init(quarterTurns: lhs.quarterTurns - rhs.quarterTurns)
    }
    
    public static func + (lhs: FUInterfaceRotation, rhs: FUInterfaceRotation) -> FUInterfaceRotation {
        .init(quarterTurns: lhs.quarterTurns + rhs.quarterTurns)
    }
}

extension PhysicalEdge {
    /// The edge this one is turned to by a rotation.
    func rotated(by rotation: FUInterfaceRotation) -> PhysicalEdge {
        rotated(quarterTurns: rotation.quarterTurns)
    }
}

private struct InterfaceRotationKey: EnvironmentKey {
    static let defaultValue: FUInterfaceRotation = .zero
}

public extension EnvironmentValues {
    /// How far this view is rotated relative to the interface by any enclosing `AutoRotatingView`.
    var interfaceRotation: FUInterfaceRotation {
        get { self[InterfaceRotationKey.self] }
        set { self[InterfaceRotationKey.self] = newValue }
    }
}
#endif
