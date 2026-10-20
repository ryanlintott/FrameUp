//
//  PhysicalCornerValues.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-09-25.
//

import SwiftUI

/// A corner of a rectangle named by the side of the screen rather than by layout direction, in clockwise order from the top left.
///
/// SwiftUI's corner types name their corners by leading and trailing, so which corner one is depends on the layout direction it's read in.
internal enum PhysicalCorner: Int, CaseIterable, Sendable {
    case topLeft, topRight, bottomRight, bottomLeft

    /// The corner reached by going the supplied number of quarter turns clockwise round the rectangle from this one.
    func rotated(quarterTurns: Int) -> PhysicalCorner {
        Self.allCases[(rawValue + quarterTurns).positiveRemainder(dividingBy: 4)]
    }

    /// The corner at the top and leading edges in the supplied layout direction.
    static func topLeading(_ layoutDirection: LayoutDirection) -> PhysicalCorner {
        layoutDirection == .leftToRight ? .topLeft : .topRight
    }

    /// The corner at the top and trailing edges in the supplied layout direction.
    static func topTrailing(_ layoutDirection: LayoutDirection) -> PhysicalCorner {
        layoutDirection == .leftToRight ? .topRight : .topLeft
    }

    /// The corner at the bottom and leading edges in the supplied layout direction.
    static func bottomLeading(_ layoutDirection: LayoutDirection) -> PhysicalCorner {
        layoutDirection == .leftToRight ? .bottomLeft : .bottomRight
    }

    /// The corner at the bottom and trailing edges in the supplied layout direction.
    static func bottomTrailing(_ layoutDirection: LayoutDirection) -> PhysicalCorner {
        layoutDirection == .leftToRight ? .bottomRight : .bottomLeft
    }
}

/// A value for each corner of a rectangle, named by the side of the screen rather than by layout direction.
///
/// SwiftUI's corner types name their corners by leading and trailing, so which corner one is depends on the layout direction it's read in. Rotating corners needs physical ones, so this type holds them until they're handed back in SwiftUI's types.
internal struct PhysicalCornerValues<Value> {
    var topLeft: Value
    var topRight: Value
    var bottomRight: Value
    var bottomLeft: Value

    init(topLeft: Value, topRight: Value, bottomLeft: Value, bottomRight: Value) {
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomRight = bottomRight
        self.bottomLeft = bottomLeft
    }

    /// Values with the one `value` gives for each corner.
    init(_ value: (PhysicalCorner) -> Value) {
        self.init(topLeft: value(.topLeft), topRight: value(.topRight), bottomLeft: value(.bottomLeft), bottomRight: value(.bottomRight))
    }

    /// Values named by leading and trailing in the supplied layout direction.
    init(topLeading: Value, topTrailing: Value, bottomLeading: Value, bottomTrailing: Value, layoutDirection: LayoutDirection) {
        let isLeftToRight = layoutDirection == .leftToRight
        self.init(
            topLeft: isLeftToRight ? topLeading : topTrailing,
            topRight: isLeftToRight ? topTrailing : topLeading,
            bottomLeft: isLeftToRight ? bottomLeading : bottomTrailing,
            bottomRight: isLeftToRight ? bottomTrailing : bottomLeading
        )
    }

    subscript(corner: PhysicalCorner) -> Value {
        switch corner {
        case .topLeft: topLeft
        case .topRight: topRight
        case .bottomRight: bottomRight
        case .bottomLeft: bottomLeft
        }
    }

    func map<T>(_ transform: (Value) -> T) -> PhysicalCornerValues<T> {
        PhysicalCornerValues<T> { transform(self[$0]) }
    }

    /// These values as seen by a view that has been rotated by the supplied number of quarter turns, with each value moved to the corner it lines up with.
    ///
    ///     // A view rotated a quarter turn clockwise has its top left corner on the parent's top right corner.
    ///     PhysicalCornerValues(topLeft: 1, topRight: 2, bottomLeft: 4, bottomRight: 3)
    ///         .rotated(quarterTurns: 1) // topLeft: 2
    ///
    /// Values are moved but not changed, so a value with a direction, like a size, has to be turned by the caller as well.
    /// - Parameter quarterTurns: Quarter turns clockwise applied to the view these values are being moved into.
    /// - Returns: Values moved to the corners they line up with after the rotation.
    func rotated(quarterTurns: Int) -> PhysicalCornerValues {
        /// A corner takes the value a quarter turn behind it.
        PhysicalCornerValues { self[$0.rotated(quarterTurns: quarterTurns)] }
    }
}

/// A size at each corner, such as a container's corner insets.
internal typealias PhysicalCornerInsets = PhysicalCornerValues<CGSize>

/// A radius at each corner.
internal typealias PhysicalCornerRadii = PhysicalCornerValues<CGFloat>

extension PhysicalCornerValues: Equatable where Value: Equatable {}
extension PhysicalCornerValues: Sendable where Value: Sendable {}

internal extension PhysicalCornerInsets {
    /// No inset at any corner.
    static let zero = PhysicalCornerInsets { _ in .zero }

    /// Corner insets as seen by a view that has been rotated by the supplied number of quarter turns. Each inset moves to the corner it lines up with, and swaps its width and height on a quarter turn.
    func rotatedInsets(quarterTurns: Int) -> PhysicalCornerInsets {
        rotated(quarterTurns: quarterTurns).map { $0.rotated(quarterTurns: quarterTurns) }
    }
}

@available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
internal extension PhysicalCornerRadii {
    init(_ radii: RectangleCornerRadii, layoutDirection: LayoutDirection) {
        self.init(topLeading: radii.topLeading, topTrailing: radii.topTrailing, bottomLeading: radii.bottomLeading, bottomTrailing: radii.bottomTrailing, layoutDirection: layoutDirection)
    }
}

@available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
internal extension RectangleCornerRadii {
    init(_ corners: PhysicalCornerRadii, layoutDirection: LayoutDirection) {
        self.init(
            topLeading: corners[.topLeading(layoutDirection)],
            bottomLeading: corners[.bottomLeading(layoutDirection)],
            bottomTrailing: corners[.bottomTrailing(layoutDirection)],
            topTrailing: corners[.topTrailing(layoutDirection)]
        )
    }
}

#if os(iOS) && compiler(>=6.2)
@available(iOS 26, *)
internal extension PhysicalCornerInsets {
    init(_ insets: RectangleCornerInsets, layoutDirection: LayoutDirection) {
        self.init(
            topLeading: insets.topLeading,
            topTrailing: insets.topTrailing,
            bottomLeading: insets.bottomLeading,
            bottomTrailing: insets.bottomTrailing,
            layoutDirection: layoutDirection
        )
    }
}

@available(iOS 26, *)
internal extension RectangleCornerInsets {
    init(_ insets: PhysicalCornerInsets, layoutDirection: LayoutDirection) {
        self.init(
            topLeading: insets[.topLeading(layoutDirection)],
            topTrailing: insets[.topTrailing(layoutDirection)],
            bottomLeading: insets[.bottomLeading(layoutDirection)],
            bottomTrailing: insets[.bottomTrailing(layoutDirection)]
        )
    }
}
#endif
