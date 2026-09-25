//
//  FUCorners.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-09-25.
//

import SwiftUI

/// A value for each corner of a rectangle, named by leading and trailing like SwiftUI's corner types.
internal struct FUCorners<Value> {
    var topLeading: Value
    var topTrailing: Value
    var bottomLeading: Value
    var bottomTrailing: Value

    func map<T>(_ transform: (Value) -> T) -> FUCorners<T> {
        FUCorners<T>(
            topLeading: transform(topLeading),
            topTrailing: transform(topTrailing),
            bottomLeading: transform(bottomLeading),
            bottomTrailing: transform(bottomTrailing)
        )
    }

    /// These values as seen by a view that has been rotated by the supplied angle, with each value moved to the corner it lines up with.
    ///
    ///     // A view rotated a quarter turn clockwise has its top leading corner on the parent's top trailing corner.
    ///     FUCorners(topLeading: 1, topTrailing: 2, bottomLeading: 4, bottomTrailing: 3)
    ///         .rotated(by: .degrees(90), layoutDirection: .leftToRight) // topLeading: 2
    ///
    /// Angles are matched to the nearest quarter turn, as with `EdgeInsets.rotated(by:layoutDirection:)`. Values are moved but not changed, so a value with a direction, like a size, has to be turned by the caller as well.
    /// - Parameters:
    ///   - angle: Rotation applied to the view these values are being moved into.
    ///   - layoutDirection: Layout direction used to resolve leading and trailing corners into left and right ones before rotating.
    /// - Returns: Values moved to the corners they line up with after the rotation.
    func rotated(by angle: Angle, layoutDirection: LayoutDirection) -> FUCorners {
        let isLeftToRight = layoutDirection == .leftToRight
        /// Values in clockwise order starting at the top left.
        let corners = isLeftToRight
        ? [topLeading, topTrailing, bottomTrailing, bottomLeading]
        : [topTrailing, topLeading, bottomLeading, bottomTrailing]
        /// Quarter turns clockwise in the range 0 to 3.
        let quarterTurns = (Int((angle.degrees / 90).rounded()) % 4 + 4) % 4

        /// A corner takes the value a quarter turn behind it.
        func value(corner: Int) -> Value {
            corners[(corner + quarterTurns) % 4]
        }

        return FUCorners(
            topLeading: value(corner: isLeftToRight ? 0 : 1),
            topTrailing: value(corner: isLeftToRight ? 1 : 0),
            bottomLeading: value(corner: isLeftToRight ? 3 : 2),
            bottomTrailing: value(corner: isLeftToRight ? 2 : 3)
        )
    }
}

extension FUCorners: Equatable where Value: Equatable {}
extension FUCorners: Sendable where Value: Sendable {}

internal extension FUCorners where Value == CGSize {
    /// No inset at any corner.
    static let zero = FUCorners(topLeading: .zero, topTrailing: .zero, bottomLeading: .zero, bottomTrailing: .zero)

    /// Corner insets as seen by a view that has been rotated by the supplied angle. Each inset moves to the corner it lines up with, and swaps its width and height on a quarter turn.
    func rotatedInsets(by angle: Angle, layoutDirection: LayoutDirection) -> FUCorners {
        rotated(by: angle, layoutDirection: layoutDirection).map { $0.rotated(by: angle) }
    }
}
