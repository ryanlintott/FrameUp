//
//  SystemTurnTiming.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-20.
//

#if os(iOS)
import SwiftUI
import UIKit

/// The timing of the system's turn of the interface: the animation UIKit gives the transition's changes, and when it began.
///
/// Shared by the outermost `AutoRotatingView` and any host taking the same turn. The turn begins when its transaction is committed, a moment after it's started.
@MainActor
internal final class SystemTurnTiming: NSObject {
    /// The animation UIKit uses for the turn, or one made from the coordinator's curve until it's measured.
    private(set) var animation: CABasicAnimation
    /// When the turn began, from `CACurrentMediaTime()`, or nil until its transaction is committed.
    private(set) var beginTime: TimeInterval? = nil
    private var isMeasured = false
    /// A view that takes UIKit's animation, kept until the turn is over.
    private var probe: UIView? = nil

    /// A timing with a duration and curve, for a turn that isn't measured.
    init(duration: TimeInterval, curve: UIView.AnimationCurve = .easeInOut) {
        animation = CABasicAnimation()
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(curve)
    }

    /// The timing the coordinator reports, until it's measured.
    convenience init(coordinator: UIViewControllerTransitionCoordinator) {
        self.init(duration: coordinator.transitionDuration, curve: coordinator.completionCurve)
    }

    var duration: TimeInterval {
        animation.duration
    }

    /// True until the turn is over, including before it begins.
    func isUnderway(at time: TimeInterval) -> Bool {
        beginTime.map { time < $0 + duration } ?? true
    }

    /// Copies the animation UIKit gives a change made inside `animate(alongsideTransition:)`, and listens for when the turn begins. Only the first call measures.
    /// - Parameter view: A view in the window that turns.
    func measure(in view: UIView) {
        guard !isMeasured else { return }
        isMeasured = true
        guard view.window != nil else {
            begin()
            return
        }
        let probe = UIView(frame: .zero)
        probe.isUserInteractionEnabled = false
        UIView.performWithoutAnimation {
            view.addSubview(probe)
        }
        probe.alpha = 0
        guard let systemAnimation = probe.layer.animation(forKey: "opacity") as? CABasicAnimation, let copy = systemAnimation.copy() as? CABasicAnimation else {
            /// Without an animation, the change happens at once.
            probe.removeFromSuperview()
            animation.duration = 0
            begin()
            return
        }
        animation = copy
        /// Added in the same transaction as UIKit's animations, so it begins with them.
        let beginMarker = CABasicAnimation(keyPath: "zPosition")
        beginMarker.duration = duration
        beginMarker.delegate = self
        probe.layer.add(beginMarker, forKey: "FrameUp.systemTurnBegin")
        self.probe = probe
    }

    /// Begins the turn now, for a change that isn't animated.
    func begin() {
        if beginTime == nil {
            beginTime = CACurrentMediaTime()
        }
    }

    /// An animation of a key path with the turn's timing, which begins with the turn when it's added in the turn's transaction.
    func animation(keyPath: String) -> CABasicAnimation {
        let copy = (animation.copy() as? CABasicAnimation) ?? CABasicAnimation()
        copy.keyPath = keyPath
        copy.delegate = nil
        copy.beginTime = 0
        copy.isRemovedOnCompletion = true
        copy.fillMode = .removed
        return copy
    }

    /// How far through the turn the system's animation is, from 0 to 1, or nil once it's over.
    @available(iOS 17, *)
    func progress(at time: TimeInterval) -> Double? {
        guard let beginTime else { return 0 }
        let elapsed = time - beginTime
        guard elapsed < duration else { return nil }
        guard elapsed > 0 else { return 0 }
        if let spring = animation as? CASpringAnimation {
            return Spring(mass: spring.mass, stiffness: spring.stiffness, damping: spring.damping).value(target: 1.0, initialVelocity: spring.initialVelocity, time: elapsed)
        }
        guard let points = animation.timingFunction?.controlPoints else { return elapsed / duration }
        return UnitCurve.bezier(startControlPoint: points.start, endControlPoint: points.end).value(at: elapsed / duration)
    }

    /// A SwiftUI animation with the turn's curve and duration, timed from SwiftUI's first frame.
    var swiftUIAnimation: Animation {
        if let spring = animation as? CASpringAnimation {
            return .interpolatingSpring(mass: spring.mass, stiffness: spring.stiffness, damping: spring.damping, initialVelocity: spring.initialVelocity)
        }
        guard let points = animation.timingFunction?.controlPoints else { return .linear(duration: duration) }
        return .timingCurve(points.start.x, points.start.y, points.end.x, points.end.y, duration: duration)
    }
}

extension SystemTurnTiming: CAAnimationDelegate {
    nonisolated func animationDidStart(_ anim: CAAnimation) {
        let beginTime = anim.beginTime
        MainActor.assumeIsolated {
            self.beginTime = self.beginTime ?? beginTime
        }
    }

    nonisolated func animationDidStop(_ anim: CAAnimation, finished: Bool) {
        MainActor.assumeIsolated {
            /// A turn removed before it began is over.
            if beginTime == nil {
                beginTime = CACurrentMediaTime() - duration
            }
            probe?.removeFromSuperview()
            probe = nil
        }
    }
}

internal extension CAMediaTimingFunction {
    /// The timing function of a UIKit animation curve.
    convenience init(_ curve: UIView.AnimationCurve) {
        switch curve {
        case .easeIn: self.init(name: .easeIn)
        case .easeOut: self.init(name: .easeOut)
        case .linear: self.init(name: .linear)
        /// UIKit's default curve.
        default: self.init(name: .easeInEaseOut)
        }
    }

    /// The two control points of the cubic Bézier curve.
    var controlPoints: (start: UnitPoint, end: UnitPoint) {
        var start = [Float](repeating: 0, count: 2)
        var end = [Float](repeating: 0, count: 2)
        getControlPoint(at: 1, values: &start)
        getControlPoint(at: 2, values: &end)
        return (UnitPoint(x: CGFloat(start[0]), y: CGFloat(start[1])), UnitPoint(x: CGFloat(end[0]), y: CGFloat(end[1])))
    }
}
#endif
