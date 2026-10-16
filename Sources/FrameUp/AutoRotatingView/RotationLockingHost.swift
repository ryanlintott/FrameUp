//
//  RotationLockingHost.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-14.
//

#if os(iOS)
import SwiftUI
import UIKit

/// The content of a ``RotationLockingHost``, which changes inside the host's own SwiftUI graph so its animations carry across.
@available(iOS 17, *)
fileprivate final class RotationLockingModel: ObservableObject {
    @Published var content: AnyView = AnyView(EmptyView())
}

@available(iOS 17, *)
fileprivate struct RotationLockingRoot: View {
    @ObservedObject var model: RotationLockingModel

    var body: some View {
        model.content
            /// Behind the content, so a touch reaches it only where nothing of the content takes the touch.
            .background(HitTestMarker())
    }
}

/// A view that fills the space behind the held content, so the host can tell where the content takes a touch.
@available(iOS 17, *)
fileprivate struct HitTestMarker: UIViewRepresentable {
    func makeUIView(context: Context) -> HitTestMarkerView {
        HitTestMarkerView()
    }

    func updateUIView(_ uiView: HitTestMarkerView, context: Context) { }
}

fileprivate final class HitTestMarkerView: UIView { }

/// A view that takes a touch only where its subviews' content does, so touches elsewhere reach the views behind it.
fileprivate final class PassThroughView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        /// Either this view or the marker behind the content means nothing of the content is at that point.
        return view === self || view is HitTestMarkerView ? nil : view
    }
}

/// The system's turn of the interface, while a ``RotationLockingHost`` turns its content in step with it.
internal struct HeldTurn: Equatable {
    /// The id of the turn, so the host turns its content once for each.
    let id: Int
    /// When the system's animation started, from `CACurrentMediaTime()`.
    let startTime: TimeInterval
    let duration: TimeInterval
    /// How far the content turns relative to the host's frame.
    let rotationChange: Angle
}

/// Hosts content that is turned to stay still on the screen while the system turns the interface.
///
/// SwiftUI can't keep an animation in step with the system's rotation, which runs outside the app. The host holds its content in a view of its own, and turns that view with a Core Animation animation that starts when the system's does and has the same timing, so the two cancel exactly on the screen.
@available(iOS 17, *)
internal struct RotationLockingHost<Content: View>: UIViewControllerRepresentable {
    /// The system's turn while it's under way and the content has taken its new rotation, or nil.
    let heldTurn: HeldTurn?
    /// True when the system has announced a turn and the content hasn't taken it yet.
    let isTurnPending: Bool
    /// The environment to pass on to the content, which a hosting controller doesn't inherit.
    let environment: EnvironmentValues
    let content: Content

    func makeUIViewController(context: Context) -> RotationLockingViewController {
        RotationLockingViewController()
    }

    func updateUIViewController(_ viewController: RotationLockingViewController, context: Context) {
        /// The interface is laid out at its new size before the turn reaches the content. Until it does, the content keeps its last layout.
        guard !isTurnPending else { return }
        viewController.heldTurn = heldTurn
        let content = AnyView(
            self.content
                /// Set inside the environment passed in, which would otherwise replace it.
                .environment(\.autoRotatingHeldTurnAnimation, heldTurn.map { .systemTurn(startTime: $0.startTime, duration: $0.duration) })
                .environment(\.self, environment)
        )
        guard let heldTurn else {
            viewController.update(content: content, transaction: context.transaction)
            return
        }
        /// Through the turn the content is laid out at each step of the turn's progress, at once.
        viewController.update(content: content, animation: nil)
        if heldTurn.id != viewController.counterRotatedTurnID {
            viewController.counterRotatedTurnID = heldTurn.id
            /// The content is shown at its new rotation, and the host turns it back to where it was and then with the system's animation to its new place. Content that keeps its rotation relative to the frame is carried by the system's rotation alone.
            if heldTurn.rotationChange != .zero {
                viewController.counterRotate(by: heldTurn.rotationChange, startTime: heldTurn.startTime, duration: heldTurn.duration)
            }
        }
    }
}

@available(iOS 17, *)
internal final class RotationLockingViewController: UIViewController {
    fileprivate let model = RotationLockingModel()
    private lazy var hostingController = UIHostingController(rootView: RotationLockingRoot(model: model))
    /// The system's turn of the interface while it's under way and the host turns the content, or nil.
    var heldTurn: HeldTurn? = nil
    /// The turn the content was last turned back for.
    var counterRotatedTurnID: Int? = nil

    /// SwiftUI can hand the status bar to this view controller, which then passes it back to the SwiftUI content it's in.
    override var preferredStatusBarStyle: UIStatusBarStyle {
        parent?.preferredStatusBarStyle ?? super.preferredStatusBarStyle
    }

    override var prefersStatusBarHidden: Bool {
        parent?.prefersStatusBarHidden ?? super.prefersStatusBarHidden
    }

    override func loadView() {
        /// The host fills the AutoRotatingView, so the content behind it can only be touched where the held content leaves room.
        let view = PassThroughView()
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
        if heldTurn != nil {
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

    /// Turns the content back by an angle, and then to where it is with the timing of the system's rotation, from when that started.
    func counterRotate(by angle: Angle, startTime: TimeInterval, duration: TimeInterval) {
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = -angle.radians
        animation.toValue = 0
        animation.isAdditive = true
        animation.duration = duration
        /// The system's rotation eases in and out (measured in iOS 27).
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        let layer = hostingController.view.layer
        /// Started when the system's turn started, so the content is as far through as the system's rotation even when it first draws a few frames late.
        animation.beginTime = layer.convertTime(startTime, from: nil)
        animation.fillMode = .backwards
        layer.add(animation, forKey: "FrameUp.counterRotation")
    }
}

#endif
