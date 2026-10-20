//
//  EnvironmentValues+AutoRotatingView.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-14.
//

#if os(iOS)
import SwiftUI

private struct AutoRotatingOrientationKey: EnvironmentKey {
    static let defaultValue: FUInterfaceOrientation? = nil
}

private struct AutoRotatingHeldTurnAnimationKey: EnvironmentKey {
    static let defaultValue: Animation? = nil
}

private struct AutoRotatingTargetSafeAreaInsetsKey: EnvironmentKey {
    static let defaultValue = EdgeInsets()
}

public extension EnvironmentValues {
    /// The orientation of the nearest enclosing `AutoRotatingView`'s content, or nil outside one or when it's off.
    ///
    /// On the inner screen of a foldable iPhone it's named as that screen names its orientations, so portrait is taller than it is wide on either screen.
    var autoRotatingOrientation: FUInterfaceOrientation? {
        get { self[AutoRotatingOrientationKey.self] }
        set { self[AutoRotatingOrientationKey.self] = newValue }
    }

    /// An animation timed like the system's turn while the nearest enclosing `AutoRotatingView` holds its content still, or nil.
    ///
    /// Use it with `animation(_:value:)` for changes the turn brings, so they move in step with it. The scoped `animation(_:body:)` doesn't animate inside held content.
    var autoRotatingHeldTurnAnimation: Animation? {
        get { self[AutoRotatingHeldTurnAnimationKey.self] }
        set { self[AutoRotatingHeldTurnAnimationKey.self] = newValue }
    }

    /// The safe area the nearest enclosing `AutoRotatingView`'s content will have once its turn is over, or no insets outside one.
    ///
    /// Use it to size something by where the safe area ends up, rather than by the safe area as it moves.
    var autoRotatingTargetSafeAreaInsets: EdgeInsets {
        get { self[AutoRotatingTargetSafeAreaInsetsKey.self] }
        set { self[AutoRotatingTargetSafeAreaInsetsKey.self] = newValue }
    }
}

/// How the safe area of an `AutoRotatingView`'s content moves during its latest turn.
internal struct SafeAreaTurn: Equatable {
    /// The safe area at this step of the turn.
    var current: PhysicalEdgeInsets
    /// The safe area once the turn is over.
    var target: PhysicalEdgeInsets
}

/// The rotation of an `AutoRotatingView`'s content relative to the interface during the latest turn.
internal struct ContentRotation: Equatable {
    /// The rotation when the turn started.
    var startRotation: Angle = .zero
    /// How far the content turns.
    var rotationChange: Angle = .zero
}

private struct SafeAreaTurnKey: EnvironmentKey {
    static let defaultValue: SafeAreaTurn? = nil
}

private struct EnclosingContentRotationKey: EnvironmentKey {
    static let defaultValue = ContentRotation()
}

private struct EnclosingCounterRotationKey: EnvironmentKey {
    static let defaultValue: FUCounterRotationStyle? = nil
}

private struct SystemBarIsTurnStartKey: EnvironmentKey {
    static let defaultValue = false
}

private struct HostHeldOrientationsKey: EnvironmentKey {
    static let defaultValue: Set<FUInterfaceOrientation> = []
}

internal extension EnvironmentValues {
    /// The rotation of the nearest enclosing `AutoRotatingView`'s content, or none.
    var fuEnclosingContentRotation: ContentRotation {
        get { self[EnclosingContentRotationKey.self] }
        set { self[EnclosingContentRotationKey.self] = newValue }
    }

    /// The counter-rotation style of the nearest enclosing `AutoRotatingView` whose content the system can turn away from, or nil.
    var fuEnclosingCounterRotation: FUCounterRotationStyle? {
        get { self[EnclosingCounterRotationKey.self] }
        set { self[EnclosingCounterRotationKey.self] = newValue }
    }

    /// How the safe area of the nearest enclosing `AutoRotatingView`'s content moves during its turn, or nil.
    var fuSafeAreaTurn: SafeAreaTurn? {
        get { self[SafeAreaTurnKey.self] }
        set { self[SafeAreaTurnKey.self] = newValue }
    }

    /// True while ``fuSystemBar`` is the measurement from the start of the enclosing turn, rather than the new one.
    var fuSystemBarIsTurnStart: Bool {
        get { self[SystemBarIsTurnStartKey.self] }
        set { self[SystemBarIsTurnStartKey.self] = newValue }
    }

    /// The interface orientations that enclosing hosts already hold their content still for.
    var fuHostHeldOrientations: Set<FUInterfaceOrientation> {
        get { self[HostHeldOrientationsKey.self] }
        set { self[HostHeldOrientationsKey.self] = newValue }
    }
}
#endif
