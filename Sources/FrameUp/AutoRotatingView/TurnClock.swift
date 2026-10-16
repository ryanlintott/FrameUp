//
//  TurnClock.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-16.
//

#if os(iOS)
import SwiftUI

/// A change of orientation that every `AutoRotatingView` inside the outermost one makes together.
///
/// Only the outermost `AutoRotatingView` listens for the device and the system. It starts each turn, and every `AutoRotatingView` inside it takes the same turn, so they all move on one clock.
internal struct AutoRotatingTurn: Equatable {
    enum Kind: Equatable {
        /// The system turns the interface by an angle, with its own animation that starts at `startTime`, from `CACurrentMediaTime()`.
        case system(angle: Angle, startTime: TimeInterval, duration: TimeInterval)
        /// The device turned to an orientation the system is about to turn the interface to. Content that changes as the device turns changes at once, and the system's rotation carries it.
        case device
        /// The content turns on its own, as the system doesn't turn the interface.
        case own
        /// The interface has arrived on another screen of a foldable iPhone, without an animation.
        case screen
    }

    /// Counts the turns, so each one can be told apart from the one before.
    let id: Int
    let kind: Kind
    /// The interface orientation the turn is to, or nil when it doesn't change.
    let interfaceOrientation: FUInterfaceOrientation?
    /// The animation that carries the turn's progress, or nil for a turn that happens at once.
    let animation: Animation?
}

/// The turn the outermost `AutoRotatingView` started last, and how far through it is.
internal struct TurnClock: Equatable {
    /// The latest turn, or nil before the first.
    let turn: AutoRotatingTurn?
    /// How far through the turn the content is, from 0 to 1, eased like the system's rotation. It's 1 once the turn is done.
    let progress: Double
    /// What the outermost `AutoRotatingView` knows of the system's turn before its state changes.
    let announcement: TurnAnnouncement

    /// True when the system has announced a turn and the outermost `AutoRotatingView` hasn't taken it yet.
    var isAnnouncedTurnPending: Bool {
        announcement.id != turn?.id
    }

    /// True while the system's turn is under way.
    var isSystemTurning: Bool {
        guard case .system = turn?.kind else { return false }
        return progress < 1
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.turn == rhs.turn && lhs.progress == rhs.progress && lhs.announcement === rhs.announcement
    }
}

/// What the outermost `AutoRotatingView` knows of the system's turn from the moment the system announces it.
///
/// SwiftUI lays the interface out at its new size before state set when the system announces a turn reaches the view (measured in iOS 27). That layout has the new size and safe area but the old rotation. A reference keeps the turn visible to that layout, so a ``RotationLockingHost`` keeps its content as it was.
internal final class TurnAnnouncement {
    /// The id of the latest turn, taken or not.
    var id = 0
    /// The interface orientation the system's latest turn is to.
    var interfaceOrientation: FUInterfaceOrientation? = nil
    /// When the system's latest turn ends, from `CACurrentMediaTime()`.
    var endTime: TimeInterval = 0
    /// The outermost view's frame as it was last laid out before the latest turn was announced.
    var frame: LayerFrame? = nil

    /// The id for a new turn.
    func nextID() -> Int {
        id += 1
        return id
    }

    /// True while the system is turning the interface to an orientation.
    func isSystemTurning(to orientation: FUInterfaceOrientation) -> Bool {
        interfaceOrientation == orientation && CACurrentMediaTime() < endTime
    }
}

/// The size of an `AutoRotatingView`'s frame and its safe area, named left to right.
internal struct LayerFrame: Equatable {
    var size: CGSize
    var safeAreaInsets: EdgeInsets

    /// The frame as seen from content turned by an angle, matched to the nearest quarter turn.
    func rotated(by angle: Angle) -> LayerFrame {
        LayerFrame(size: size.rotated(by: angle), safeAreaInsets: safeAreaInsets.rotated(by: angle, layoutDirection: .leftToRight))
    }

    /// The frame part way to another. It's exactly the other frame once the progress reaches 1.
    func interpolated(to other: LayerFrame, progress: Double) -> LayerFrame {
        guard progress < 1 else { return other }
        guard progress > 0 else { return self }
        func mix(_ a: CGFloat, _ b: CGFloat) -> CGFloat { a + (b - a) * progress }
        return LayerFrame(
            size: CGSize(width: mix(size.width, other.size.width), height: mix(size.height, other.size.height)),
            safeAreaInsets: EdgeInsets(
                top: mix(safeAreaInsets.top, other.safeAreaInsets.top),
                leading: mix(safeAreaInsets.leading, other.safeAreaInsets.leading),
                bottom: mix(safeAreaInsets.bottom, other.safeAreaInsets.bottom),
                trailing: mix(safeAreaInsets.trailing, other.safeAreaInsets.trailing)
            )
        )
    }
}

/// How an `AutoRotatingView`'s content turns relative to its frame during the latest turn.
///
/// Rotations relative to the interface are the content's own, and an enclosing `AutoRotatingView`'s. The content turns relative to its frame by the difference, so both move on the same progress and arrive together.
internal struct LayerTurn: Equatable {
    /// The rotation of the content relative to its frame when the turn started.
    let startRotation: Angle
    /// How far the content turns relative to its frame.
    let rotationChange: Angle
    /// The content's rotation relative to the interface, passed on to any `AutoRotatingView` inside it.
    let content: AutoRotatingContentState

    /// - Parameters:
    ///   - enclosing: The enclosing content's rotation relative to the interface, and how far it turns.
    ///   - start: The content's rotation relative to the interface when the turn started.
    ///   - target: The content's rotation relative to the interface once the turn is done.
    ///   - isShortWay: True when the content turns the short way round relative to its frame. Otherwise it turns exactly as far as its own rotation and the enclosing content's say, as content held still on the screen does.
    init(enclosing: AutoRotatingContentState, start: Angle, target: Angle, isShortWay: Bool) {
        var change = (target - start) - enclosing.rotationChange
        if isShortWay {
            change = .degrees(change.degrees.remainder(dividingBy: 360))
        }
        startRotation = start - enclosing.startRotation
        rotationChange = change
        content = AutoRotatingContentState(startRotation: start, rotationChange: enclosing.rotationChange + change)
    }

    /// The rotation relative to the frame once the turn is done.
    var targetRotation: Angle {
        startRotation + rotationChange
    }

    /// The rotation relative to the frame part way through the turn.
    func rotation(progress: Double) -> Angle {
        startRotation + .degrees(rotationChange.degrees * progress)
    }
}

/// Carries the progress of the outermost `AutoRotatingView`'s latest turn to every `AutoRotatingView` inside it, laid out again at each step.
///
/// The animated value counts the turns, and the progress of the latest one is how far the value is past the one before. A new turn starts at 0, and a turn with no animation is done at once.
internal struct TurnClockDriver: ViewModifier, @preconcurrency Animatable {
    var count: Double
    let turn: AutoRotatingTurn?
    let announcement: TurnAnnouncement

    init(turn: AutoRotatingTurn?, announcement: TurnAnnouncement) {
        self.count = Double(turn?.id ?? 0)
        self.turn = turn
        self.announcement = announcement
    }

    var animatableData: Double {
        get { count }
        set { count = newValue }
    }

    func body(content: Content) -> some View {
        let progress = turn.map { min(max(count - Double($0.id - 1), 0), 1) } ?? 1
        content
            /// Turns are started without an animation, which the content keeps.
            .animation(nil, value: turn?.id)
            .environment(\.fuTurnClock, TurnClock(turn: turn, progress: progress, announcement: announcement))
    }
}

internal extension View {
    /// Starts the clock that every `AutoRotatingView` inside turns on. Only the turn's progress takes its animation.
    ///
    /// The turn's animation applies to the transaction that starts the turn, and the clock takes it off again for the content inside, which keeps the transaction's own animation, none. An environment value set inside `transaction(_:body:)` doesn't reach the content, so that can't keep the animation to the progress.
    func turnClock(_ turn: AutoRotatingTurn?, announcement: TurnAnnouncement) -> some View {
        modifier(TurnClockDriver(turn: turn, announcement: announcement))
            .animation(turn?.animation, value: turn?.id)
    }
}

/// An animation timed like the system's turn of the interface, from when the turn started rather than from when SwiftUI first draws it.
///
/// SwiftUI starts an animation's clock on the first frame it draws, which can be a few frames into the system's turn. This animation reads the time on every frame, so it's always as far through as the system's rotation, which eases in and out (measured in iOS 27).
@available(iOS 17, *)
internal struct SystemTurnAnimation: CustomAnimation {
    /// When the turn started, from `CACurrentMediaTime()`.
    let startTime: TimeInterval
    let duration: TimeInterval

    func animate<V: VectorArithmetic>(value: V, time: TimeInterval, context: inout AnimationContext<V>) -> V? {
        let elapsed = CACurrentMediaTime() - startTime
        guard elapsed < duration else { return nil }
        return value.scaled(by: UnitCurve.easeInOut.value(at: max(elapsed, 0) / duration))
    }
}

internal extension Animation {
    /// An animation timed like the system's turn of the interface, which started at a time and lasts a duration.
    static func systemTurn(startTime: TimeInterval, duration: TimeInterval) -> Animation {
        if #available(iOS 17, *) {
            Animation(SystemTurnAnimation(startTime: startTime, duration: duration))
        } else {
            .easeInOut(duration: duration)
        }
    }
}

private struct TurnClockKey: EnvironmentKey {
    static var defaultValue: TurnClock? { nil }
}

internal extension EnvironmentValues {
    /// The clock of the outermost enclosing `AutoRotatingView`, or nil outside one.
    var fuTurnClock: TurnClock? {
        get { self[TurnClockKey.self] }
        set { self[TurnClockKey.self] = newValue }
    }
}
#endif
