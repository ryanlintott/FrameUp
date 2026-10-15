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

/// Hosts content that is turned to stay still on the screen while the system turns the interface.
///
/// SwiftUI can't keep an animation in step with the system's rotation, which runs outside the app, and the system doesn't hand its timing to SwiftUI. The host holds its content in a view of its own, and turns that view back with a Core Animation animation that uses the same timing as the system's, so the two cancel exactly on the screen.
@available(iOS 17, *)
internal struct RotationLockingHost<Content: View>: UIViewControllerRepresentable {
    /// The rotation of the content relative to the host's frame.
    let rotation: Angle
    /// The system's turn of the interface while it's under way, or nil.
    let turn: InterfaceTurn?
    /// True when the system has announced a turn that holds the content still, but `turn` and `rotation` don't have it yet.
    let isTurnPending: Bool
    /// The environment to pass on to the content, which a hosting controller doesn't inherit.
    let environment: EnvironmentValues
    let content: Content

    func makeUIViewController(context: Context) -> RotationLockingViewController {
        RotationLockingViewController()
    }

    func updateUIViewController(_ viewController: RotationLockingViewController, context: Context) {
        /// The interface is laid out at its new size before the turn reaches the content. Until it does, the content keeps its last layout, so its safe area animates from where it was before the turn rather than from insets that match neither rotation.
        guard !isTurnPending else { return }
        let heldTurn = turn?.isHeldStill == true ? turn : nil
        viewController.heldTurn = heldTurn
        let content = AnyView(
            self.content
                /// Set inside the environment passed in, which would otherwise replace it.
                /// While the system turns the interface and the content stays still, the safe area moves with the system's timing.
                .environment(\.fuCounterRotationDuration, heldTurn?.duration)
                .environment(\.autoRotatingHeldTurnAnimation, heldTurn.map { .easeInOut(duration: $0.duration) })
                .environment(\.self, environment)
        )
        guard let heldTurn, heldTurn.id != viewController.counterRotatedTurnID else {
            viewController.rotation = rotation
            if heldTurn != nil {
                /// The layout changes at once, apart from the safe area, which animates on its own.
                viewController.update(content: content, animation: nil)
            } else {
                viewController.update(content: content, transaction: context.transaction)
            }
            return
        }
        /// The turn has started, but the content's new rotation arrives in a later update. Until then the content keeps its last layout, rather than briefly taking a shape that matches neither.
        guard let previousRotation = viewController.rotation, rotation != previousRotation else { return }
        viewController.rotation = rotation
        viewController.counterRotatedTurnID = heldTurn.id
        viewController.update(content: content, animation: nil)
        /// The content turns back to stay where it is. It's shown at its new rotation at once, and the host turns it back to where it was and then with the system's animation to its new place.
        viewController.counterRotate(by: rotation - previousRotation, duration: heldTurn.duration)
    }
}

@available(iOS 17, *)
internal final class RotationLockingViewController: UIViewController {
    fileprivate let model = RotationLockingModel()
    private lazy var hostingController = UIHostingController(rootView: RotationLockingRoot(model: model))
    /// The rotation of the content last shown, or nil before it's first shown.
    var rotation: Angle? = nil
    /// The system's turn of the interface while it's under way and the content stays still on the screen, or nil.
    var heldTurn: InterfaceTurn? = nil
    /// The turn the content was last turned back for.
    var counterRotatedTurnID: Int? = nil

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
