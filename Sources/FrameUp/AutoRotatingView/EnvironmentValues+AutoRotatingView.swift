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
    
    /// An animation timed like the system's turn of the interface while the nearest enclosing `AutoRotatingView` holds its content still on the screen, or nil.
    ///
    /// Held content keeps its layout through the turn, apart from its safe area. Use this animation for any other change the turn brings, so it moves in step with the turn rather than at once.
    ///
    ///     AutoRotatingView([.portrait], systemRotation: .locked) {
    ///         Content()
    ///     }
    ///
    ///     struct Content: View {
    ///         @Environment(\.autoRotatingHeldTurnAnimation) private var heldTurnAnimation
    ///         @Environment(\.verticalSizeClass) private var verticalSizeClass
    ///
    ///         var body: some View {
    ///             Color.blue
    ///                 .padding(.top, verticalSizeClass == .compact ? 20 : 60)
    ///                 .animation(heldTurnAnimation, value: verticalSizeClass)
    ///         }
    ///     }
    var autoRotatingHeldTurnAnimation: Animation? {
        get { self[AutoRotatingHeldTurnAnimationKey.self] }
        set { self[AutoRotatingHeldTurnAnimationKey.self] = newValue }
    }
}

private struct AutoRotatingHeldTurnAnimationKey: EnvironmentKey {
    static let defaultValue: Animation? = nil
}

/// The content of an `AutoRotatingView`, and how it turns when the system turns the interface.
internal struct AutoRotatingContentState: Equatable {
    /// The rotation of the content relative to the interface.
    var rotation: Angle = .zero
    /// The orientation of the content.
    var orientation: FUInterfaceOrientation? = nil
    /// The orientations the content allows.
    var allowedOrientations: [FUInterfaceOrientation] = []
    /// True when the content changes in step with the system's turn of the interface, rather than when the device turns or not at all.
    var turnsWithInterface: Bool = false
    
    /// True when the content stays where it is on the screen while the system turns the interface, because the device turned to an orientation it doesn't allow or the one it's in already.
    func isHeldStill(deviceOrientation: FUInterfaceOrientation?) -> Bool {
        !(deviceOrientation.map(allowedOrientations.contains) ?? false) || deviceOrientation == orientation
    }
    
    /// The rotation of the content once the system has turned the interface by an angle to a new orientation.
    ///
    /// Content held still turns back by exactly as much as the interface turns. Otherwise it takes the device orientation.
    func rotation(afterInterfaceTurnBy angle: Angle, to newInterfaceOrientation: FUInterfaceOrientation, deviceOrientation: FUInterfaceOrientation?) -> Angle {
        guard turnsWithInterface else { return rotation }
        guard let deviceOrientation, !isHeldStill(deviceOrientation: deviceOrientation) else { return rotation - angle }
        return rotation.closestEquivalent(to: deviceOrientation.rotation(to: newInterfaceOrientation))
    }
}

private struct AutoRotatingContentKey: EnvironmentKey {
    static let defaultValue = AutoRotatingContentState()
}

internal extension EnvironmentValues {
    /// The content of the nearest enclosing `AutoRotatingView`, or a content that never turns if there's none.
    var fuAutoRotatingContent: AutoRotatingContentState {
        get { self[AutoRotatingContentKey.self] }
        set { self[AutoRotatingContentKey.self] = newValue }
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
