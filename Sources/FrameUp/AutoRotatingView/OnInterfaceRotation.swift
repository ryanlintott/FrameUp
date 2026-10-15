//
//  OnInterfaceRotation.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-14.
//

#if os(iOS)
import SwiftUI
import UIKit

/// A turn of the interface by the system, while it's under way.
internal struct InterfaceTurn: Equatable, Sendable {
    /// Counts the turns, so a turn can be told apart from the one before it.
    let id: Int
    /// The duration of the system's animation.
    let duration: TimeInterval
    /// True when the content of an `AutoRotatingView` stays still on the screen through the turn.
    let isHeldStill: Bool
}

/// An animation timed like the system's turn of the interface, measured from when the turn started rather than from when SwiftUI first draws it.
///
/// SwiftUI starts an animation's clock on the first frame it draws, which can be a few frames into the system's turn, more on the first turn, when the app lays itself out at the new size for the first time. The system's turn eases in and out (measured in iOS 27), so content that starts late lags all the way through. This animation takes its progress from the time since the turn started, so it catches up on its first frame and stays in step.
@available(iOS 17, *)
internal struct InterfaceTurnAnimation: CustomAnimation {
    /// When the turn started, from `CACurrentMediaTime()`.
    let startTime: TimeInterval
    /// The duration of the system's animation.
    let duration: TimeInterval

    func animate<V: VectorArithmetic>(value: V, time: TimeInterval, context: inout AnimationContext<V>) -> V? {
        /// How far into the turn the animation's first frame is, fixed then so the animation runs on SwiftUI's own clock from there.
        let lateness: TimeInterval
        if let storedLateness = context.state[LatenessKey.self] {
            lateness = storedLateness
        } else {
            lateness = min(max(CACurrentMediaTime() - startTime - time, 0), duration)
            context.state[LatenessKey.self] = lateness
        }
        let elapsed = time + lateness
        guard elapsed < duration else { return nil }
        return value.scaled(by: UnitCurve.easeInOut.value(at: elapsed / duration))
    }
    
    private struct LatenessKey: AnimationStateKey {
        static var defaultValue: TimeInterval? { nil }
    }
}

internal extension Animation {
    /// An animation timed like the system's turn of the interface, which started now and lasts a duration.
    static func interfaceTurn(duration: TimeInterval) -> Animation {
        if #available(iOS 17, *) {
            Animation(InterfaceTurnAnimation(startTime: CACurrentMediaTime(), duration: duration))
        } else {
            .easeInOut(duration: duration)
        }
    }
}

internal extension Angle {
    /// The turn of the interface that a transition coordinator's `targetTransform` describes.
    ///
    /// A half turn's transform doesn't say which way the system turns, and the sign of its zero component varies. The system always turns a half turn the way a positive angle describes (measured in iOS 27), so a half turn is always 180 degrees.
    init(interfaceTurn transform: CGAffineTransform) {
        let angle = Angle(radians: atan2(Double(transform.b), Double(transform.a)))
        self = abs(abs(angle.degrees) - 180) < 1 ? .degrees(180) : angle
    }
}

/// A view controller that has no view of its own to show, and passes on the system's interface rotations.
fileprivate final class InterfaceRotationViewController: UIViewController {
    var action: (Angle, UIViewControllerTransitionCoordinator) -> Void = { _, _ in }

    /// SwiftUI can hand the status bar to this view controller, which then passes it back to the SwiftUI content it's in.
    override var preferredStatusBarStyle: UIStatusBarStyle {
        parent?.preferredStatusBarStyle ?? super.preferredStatusBarStyle
    }

    override var prefersStatusBarHidden: Bool {
        parent?.prefersStatusBarHidden ?? super.prefersStatusBarHidden
    }

    override func loadView() {
        let view = UIView()
        view.isUserInteractionEnabled = false
        self.view = view
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        action(Angle(interfaceTurn: coordinator.targetTransform), coordinator)
    }
}

fileprivate struct InterfaceRotationReader: UIViewControllerRepresentable {
    let action: (Angle, UIViewControllerTransitionCoordinator) -> Void

    func makeUIViewController(context: Context) -> InterfaceRotationViewController {
        InterfaceRotationViewController()
    }

    func updateUIViewController(_ viewController: InterfaceRotationViewController, context: Context) {
        viewController.action = action
    }
}

internal extension View {
    /// Adds an action to perform when the system is about to turn the interface, with the angle of the turn and the coordinator of its animation.
    func onInterfaceRotation(_ action: @escaping (Angle, UIViewControllerTransitionCoordinator) -> Void) -> some View {
        background(InterfaceRotationReader(action: action).allowsHitTesting(false).accessibilityHidden(true))
    }
}
#endif
