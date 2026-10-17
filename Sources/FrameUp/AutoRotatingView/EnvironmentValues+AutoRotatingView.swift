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
    /// It's also nil when the view is off. On the inner screen of a foldable iPhone it's named as that screen's interface names its orientations, so portrait is taller than it is wide on either screen.
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
    
    /// The safe area the content of the nearest enclosing `AutoRotatingView` has once its current turn is over, in the content's own frame, or no insets outside one. When the content isn't turning, it's the content's safe area.
    ///
    /// During a turn the content's safe area moves from where it was to where it's going with the turn's progress. Size something by where the safe area ends up, rather than by the safe area as it moves.
    ///
    ///     AutoRotatingView(topEdges: [.portrait: .top, .landscapeLeft: .top, .landscapeRight: .top]) {
    ///         TabBar()
    ///     }
    ///
    ///     struct TabBar: View {
    ///         @Environment(\.autoRotatingTargetSafeAreaInsets) private var targetSafeArea
    ///
    ///         var body: some View {
    ///             Color.brown
    ///                 .frame(height: 50 + targetSafeArea.bottom)
    ///                 .frame(maxHeight: .infinity, alignment: .bottom)
    ///                 .ignoresSafeArea()
    ///         }
    ///     }
    var autoRotatingTargetSafeAreaInsets: EdgeInsets {
        get { self[AutoRotatingTargetSafeAreaInsetsKey.self] }
        set { self[AutoRotatingTargetSafeAreaInsetsKey.self] = newValue }
    }
}

private struct AutoRotatingHeldTurnAnimationKey: EnvironmentKey {
    static let defaultValue: Animation? = nil
}

private struct AutoRotatingTargetSafeAreaInsetsKey: EnvironmentKey {
    static let defaultValue = EdgeInsets()
}

/// How the safe area of an `AutoRotatingView`'s content moves during its latest turn, named left to right.
internal struct SafeAreaTurn: Equatable {
    /// The safe area at this step of the turn.
    var current: EdgeInsets
    /// The safe area once the turn is over.
    var target: EdgeInsets
}

private struct SafeAreaTurnKey: EnvironmentKey {
    static let defaultValue: SafeAreaTurn? = nil
}

/// The rotation of an `AutoRotatingView`'s content relative to the interface during the latest turn.
internal struct AutoRotatingContentState: Equatable {
    /// The rotation when the turn started, or the rotation if the content isn't turning.
    var startRotation: Angle = .zero
    /// How far the content turns.
    var rotationChange: Angle = .zero
}

private struct AutoRotatingContentKey: EnvironmentKey {
    static let defaultValue = AutoRotatingContentState()
}

internal extension EnvironmentValues {
    /// The rotation of the nearest enclosing `AutoRotatingView`'s content, or a content that never turns if there's none.
    var fuAutoRotatingContent: AutoRotatingContentState {
        get { self[AutoRotatingContentKey.self] }
        set { self[AutoRotatingContentKey.self] = newValue }
    }
    
    /// How content left where it is by the system's turn moves in the nearest enclosing `AutoRotatingView` that can leave it, or nil if there's none.
    var fuAutoRotatingHeldBehavior: FUSystemRotationBehavior? {
        get { self[AutoRotatingHeldBehaviorKey.self] }
        set { self[AutoRotatingHeldBehaviorKey.self] = newValue }
    }
    
    /// How the safe area of the nearest enclosing `AutoRotatingView`'s content moves during its turn, or nil outside one.
    var fuSafeAreaTurn: SafeAreaTurn? {
        get { self[SafeAreaTurnKey.self] }
        set { self[SafeAreaTurnKey.self] = newValue }
    }
    
    /// True while the system's bar in ``fuSystemBar`` is as the nearest enclosing `AutoRotatingView`'s content saw it when its turn started, seen from where the content started, rather than the bar's new measurement seen from where it's going.
    var fuSystemBarIsTurnStart: Bool {
        get { self[SystemBarIsTurnStartKey.self] }
        set { self[SystemBarIsTurnStartKey.self] = newValue }
    }
    
    /// The interface orientations that enclosing hosts hold their content still for when the system turns the interface to them, or none outside a host.
    var fuHostHeldOrientations: Set<FUInterfaceOrientation> {
        get { self[HostHeldOrientationsKey.self] }
        set { self[HostHeldOrientationsKey.self] = newValue }
    }
}

private struct SystemBarIsTurnStartKey: EnvironmentKey {
    static let defaultValue = false
}

private struct HostHeldOrientationsKey: EnvironmentKey {
    static let defaultValue: Set<FUInterfaceOrientation> = []
}

private struct AutoRotatingHeldBehaviorKey: EnvironmentKey {
    static let defaultValue: FUSystemRotationBehavior? = nil
}
#endif
