#if os(iOS)
import SwiftUI
import Testing
import UIKit
@testable import FrameUp

/// A held view is turned back by the system's turn, with an animation of its rotation angle that goes the opposite way to the system's.
@MainActor
struct CounterRotationTests {
    /// The view's rotation in degrees halfway through a one second counter-rotation, and how long the transaction it was added in took to complete.
    func counterRotate(by angle: Angle) async -> (midway: Double, completed: TimeInterval) {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        window.addSubview(view)
        window.isHidden = false
        let start = CACurrentMediaTime()
        var completed: TimeInterval = 0
        /// The host releases its hold from the completion of the transaction it adds the counter-rotation in.
        CATransaction.begin()
        CATransaction.setCompletionBlock { completed = CACurrentMediaTime() - start }
        view.layer.addCounterRotation(by: angle, duration: 1)
        CATransaction.commit()
        CATransaction.flush()
        try? await Task.sleep(for: .milliseconds(500))
        let midway = view.layer.presentation()!.affineTransform()
        try? await Task.sleep(for: .milliseconds(700))
        return (atan2(Double(midway.b), Double(midway.a)) * 180 / .pi, completed)
    }

    /// The system turns a half turn the positive way, so the content turns back the negative way, and the hold lasts the whole turn.
    @Test func halfTurnGoesBackTheNegativeWay() async {
        let result = await counterRotate(by: .degrees(180))
        #expect(result.midway < -45 && result.midway > -135)
        #expect(result.completed > 0.9 && result.completed < 1.15)
    }

    @Test(arguments: [90.0, -90.0])
    func quarterTurnGoesBackTheOtherWay(degrees: Double) async {
        let result = await counterRotate(by: .degrees(degrees))
        #expect(result.midway * degrees < 0)
        #expect(abs(result.midway) > 20 && abs(result.midway) < 70)
    }
}
#endif
