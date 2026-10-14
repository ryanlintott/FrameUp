//
//  RotationLockingHost.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-14.
//

#if os(iOS)
import SwiftUI
import UIKit

/// The content of a ``RotationLockingHost`` and the values it's built from, which change inside the host's own SwiftUI graph so its animations carry across.
@available(iOS 17, *)
fileprivate final class RotationLockingModel: ObservableObject {
    @Published var content: AnyView = AnyView(EmptyView())
}

@available(iOS 17, *)
fileprivate struct RotationLockingRoot: View {
    @ObservedObject var model: RotationLockingModel

    var body: some View {
        model.content
    }
}

/// Hosts content that is turned to stay still on the screen while the system turns the interface.
///
/// SwiftUI can't keep an animation in step with the system's rotation, which runs outside the app, and the system doesn't hand its timing to SwiftUI. The host holds its content in a view of its own, and turns that view back with a Core Animation animation that uses the same timing as the system's, so the two cancel exactly on the screen.
@available(iOS 17, *)
internal struct RotationLockingHost<Content: View>: UIViewControllerRepresentable {
    /// The rotation of the content relative to the host's frame.
    let rotation: Angle
    /// The orientation of the content. When the system turns the interface and this stays the same, the content stays still on the screen.
    let contentOrientation: FUInterfaceOrientation?
    /// The orientations the content can turn to.
    let allowedOrientations: [FUInterfaceOrientation]
    /// The environment to pass on to the content, which a hosting controller doesn't inherit.
    let environment: EnvironmentValues
    let content: Content

    func makeUIViewController(context: Context) -> RotationLockingViewController {
        RotationLockingViewController()
    }

    func updateUIViewController(_ viewController: RotationLockingViewController, context: Context) {
        let holdingStillDuration = viewController.holdingStillDuration
        let content = AnyView(
            self.content
                /// Set inside the environment passed in, which would otherwise replace it.
                /// While the system turns the interface and the content stays still, the safe area moves with the system's timing.
                .environment(\.fuCounterRotationDuration, holdingStillDuration)
                .environment(\.self, environment)
        )
        let previousRotation = viewController.rotation
        let previousContentOrientation = viewController.contentOrientation
        viewController.rotation = rotation
        viewController.contentOrientation = contentOrientation
        viewController.allowedOrientations = allowedOrientations

        if let holdingStillDuration {
            let isTurningBack = previousRotation.map { rotation != $0 } ?? false && contentOrientation == previousContentOrientation
            if viewController.isAwaitingRotation && !isTurningBack {
                /// The window has its new size but the content not yet its new rotation, which arrives in a later update. The content keeps its last layout until then, rather than briefly taking a shape that matches neither.
                viewController.rotation = previousRotation
                return
            }
            viewController.isAwaitingRotation = false
            /// The layout changes at once, apart from the safe area, which animates on its own.
            viewController.update(content: content, animation: nil)
            if isTurningBack, let previousRotation {
                /// The content turns back to stay where it is. It is shown at its new rotation at once, and the host turns it back to where it was and then with the system's animation to its new place.
                viewController.counterRotate(by: rotation - previousRotation, duration: holdingStillDuration)
            }
        } else {
            viewController.update(content: content, transaction: context.transaction)
        }
    }
}

@available(iOS 17, *)
internal final class RotationLockingViewController: UIViewController {
    fileprivate let model = RotationLockingModel()
    private lazy var hostingController = UIHostingController(rootView: RotationLockingRoot(model: model))
    /// The rotation of the content last shown, or nil before it's first shown.
    var rotation: Angle? = nil
    var contentOrientation: FUInterfaceOrientation? = nil
    var allowedOrientations: [FUInterfaceOrientation] = []
    /// The duration of the system's turn of the interface while it's under way and the content stays still on the screen, or nil.
    private(set) var holdingStillDuration: TimeInterval? = nil
    /// True from the start of a turn the content is held still through until its new rotation arrives.
    var isAwaitingRotation = false

    override func loadView() {
        let view = UIView()
        view.backgroundColor = .clear
        self.view = view
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        /// The content gets its safe area from the AutoRotatingView, turned with it. UIKit can't work out the safe area of a turned view.
        hostingController.safeAreaRegions = []
        hostingController.view.backgroundColor = .clear
        hostingController.view.clipsToBounds = false
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let hostedView = hostingController.view!
        if holdingStillDuration != nil {
            /// The content is laid out at its new size at once, outside the system's animation, which would otherwise carry its layout and distort the shapes it turns back.
            UIView.performWithoutAnimation {
                hostedView.bounds = CGRect(origin: .zero, size: view.bounds.size)
                hostedView.layoutIfNeeded()
            }
        } else {
            /// The content changes size with the system's animation when there is one, as content outside a host does.
            hostedView.bounds = CGRect(origin: .zero, size: view.bounds.size)
        }
        /// The centre moves with this view, in the system's animation when there is one, so it stays on the centre of this view as it changes size.
        hostedView.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        /// The content stays where it is unless the device turns to an allowed orientation it isn't in already, as in `AutoRotatingView`.
        let deviceOrientation = UIDevice.current.orientation.interfaceOrientation
        let isTurning = deviceOrientation.map(allowedOrientations.contains) ?? false && deviceOrientation != contentOrientation
        /// A window that resizes without turning, such as on an iPad, isn't held.
        let isRotating = abs(atan2(coordinator.targetTransform.b, coordinator.targetTransform.a)) > 0.01
        guard isRotating && !isTurning else { return }
        let duration = coordinator.transitionDuration
        holdingStillDuration = duration
        isAwaitingRotation = true
        /// The coordinator's completion runs at once for a half turn (iOS 27), so the turn is treated as finished after its duration instead.
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.holdingStillDuration = nil
            self?.isAwaitingRotation = false
        }
    }

    /// Updates the content without an animation, and lays it out at once, outside any UIKit animation that would otherwise carry the change.
    func update(content: AnyView, animation: Animation?) {
        UIView.performWithoutAnimation {
            withAnimation(animation) {
                model.content = content
            }
            /// Lays the content out now, outside any UIKit animation that would otherwise carry the change.
            hostingController.view.setNeedsLayout()
            hostingController.view.layoutIfNeeded()
        }
    }

    func update(content: AnyView, transaction: Transaction) {
        withTransaction(transaction) {
            model.content = content
        }
    }

    /// Turns the content back by an angle at once, and then to where it is with the timing of the system's rotation.
    func counterRotate(by angle: Angle, duration: TimeInterval) {
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = -angle.radians
        animation.toValue = 0
        animation.isAdditive = true
        animation.duration = duration
        /// The system's rotation eases in and out (measured in iOS 27).
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        hostingController.view.layer.add(animation, forKey: "FrameUp.counterRotation")
    }
}

#endif
