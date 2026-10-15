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

public extension EnvironmentValues {
    /// The orientation of the content of the nearest enclosing `AutoRotatingView`, named for the way the device is held when the content is upright, or nil outside one.
    ///
    /// It's also nil when the view is off, and on the inner screen of a foldable iPhone, where the content always matches the interface.
    ///
    ///     AutoRotatingView([.portrait, .landscapeLeft]) {
    ///         Content()
    ///     }
    ///
    ///     struct Content: View {
    ///         @Environment(\.autoRotatingOrientation) private var orientation
    ///
    ///         var body: some View {
    ///             Text(orientation == .portrait ? "Portrait" : "Landscape")
    ///         }
    ///     }
    var autoRotatingOrientation: FUInterfaceOrientation? {
        get { self[AutoRotatingOrientationKey.self] }
        set { self[AutoRotatingOrientationKey.self] = newValue }
    }
}

private struct AutoRotatingContentRotationKey: EnvironmentKey {
    static let defaultValue: Angle = .zero
}

internal extension EnvironmentValues {
    /// The rotation of the content of the nearest enclosing `AutoRotatingView` relative to the interface.
    var fuAutoRotatingContentRotation: Angle {
        get { self[AutoRotatingContentRotationKey.self] }
        set { self[AutoRotatingContentRotationKey.self] = newValue }
    }
    
    /// How content left where it is by the system's turn moves in the nearest enclosing `AutoRotatingView` that can leave it, or nil if there's none.
    var fuAutoRotatingHeldBehavior: FUSystemRotationBehavior? {
        get { self[AutoRotatingHeldBehaviorKey.self] }
        set { self[AutoRotatingHeldBehaviorKey.self] = newValue }
    }
    
    /// The duration of the system's turn while a ``RotationLockingHost`` turns its content back in step with it, or nil.
    var fuCounterRotationDuration: TimeInterval? {
        get { self[CounterRotationDurationKey.self] }
        set { self[CounterRotationDurationKey.self] = newValue }
    }
}

private struct AutoRotatingHeldBehaviorKey: EnvironmentKey {
    static let defaultValue: FUSystemRotationBehavior? = nil
}

private struct CounterRotationDurationKey: EnvironmentKey {
    static let defaultValue: TimeInterval? = nil
}
#endif
