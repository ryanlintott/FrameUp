//
//  SystemTurnTimingTests.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-20.
//

#if os(iOS)
import SwiftUI
import Testing
import UIKit
@testable import FrameUp

/// The turn's timing is copied from the animation UIKit gives changes inside the transition, and begins when its transaction is committed.
@MainActor
struct SystemTurnTimingTests {
    @Test(arguments: [UIView.AnimationCurve.easeInOut, .easeIn, .easeOut, .linear])
    func coordinatorCurveMatchesUIKit(curve: UIView.AnimationCurve) {
        let expected: CAMediaTimingFunctionName = switch curve {
        case .easeIn: .easeIn
        case .easeOut: .easeOut
        case .linear: .linear
        default: .easeInEaseOut
        }
        let points = CAMediaTimingFunction(curve).controlPoints
        let expectedPoints = CAMediaTimingFunction(name: expected).controlPoints
        #expect(points.start == expectedPoints.start && points.end == expectedPoints.end)
    }

    /// UIKit's ease in and out is SwiftUI's.
    @available(iOS 17, *)
    @Test func easeInOutProgress() {
        let timing = SystemTurnTiming(duration: 0.3)
        timing.begin()
        let beginTime = timing.beginTime!
        for fraction in [0.1, 0.25, 0.5, 0.8] {
            let progress = timing.progress(at: beginTime + 0.3 * fraction)!
            #expect(abs(progress - UnitCurve.easeInOut.value(at: fraction)) < 0.001)
        }
        #expect(timing.progress(at: beginTime - 0.1) == 0)
        #expect(timing.progress(at: beginTime + 0.301) == nil)
    }

    /// Before its transaction is committed, the turn hasn't begun, and it's under way.
    @available(iOS 17, *)
    @Test func notBegunIsAtStart() {
        let timing = SystemTurnTiming(duration: 0.3)
        #expect(timing.progress(at: CACurrentMediaTime() + 10) == 0)
        #expect(timing.isUnderway(at: CACurrentMediaTime() + 10))
    }

    /// Measured inside a UIKit animation, the timing takes its duration and curve, and its begin time from the commit.
    @Test func measuresUIKitAnimation() async {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
        let view = UIView(frame: window.bounds)
        window.addSubview(view)
        window.isHidden = false
        let timing = SystemTurnTiming(duration: 0.3)
        let before = CACurrentMediaTime()
        UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseIn) {
            timing.measure(in: view)
        }
        #expect(timing.duration == 0.4)
        let points = timing.animation.timingFunction!.controlPoints
        let easeIn = CAMediaTimingFunction(name: .easeIn).controlPoints
        #expect(points.start == easeIn.start && points.end == easeIn.end)
        #expect(timing.beginTime == nil)
        CATransaction.flush()
        try? await Task.sleep(for: .milliseconds(100))
        let beginTime = try! #require(timing.beginTime)
        #expect(beginTime >= before && beginTime < before + 0.1)
        let counterRotation = timing.animation(keyPath: "transform.rotation.z")
        #expect(counterRotation.duration == 0.4 && counterRotation.keyPath == "transform.rotation.z" && counterRotation.delegate == nil)
        window.isHidden = true
    }
}
#endif
