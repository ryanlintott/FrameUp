//
//  TurnClock.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-16.
//

#if os(iOS)
import SwiftUI
import UIKit

/// A change of orientation that the outermost `AutoRotatingView` starts and every one inside it takes, so they all move on one clock.
internal struct AutoRotatingTurn: Equatable {
    enum Kind: Equatable {
        /// The system turns the interface by an angle. `startTime` is from `CACurrentMediaTime()`.
        case system(angle: Angle, startTime: TimeInterval, duration: TimeInterval)
        /// The device turned to an orientation the system is about to turn the interface to.
        case device
        /// The content turns on its own, without the system.
        case contentOnly
        /// The interface has arrived on another screen of a foldable iPhone, without an animation.
        case screen
    }

    /// Counts the turns.
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
    /// How far through the turn the content is, from 0 to 1, eased.
    let progress: Double
    /// What the outermost `AutoRotatingView` knows of the system's turn before its state changes.
    let announcement: TurnAnnouncement

    /// True when the system has announced a turn that hasn't been taken yet.
    var isAnnouncedTurnPending: Bool {
        announcement.id != (turn?.id ?? 0)
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

/// What the outermost `AutoRotatingView` knows of the system's turn from the moment it's announced.
///
/// A reference type, so the layout at the new size, which comes before any state change, can see the turn.
internal final class TurnAnnouncement {
    /// The id of the latest turn.
    var id = 0
    /// The interface orientation the system's latest turn is to.
    var interfaceOrientation: FUInterfaceOrientation? = nil
    /// When the system's latest turn ends, from `CACurrentMediaTime()`.
    var endTime: TimeInterval = 0
    /// The outermost view's frame as it was last laid out before the latest turn was announced.
    var frame: LayerFrame? = nil

    private weak var systemTurnCoordinator: AnyObject? = nil
    private var systemTurnID = 0

    /// The id for a new turn.
    func nextID() -> Int {
        id += 1
        return id
    }

    /// The id of the system's turn in a transition, the same for the layer and any host, whichever asks first.
    func systemTurnID(for coordinator: UIViewControllerTransitionCoordinator) -> Int {
        if systemTurnCoordinator !== coordinator {
            systemTurnCoordinator = coordinator
            systemTurnID = nextID()
        }
        return systemTurnID
    }

    /// True while the system is turning the interface to an orientation.
    func isSystemTurning(to orientation: FUInterfaceOrientation) -> Bool {
        interfaceOrientation == orientation && CACurrentMediaTime() < endTime
    }
}

/// The size of an `AutoRotatingView`'s frame and its safe area.
internal struct LayerFrame: Equatable {
    var size: CGSize
    var safeAreaInsets: PhysicalEdgeInsets

    /// The frame as seen from content turned by an angle.
    func rotated(by angle: Angle) -> LayerFrame {
        LayerFrame(size: size.rotated(quarterTurns: angle.quarterTurns), safeAreaInsets: safeAreaInsets.rotated(quarterTurns: angle.quarterTurns))
    }

    /// The frame part way to another.
    func interpolated(to other: LayerFrame, progress: Double) -> LayerFrame {
        guard progress < 1 else { return other }
        guard progress > 0 else { return self }
        func mix(_ a: CGFloat, _ b: CGFloat) -> CGFloat { a + (b - a) * progress }
        return LayerFrame(
            size: CGSize(width: mix(size.width, other.size.width), height: mix(size.height, other.size.height)),
            safeAreaInsets: safeAreaInsets.interpolated(to: other.safeAreaInsets, progress: progress)
        )
    }
}

/// How an `AutoRotatingView`'s content turns relative to its frame during the latest turn: its own rotation in the interface less the enclosing content's.
internal struct LayerTurn: Equatable {
    /// The rotation of the content relative to its frame when the turn started.
    let startRotation: Angle
    /// How far the content turns relative to its frame.
    let rotationChange: Angle
    /// The content's rotation relative to the interface, passed on to any `AutoRotatingView` inside it.
    let contentRotation: ContentRotation

    /// - Parameters:
    ///   - enclosing: The enclosing content's rotation relative to the interface, and how far it turns.
    ///   - start: The content's rotation relative to the interface when the turn started.
    ///   - target: The content's rotation relative to the interface once the turn is done.
    ///   - isShortWay: True when the content turns the short way round relative to its frame, rather than exactly as far as the rotations say.
    init(enclosing: ContentRotation, start: Angle, target: Angle, isShortWay: Bool) {
        var change = (target - start) - enclosing.rotationChange
        if isShortWay {
            change = .degrees(change.degrees.remainder(dividingBy: 360))
        }
        startRotation = start - enclosing.startRotation
        rotationChange = change
        contentRotation = ContentRotation(startRotation: start, rotationChange: enclosing.rotationChange + change)
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

/// Animates a count of the turns, and passes the latest turn's progress, how far the count is past the one before, to its content and every `AutoRotatingView` inside. Outermost layer only.
internal struct TurnClockDriver<Content: View>: View, @preconcurrency Animatable {
    var count: Double
    let turn: AutoRotatingTurn?
    let announcement: TurnAnnouncement
    let content: (TurnClock) -> Content

    var animatableData: Double {
        get { count }
        set { count = newValue }
    }

    var body: some View {
        let progress = turn.map { min(max(count - Double($0.id - 1), 0), 1) } ?? 1
        let clock = TurnClock(turn: turn, progress: progress, announcement: announcement)
        content(clock)
            /// Turns are started without an animation, which the content keeps.
            .animation(nil, value: turn?.id)
            .environment(\.fuTurnClock, clock)
    }
}

internal extension TurnClockDriver {
    /// Starts the clock that every `AutoRotatingView` inside turns on. Only the progress takes the turn's animation; the content inside keeps none.
    static func start(_ turn: AutoRotatingTurn?, announcement: TurnAnnouncement, @ViewBuilder content: @escaping (TurnClock) -> Content) -> some View {
        TurnClockDriver(count: Double(turn?.id ?? 0), turn: turn, announcement: announcement, content: content)
            .animation(turn?.animation, value: turn?.id)
    }
}

/// An animation timed from when the system's turn started, rather than from SwiftUI's first frame, which can be a few frames later.
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
    /// An animation timed like the system's turn of the interface.
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
