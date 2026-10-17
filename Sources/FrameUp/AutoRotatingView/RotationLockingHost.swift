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
    /// The id of the system's turn, which the outermost `AutoRotatingView` gives the same turn.
    let turnID: Int
    let duration: TimeInterval
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

    /// Turns the layer back by the system's turn of the interface, so it stays still on the screen while the system turns it.
    ///
    /// The layer takes its final transform at once, and an additive animation of its rotation turns it from where it was. Animating the rotation angle, rather than the transform, takes a half turn the way the angle says (the system turns a half turn the positive way, measured in iOS 27) and keeps the layer exactly in step with the system's rotation, which eases in and out (measured in iOS 27). Added in the same transaction as the system's animations, the animation starts with them.
    func addCounterRotation(by angle: Angle, duration: TimeInterval) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        setAffineTransform(CGAffineTransform(rotationAngle: -angle.radians))
        CATransaction.commit()
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = angle.radians
        animation.toValue = 0
        animation.isAdditive = true
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        add(animation, forKey: Self.counterRotationKey)
    }
}

/// Hosts content that is turned to stay still on the screen while the system turns the interface.
///
/// SwiftUI can't keep an animation in step with the system's rotation, which runs outside the app, and its updates arrive after the rotation has started. The host's view controller hears of the turn from UIKit when the system announces it, and holds its content itself: it keeps the content's view at its size from before the turn, and turns it back in the system's own animation, so the two cancel exactly on the screen from the first frame. Once the turn is over it gives the content its new frame, lays it out, and takes the counter-rotation off in one step, so nothing moves on the screen.
///
/// Inside the held view, anything that moves with the turn, such as the safe area or an `AutoRotatingView` that turns, moves on the turn clock.
@available(iOS 17, *)
internal struct RotationLockingHost<Content: View>: UIViewControllerRepresentable {
    /// The frame the host fills.
    let frame: LayerFrame
    /// The interface orientation before any turn.
    let interfaceOrientation: FUInterfaceOrientation?
    /// What the outermost `AutoRotatingView` knows of the system's turns, so the host's hold and the turn have the same id.
    let announcement: TurnAnnouncement?
    /// The interface orientations that the host holds its content still for when the system turns the interface to them.
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
                    /// Set inside the environment passed in, which would otherwise replace it.
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
    /// The interface orientation, and the ones the content is held still for when the system turns the interface to them.
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
        if isHolding {
            /// The content keeps its size from before the turn until the turn is over.
        } else if isSystemTurning {
            /// The content is laid out at once, outside the system's animation, as SwiftUI lays it out at each step of the turn.
            UIView.performWithoutAnimation {
                hostedView.bounds = CGRect(origin: .zero, size: view.bounds.size)
                hostedView.layoutIfNeeded()
            }
        } else {
            /// The content changes size with the system's animation when there is one, as content outside a host does.
            hostedView.bounds = CGRect(origin: .zero, size: view.bounds.size)
        }
        /// The centre moves with this view, in the system's animation when there is one, so it stays on the centre of this view as it changes size. The system turns the interface around the same point.
        hostedView.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        /// A turn that starts before the last one is over takes over from it.
        if isHolding {
            release()
        }
        let angle = Angle(interfaceTurn: coordinator.targetTransform)
        /// A window that resizes without turning, such as on an iPad, and a change with no animation, such as moving between the screens of a foldable iPhone, take the new layout at once.
        guard coordinator.isAnimated, coordinator.transitionDuration > 0, abs(angle.degrees) > 1,
              let frame, let announcement,
              let newOrientation = (hostInterfaceOrientation ?? FUInterfaceOrientation.windowScene)?.rotated(by: angle),
              heldOrientations.contains(newOrientation)
        else { return }
        let hold = RotationHold(turnID: announcement.systemTurnID(for: coordinator), duration: coordinator.transitionDuration, angle: angle, frame: frame)
        /// Set before the system lays the interface out at its new size, which this view ignores while it holds.
        self.hold = hold
        let isAnimated = coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.counterRotate(hold)
        })
        guard isAnimated else {
            self.hold = nil
            return
        }
        updateContent(transaction: Transaction())
    }

    /// Updates the content. While the content is held or the system turns, it changes without an animation and is laid out at once, outside any UIKit animation that would otherwise carry the change.
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

    /// Turns the content back by the system's turn, in step with the system's animation, so the two cancel on the screen, and releases the hold when the counter-rotation is over.
    ///
    /// The transition's completion runs as soon as a half turn starts (measured in iOS 27), so the hold ends with the counter-rotation instead, from a transaction of its own that waits for it.
    private func counterRotate(_ hold: RotationHold) {
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            self?.release(hold)
        }
        /// Inside the transition's animation, a UIKit animation of the view's transform would otherwise replace the counter-rotation.
        UIView.performWithoutAnimation {
            hostingController.view.layer.addCounterRotation(by: hold.angle, duration: hold.duration)
        }
        CATransaction.commit()
    }

    /// Releases a hold, unless another has taken over from it.
    private func release(_ hold: RotationHold) {
        guard isHolding, self.hold?.turnID == hold.turnID else { return }
        release()
    }

    /// Gives the content its new frame, lays it out, and takes the counter-rotation off, all in one transaction, so nothing moves on the screen.
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
