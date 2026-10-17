#if os(iOS)
import SwiftUI
import Testing
import UIKit
@testable import FrameUp

/// A held view is turned back by the system's turn with UIKit's own animation of its transform, which has to go the opposite way to the system's.
@MainActor
struct CounterRotationTests {
    /// The view's rotation in degrees halfway through a one second animation to a transform, and how long the animation took to finish.
    func animate(to transform: CGAffineTransform) async -> (midway: Double, finished: TimeInterval) {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        window.addSubview(view)
        window.isHidden = false
        let start = CACurrentMediaTime()
        var finished: TimeInterval = 0
        UIView.animate(withDuration: 1, delay: 0, options: .curveEaseInOut) {
            /// The host releases its hold from a nested transaction's completion, which waits for the animation.
            CATransaction.begin()
            CATransaction.setCompletionBlock { finished = CACurrentMediaTime() - start }
            view.transform = transform
            CATransaction.commit()
        }
        CATransaction.flush()
        try? await Task.sleep(for: .milliseconds(500))
        let midway = view.layer.presentation()!.affineTransform()
        try? await Task.sleep(for: .milliseconds(700))
        return (atan2(Double(midway.b), Double(midway.a)) * 180 / .pi, finished)
    }

    /// The system turns a half turn the positive way, so the content turns back the negative way.
    @Test func halfTurnGoesBackTheNegativeWay() async {
        let result = await animate(to: CGAffineTransform(counterTurning: .degrees(180)))
        #expect(result.midway < -45 && result.midway > -135)
        #expect(result.finished > 0.9 && result.finished < 1.15)
    }

    @Test(arguments: [90.0, -90.0])
    func quarterTurnGoesBackTheShortWay(degrees: Double) async {
        let result = await animate(to: CGAffineTransform(counterTurning: .degrees(degrees)))
        #expect(result.midway * degrees < 0)
        #expect(abs(result.midway) > 20 && abs(result.midway) < 70)
    }

    /// A half turn's transform falls a millionth of a radian short, which nothing on the screen shows.
    @Test func halfTurnEndsAtAHalfTurn() {
        let transform = CGAffineTransform(counterTurning: .degrees(180))
        #expect(abs(transform.a + 1) < 1e-9)
        #expect(abs(transform.b) < 1e-5)
    }
}
#endif
