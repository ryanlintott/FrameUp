//
//  TurnClockTests.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-16.
//

#if os(iOS)
import SwiftUI
import UIKit
import XCTest
@testable import FrameUp

/// The turn clock's progress reaches views inside it at each step of the turn, not only at its end.
@MainActor
final class TurnClockTests: XCTestCase {
    final class Recorder {
        var progress: [Double] = []
    }

    struct ProgressProbe: View {
        let recorder: Recorder
        @Environment(\.fuTurnClock) private var clock

        var body: some View {
            let _ = recorder.progress.append(clock?.progress ?? -1)
            Color.clear
        }
    }

    struct Root: View {
        let turn: AutoRotatingTurn?
        let announcement: TurnAnnouncement
        let recorder: Recorder

        var body: some View {
            TurnClockDriver.start(turn, announcement: announcement) { _ in
                ProgressProbe(recorder: recorder)
            }
        }
    }

    /// Shows a view in a window, starts a turn, and returns the progress the view saw over the next half second.
    private func progress(for turn: (Int) -> AutoRotatingTurn) -> [Double] {
        let announcement = TurnAnnouncement()
        let recorder = Recorder()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 300, height: 600))
        let host = UIHostingController(rootView: Root(turn: nil, announcement: announcement, recorder: recorder))
        window.rootViewController = host
        window.makeKeyAndVisible()
        /// The test host has no scene to draw on, so the view is laid out by hand about once a frame.
        func runFrames(_ count: Int) {
            for _ in 0..<count {
                RunLoop.main.run(until: Date().addingTimeInterval(1.0 / 60))
                host.view.setNeedsLayout()
                host.view.layoutIfNeeded()
            }
        }
        runFrames(5)
        recorder.progress = []
        host.rootView = Root(turn: turn(announcement.nextID()), announcement: announcement, recorder: recorder)
        runFrames(30)
        window.isHidden = true
        return recorder.progress
    }

    /// Before the first turn nothing is pending, so held content is shown at once. A turn is pending from when it's announced until it's taken.
    func testPendingOnlyBetweenAnnouncementAndTurn() {
        let announcement = TurnAnnouncement()
        XCTAssertFalse(TurnClock(turn: nil, progress: 1, announcement: announcement).isAnnouncedTurnPending)
        let id = announcement.nextID()
        XCTAssertTrue(TurnClock(turn: nil, progress: 1, announcement: announcement).isAnnouncedTurnPending)
        let turn = AutoRotatingTurn(id: id, kind: .contentOnly, interfaceOrientation: nil, animation: nil)
        XCTAssertFalse(TurnClock(turn: turn, progress: 1, announcement: announcement).isAnnouncedTurnPending)
    }

    func testSystemTurnProgressSteps() {
        let values = progress { id in
            let startTime = CACurrentMediaTime()
            return AutoRotatingTurn(id: id, kind: .system(angle: .degrees(90), startTime: startTime, duration: 0.3), interfaceOrientation: .landscapeLeft, animation: .systemTurn(startTime: startTime, duration: 0.3))
        }
        let steps = values.filter { $0 > 0.01 && $0 < 0.99 }
        XCTAssertGreaterThan(steps.count, 3, "progress seen: \(values)")
        XCTAssertEqual(values.last, 1)
    }

    func testOwnTurnProgressSteps() {
        let values = progress { id in
            AutoRotatingTurn(id: id, kind: .contentOnly, interfaceOrientation: nil, animation: .easeInOut(duration: 0.3))
        }
        let steps = values.filter { $0 > 0.01 && $0 < 0.99 }
        XCTAssertGreaterThan(steps.count, 3, "progress seen: \(values)")
        XCTAssertEqual(values.last, 1)
    }
}
#endif
