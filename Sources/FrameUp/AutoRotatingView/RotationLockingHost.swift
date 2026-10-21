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

/// How a ``RotationLockingHost`` holds its content still through one turn of the interface by the system.
internal struct RotationHold {
    /// The id of the system's turn, shared with the outermost `AutoRotatingView`.
    let turnID: Int
    let timing: SystemTurnTiming
    /// The system's turn of the interface.
    let angle: Angle
    /// The host's frame before the turn, which the content keeps until the host hands it the new one.
    let frame: LayerFrame
    /// True once the turn is over and the content has the host's new frame.
    var isReleased = false

    /// True when a turn is the system's turn this hold is for.
    func isFor(_ turn: AutoRotatingTurn?) -> Bool {
        turn?.id == turnID
    }
}

internal extension CALayer {
    /// The key of the animation that turns a held view back by the system's turn.
    static let counterRotationKey = "FrameUp.counterRotation"

    /// Turns the layer back by the system's turn of the interface, so it stays still on the screen.
    ///
    /// Animating the rotation angle, rather than the transform, turns a half turn the way the angle says. Added in the system's transaction with the system's timing, it moves with the system's animations.
    @MainActor
    func addCounterRotation(by angle: Angle, timing: SystemTurnTiming) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        setAffineTransform(CGAffineTransform(rotationAngle: -angle.radians))
        CATransaction.commit()
        let animation = timing.animation(keyPath: "transform.rotation.z")
        animation.fromValue = angle.radians
        animation.toValue = 0
        animation.isAdditive = true
        add(animation, forKey: Self.counterRotationKey)
    }
}

/// Hosts content that UIKit holds still on the screen while the system turns the interface.
///
/// The view controller keeps the content at its old size and turns it back inside the system's own animation, so the two cancel from the first frame. When the turn ends it hands over the new frame and removes the counter-rotation in one step.
@available(iOS 17, *)
internal struct RotationLockingHost<Content: View>: UIViewControllerRepresentable {
    /// The frame the host fills.
    let frame: LayerFrame
    /// The interface orientation before any turn.
    let interfaceOrientation: FUInterfaceOrientation?
    /// Shared with the outermost `AutoRotatingView`, so the hold and the turn have the same id.
    let announcement: TurnAnnouncement?
    /// The interface orientations the host holds its content still for.
    let heldOrientations: Set<FUInterfaceOrientation>
    /// An animation timed like the system's turn while it's under way and the content is held, or nil.
    let heldTurnAnimation: Animation?
    /// The environment to pass on to the content, which a hosting controller doesn't inherit.
    let environment: EnvironmentValues
    /// The content, laid out for the host's hold, or nil when it isn't holding.
    let content: (RotationHold?) -> Content

    func makeUIViewController(context: Context) -> RotationLockingViewController {
        RotationLockingViewController()
    }

    func updateUIViewController(_ viewController: RotationLockingViewController, context: Context) {
        viewController.frame = frame
        viewController.hostInterfaceOrientation = interfaceOrientation
        viewController.announcement = announcement
        viewController.heldOrientations = heldOrientations
        viewController.isSystemTurning = heldTurnAnimation != nil
        viewController.makeContent = { [content, heldTurnAnimation, environment] hold in
            AnyView(
                content(hold)
                    /// Set inside the passed environment, which would otherwise replace it.
                    .environment(\.autoRotatingHeldTurnAnimation, heldTurnAnimation)
                    .environment(\.self, environment)
            )
        }
        viewController.updateContent(transaction: context.transaction)
    }
}

@available(iOS 17, *)
internal final class RotationLockingViewController: UIViewController {
    fileprivate let model = RotationLockingModel()
    private lazy var hostingController = UIHostingController(rootView: RotationLockingRoot(model: model))
    /// The frame the host fills, as of its latest update.
    var frame: LayerFrame? = nil
    var hostInterfaceOrientation: FUInterfaceOrientation? = nil
    var announcement: TurnAnnouncement? = nil
    var heldOrientations: Set<FUInterfaceOrientation> = []
    /// True while the system's turn is under way and the content is held.
    var isSystemTurning = false
    /// Builds the content for a hold, from the host's latest update.
    var makeContent: (RotationHold?) -> AnyView = { _ in AnyView(EmptyView()) }
    /// The latest hold, or nil before the first.
    private var hold: RotationHold? = nil

    /// True while the host holds its content still through the system's turn.
    private var isHolding: Bool {
        hold.map { !$0.isReleased } ?? false
    }

    /// Passes the status bar back to the SwiftUI content this view controller is in.
    override var preferredStatusBarStyle: UIStatusBarStyle {
        parent?.preferredStatusBarStyle ?? super.preferredStatusBarStyle
    }

    override var prefersStatusBarHidden: Bool {
        parent?.prefersStatusBarHidden ?? super.prefersStatusBarHidden
    }

    override func loadView() {
        /// Lets touches through to the content behind wherever the held content doesn't take them.
        let view = PassThroughView()
        view.backgroundColor = .clear
        self.view = view
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        /// The content gets its safe area from the AutoRotatingView, turned with it.
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
        if isHolding {
            /// Keeps its size from before the turn until the turn is over.
        } else if isSystemTurning {
            /// Laid out at once, as SwiftUI lays it out at each step of the turn.
            UIView.performWithoutAnimation {
                hostedView.bounds = CGRect(origin: .zero, size: view.bounds.size)
                hostedView.layoutIfNeeded()
            }
        } else {
            /// Changes size with the system's animation, as content outside a host does.
            hostedView.bounds = CGRect(origin: .zero, size: view.bounds.size)
        }
        /// Stays on this view's centre, which the system turns the interface around.
        hostedView.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        /// A turn that starts before the last one is over takes over from it.
        if isHolding {
            release()
        }
        let angle = Angle(interfaceTurn: coordinator.targetTransform)
        /// A resize without a turn, or a change without an animation, takes the new layout at once.
        guard coordinator.isAnimated, coordinator.transitionDuration > 0, abs(angle.degrees) > 1,
              let frame, let announcement,
              let rotation = FUInterfaceRotation(exactly: angle),
              let newOrientation = (hostInterfaceOrientation ?? view.window?.windowScene.flatMap(FUInterfaceOrientation.init(windowScene:)))?.rotated(by: rotation),
              heldOrientations.contains(newOrientation)
        else { return }
        let systemTurn = announcement.systemTurn(for: coordinator)
        let hold = RotationHold(turnID: systemTurn.id, timing: systemTurn.timing, angle: angle, frame: frame)
        /// Set before the system lays the interface out at its new size.
        self.hold = hold
        let isAnimated = coordinator.animate(alongsideTransition: { [weak self] _ in
            guard let self else { return }
            hold.timing.measure(in: view)
            counterRotate(hold)
        })
        guard isAnimated else {
            hold.timing.begin()
            self.hold = nil
            return
        }
        updateContent(transaction: Transaction())
    }

    /// Updates the content. While it's held or the system turns, it changes without an animation and is laid out at once.
    func updateContent(transaction: Transaction) {
        let content = makeContent(hold)
        guard isHolding || isSystemTurning else {
            withTransaction(transaction) {
                model.content = content
            }
            return
        }
        UIView.performWithoutAnimation {
            withAnimation(nil) {
                model.content = content
            }
            hostingController.view.setNeedsLayout()
            hostingController.view.layoutIfNeeded()
        }
    }

    /// Turns the content back by the system's turn, and releases the hold when the counter-rotation ends.
    ///
    /// The transition's completion can run as a half turn starts, so the hold waits for the counter-rotation's own transaction instead.
    private func counterRotate(_ hold: RotationHold) {
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            self?.release(hold)
        }
        /// A UIKit animation of the transform would otherwise replace the counter-rotation.
        UIView.performWithoutAnimation {
            hostingController.view.layer.addCounterRotation(by: hold.angle, timing: hold.timing)
        }
        CATransaction.commit()
    }

    /// Releases a hold, unless another has taken over from it.
    private func release(_ hold: RotationHold) {
        guard isHolding, self.hold?.turnID == hold.turnID else { return }
        release()
    }

    /// Gives the content its new frame and takes the counter-rotation off in one transaction, so nothing moves on the screen.
    private func release() {
        hold?.isReleased = true
        let hostedView = hostingController.view!
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        UIView.performWithoutAnimation {
            withAnimation(nil) {
                model.content = makeContent(hold)
            }
            hostedView.layer.removeAnimation(forKey: CALayer.counterRotationKey)
            hostedView.transform = .identity
            hostedView.bounds = CGRect(origin: .zero, size: view.bounds.size)
            hostedView.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
            hostedView.setNeedsLayout()
            hostedView.layoutIfNeeded()
        }
        CATransaction.commit()
    }
}

#endif
