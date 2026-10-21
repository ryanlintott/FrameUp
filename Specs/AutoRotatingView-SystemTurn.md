# AutoRotatingView during the system's turn

Status: reference notes (2026-10-20). They describe the code as it is, and the measured behaviour it relies on. The earlier version of this file, with the experiments that led here, is in git history.

## How a turn flows

- **Outermost layer only.** Only the outermost `AutoRotatingLayer` listens to the device and the system. It starts each `AutoRotatingTurn`, and every layer inside takes the same turn and moves on its `TurnClock`.
- **The turn clock.** `TurnClockDriver` animates a count of turns, and progress is how far the count is past the previous turn. A system turn's animation is `SystemTurnAnimation`, which reads `CACurrentMediaTime()` every frame against the turn's `SystemTurnTiming`, so progress matches the system's rotation however late SwiftUI draws its first frame.
- **The turn's timing.** Inside `animate(alongsideTransition:)`, `SystemTurnTiming.measure(in:)` changes a probe view's alpha and copies the animation UIKit gives it: its duration and curve, or spring. A marker animation added in the same transaction reports the begin time in `animationDidStart`. The clock and the `.hold` counter-rotation both use it.
- **Nested layers.** A nested layer takes the outermost turn in the same layout pass (`currentTurnState`) and stores it in `onChange`. It turns relative to the enclosing content (`ContentRotation`, `LayerTurn`).
- **`.hold`.** `RotationLockingHost` keeps the content at its old size and adds a counter-rotation inside `coordinator.animate(alongsideTransition:)`, so it starts in the system's own transaction. When the counter-rotation ends, it hands over the new frame and removes the counter-rotation in one transaction.

## Measured behaviour the code relies on

These were measured on the iPhone 18 Pro and iPhone Duo simulators, iOS 27.0 and 27.1. They are what the code's shorter comments refer to.

| Fact | Where it matters |
| --- | --- |
| SwiftUI lays the interface out at its new size before state set in `viewWillTransition` reaches the view. That layout has the new size and safe area but the old rotation. | `TurnAnnouncement` is a reference type, so that layout can see the turn and keep the frame from before it (`announcement.frame`). |
| Inside `animate(alongsideTransition:)`, UIKit gives a view's change a `CABasicAnimation` with control points (0.42, 0), (0.58, 1), the coordinator's `transitionDuration` (0.3 s a quarter turn, 0.6 s a half turn) and `beginTime` 0. The window's own `bounds.size` and `position` animations have the same timing. `completionCurve` is `.easeInOut`. | `SystemTurnTiming` copies the animation rather than assuming the curve. |
| The system's animations begin when the transaction is committed, 10 to 85 ms after `viewWillTransition` in the simulator. A clock started at `viewWillTransition` ran up to 0.35 of the turn ahead of the window's animated bounds. Timed from the marker's `beginTime`, it was within 0.006 at every frame. | `SystemTurnTiming.beginTime`; progress is 0 until it arrives. |
| A half turn has no window animation in the app, but a change inside it still gets UIKit's animation with the half turn's duration. | Half turns are measured the same way. Their screen rotation runs outside the app, so its start isn't measured directly. |
| `coordinator.transitionDuration` already doubles for a half turn. | Turn duration everywhere. |
| A half turn's `targetTransform` doesn't say which way it turns. The system always turns it the positive way. | `Angle(interfaceTurn:)`. |
| The transition's completion can run as soon as a half turn starts. | The host releases on its counter-rotation's own `CATransaction` completion. |
| The device orientation notification can arrive after the system's turn to that orientation has started. | `announcement.isSystemTurning(to:)` in `deviceOrientationDidChange`. |
| After a device turn to a supported orientation, the system starts its turn a few milliseconds later. It doesn't turn when a view controller doesn't support the orientation, or for upside down on an iPhone without a Home button, and no API reports either. | The 0.1 s fallback in `deviceOrientationDidChange`. |
| The hinge reports a new screen before the interface moves there, while the scene still has the old screen's orientation. The interface then moves with an unanimated transition, by which time the scene has the new orientation. The scene moves between screens exactly when the hinge status changes. | `isAwaitingScreenLayout`, the `.screen` turn, and the 0.3 s fallback in `changeScreen`. |
| `toolbarVerticalEdge` lags the turn by one layout pass. | `TurnStart.systemBar` keeps the bar from before the turn until the new measurement arrives. |
| Inside held content, the scoped `animation(_:body:)` doesn't animate. `animation(_:value:)` does. | `autoRotatingHeldTurnAnimation` docs. |
| In a reader whose layout direction differs from the app's, SwiftUI names system UI in a corner for the reader's direction but the rounded corners for the app's. | Corner insets are read in the caller's direction. |
| On a device (iPhone 18 Pro, iOS 27.0.1), the system's turn starts about 1 ms after the device orientation notification, so `.system`'s new rotation is first drawn inside UIKit's rotation animation. The window has no transform: the system turns the display while the window's bounds animate. Core Animation animates the content layer's rotation and position separately, and SwiftUI places a turned layer by its corner, so the content's centre drifts about 140 pt off the window's centre mid-turn and the animated bounds crop it. Neither a scoped `transaction` without animation nor turning a zero-size frame at the centre changed it. | `FUCounterRotationStyle.system` docs: a known limitation; `.hold` avoids it. |
| `ConcentricRectangle` and `ContainerRelativeShape` resolve against the unturned container. Setting a container shape inside `AutoRotatingView` would change the shape of style backgrounds even when nothing turns. | `AutoRotatingGeometryProxy.concentricCornerRadii`; no `containerShape` is set. |

## Known heuristics

The review on 2026-10-20 listed the values that aren't derived from the system. The main ones:

- The 0.1 s and 0.3 s fallbacks above.
- `FUInterfaceOrientation.windowScene` reads the app's foreground scene, not the view's own.
- Info.plist orientations stand in for the app's effective supported orientations.
- The fold and unfold orientation table in `ContentOrientationChoice` is an estimate.
- The 0.3 s default `animation` is a chosen default. It doesn't double for half turns.
