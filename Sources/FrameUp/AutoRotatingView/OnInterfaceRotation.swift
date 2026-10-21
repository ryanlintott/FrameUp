//
//  OnInterfaceRotation.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-14.
//

#if os(iOS)
import SwiftUI
import UIKit

internal extension Angle {
    /// The turn of the interface that a transition coordinator's `targetTransform` describes. A half turn is always 180 degrees, the way the system turns it.
    init(interfaceTurn transform: CGAffineTransform) {
        let angle = Angle(radians: atan2(Double(transform.b), Double(transform.a)))
        self = abs(abs(angle.degrees) - 180) < 1 ? .degrees(180) : angle
    }
}

/// A view controller that passes on the system's interface rotations. It is never given a place in the view hierarchy.
fileprivate final class InterfaceRotationViewController: UIViewController {
    var action: (Angle, UIViewControllerTransitionCoordinator, UIView) -> Void = { _, _, _ in }
    /// The view in the window that keeps this view controller.
    weak var anchorView: UIView? = nil

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard let anchorView else { return }
        action(Angle(interfaceTurn: coordinator.targetTransform), coordinator, anchorView)
    }
}

/// An empty view that keeps an ``InterfaceRotationViewController`` as a child of the view controller it's in.
///
/// Added this way, rather than through a representable, the child isn't a view controller SwiftUI places in its own hierarchy, so it stays out of the status bar's way.
fileprivate final class InterfaceRotationAnchorView: UIView {
    let viewController = InterfaceRotationViewController()
    /// Performed with the window when the view moves to one.
    var windowAction: (UIWindow) -> Void = { _ in }
    /// Performed when the window scene's effective geometry changes.
    var geometryAction: () -> Void = { }
    private var geometryObservation: NSKeyValueObservation? = nil

    override init(frame: CGRect) {
        super.init(frame: frame)
        viewController.anchorView = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if let window {
            windowAction(window)
        }
        geometryObservation = nil
        if #available(iOS 16, *), let windowScene = window?.windowScene {
            geometryObservation = windowScene.observe(\.effectiveGeometry) { [weak self] _, _ in
                MainActor.assumeIsolated {
                    self?.geometryAction()
                }
            }
        }
        viewController.willMove(toParent: nil)
        viewController.removeFromParent()
        guard window != nil, let parent = enclosingViewController else { return }
        parent.addChild(viewController)
        viewController.didMove(toParent: parent)
    }

    private var enclosingViewController: UIViewController? {
        sequence(first: next, next: { $0?.next }).lazy.compactMap { $0 as? UIViewController }.first
    }
}

fileprivate struct InterfaceRotationReader: UIViewRepresentable {
    let action: (Angle, UIViewControllerTransitionCoordinator, UIView) -> Void
    let windowAction: (UIWindow) -> Void
    let geometryAction: () -> Void

    func makeUIView(context: Context) -> InterfaceRotationAnchorView {
        let view = InterfaceRotationAnchorView()
        view.isUserInteractionEnabled = false
        updateUIView(view, context: context)
        return view
    }

    func updateUIView(_ view: InterfaceRotationAnchorView, context: Context) {
        view.viewController.action = action
        view.windowAction = windowAction
        view.geometryAction = geometryAction
    }
}

internal extension View {
    /// Adds an action to perform when the system is about to turn the interface, with the angle of the turn, the coordinator of its animation, and a view in the window to measure the animation in.
    /// - Parameters:
    ///   - action: The action to perform when the system is about to turn the interface.
    ///   - windowAction: An action to perform with the view's window when it moves to one, which is after it appears.
    ///   - geometryAction: An action to perform when the window scene's effective geometry changes, such as when it moves to another screen. From iOS 16.
    func onInterfaceRotation(_ action: @escaping (Angle, UIViewControllerTransitionCoordinator, UIView) -> Void, window windowAction: @escaping (UIWindow) -> Void, geometry geometryAction: @escaping () -> Void) -> some View {
        background(InterfaceRotationReader(action: action, windowAction: windowAction, geometryAction: geometryAction).allowsHitTesting(false).accessibilityHidden(true))
    }
}
#endif
