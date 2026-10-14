//
//  OnInterfaceRotation.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-14.
//

#if os(iOS)
import SwiftUI
import UIKit

/// A view controller that has no view of its own to show, and passes on the system's interface rotations.
fileprivate final class InterfaceRotationViewController: UIViewController {
    var action: (Angle, UIViewControllerTransitionCoordinator) -> Void = { _, _ in }

    override func loadView() {
        let view = UIView()
        view.isUserInteractionEnabled = false
        self.view = view
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        let transform = coordinator.targetTransform
        /// The turn of the interface, the inverse of the turn that keeps a view still on the screen.
        var angle = Angle(radians: atan2(Double(transform.b), Double(transform.a)))
        if abs(abs(angle.degrees) - 180) < 1 {
            /// A half turn's transform doesn't say which way the system turns, and the sign of its zero component varies. The system always turns a half turn the way a positive angle describes (measured on iOS 27 in the simulator).
            angle = .degrees(180)
        }
        action(angle, coordinator)
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
