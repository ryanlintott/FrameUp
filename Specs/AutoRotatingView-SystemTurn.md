# AutoRotatingView during the system's turn

Status: notes (2026-10-14). Paused, left as it is.
Covers: `AutoRotatingView` with `systemRotation: .locked`, `RotationLockingHost`, and an `AutoRotatingView` nested inside a locked one. All measurements are on the iPhone 18 Pro simulator, iOS 27.0, from `simctl io recordVideo` recordings and logged `CACurrentMediaTime()` timestamps.

## Where it stands

- **Committed on `dev` (not pushed):** 7b9ef6f. A nested view works out where the enclosing content will be after the turn (`AutoRotatingContentState`, passed in the environment), and changes its orientation, frame and rotation together in one animation when the turn starts. Before, its rotation waited for the enclosing view's environment change, so it showed its new layout unturned and then turned late.
- **Uncommitted in the working tree:** `InterfaceTurnAnimation` in `OnInterfaceRotation.swift`, used for the nested view's turn on iOS 17 and later. It takes its progress from when the turn started rather than from SwiftUI's first frame, so a late first frame catches up. It works: the nested title starts one frame after the window on every turn, including the first. But it makes up for the lag rather than being tied to the system's turn. Keep it, or replace it with the UIKit approach below.
- **FrameUp example (Nested, `.locked`):** the panel holds still and the title turns with the system, in quarter and half turns. `.lockedOrientation` behaves as before: it drifts, and the half turn distorts.
- **Wordhord's BookView2:** the clasp jumps about 45 pt on the turn's first frame. The cover's contents start turning about 0.1 s after the window and end about 0.15 s after it. In a half turn they turn with the window and then flip at the end. Not fixed.

## How the timing works

- The system's turn always starts on time. Only the app's part starts late; nothing waits for it.
- `viewWillTransition` runs first. Then UIKit lays the app out at the new size. Then the coordinator's alongside blocks run. Between `viewWillTransition` and the alongside blocks: about 12–15 ms in the example, 26 ms on its first turn, and about 96 ms in Wordhord (heavy layout, 4 BookView2 instances).
- **Outer view:** its new rotation is set in the alongside block. The host then adds a `CABasicAnimation` for the counter-rotation in a later SwiftUI update, about 20 ms behind the system. The system's turn eases in, so that's under a degree and can't be seen.
- **Nested view:** its change is made with `withAnimation` in the alongside block. SwiftUI starts an animation's clock when it first draws the change, so the turn starts late and finishes late by the same amount. That's one frame in the example, two on its first turn, and about 0.1 s in Wordhord.
- **Layout gap:** the window's new size is laid out before the alongside block runs. Until then, held content is laid out in its new frame at its old rotation. A full-screen view barely shows this. In Wordhord, the held book's frame changes as the tab bar moves off the bottom, and that gap is the clasp jump.

## Tried

| Change | Result |
| --- | --- |
| Nested view predicts the enclosing rotation (7b9ef6f) | Kept. Orientation, frame and rotation change together. |
| Keep `RotationLockingViewController`'s hosted view at its old bounds until the rotation arrives | Reverted. The content moved off centre and the turn stalled. |
| Set the held rotation in `viewWillTransition` instead of the alongside block | Reverted. It fixed Wordhord's sideways clasp jump, but the example's quarter turn collapsed into the top-left with white areas, because the window hasn't resized yet at that point. |
| Start the nested view's animation in `viewWillTransition` | Reverted. It still started about 0.15 s late in Wordhord, then rushed to catch up. |
| `InterfaceTurnAnimation` reading the wall clock on every frame | Replaced. A text crossfade driven by it never finished, so the title's label kept fading in and out. The kept version fixes its offset on the first frame and runs on SwiftUI's clock after that. |

## Could still do

- **Animate rotations with UIKit inside the alongside block.** UIKit animates any UIView property changed inside `coordinator.animate(alongsideTransition:)` as part of the system's own rotation: the same start, curve and duration, however heavy the layout. That's the only way to match the system every time. SwiftUI has no API to join a UIKit transition.
  - Outer: set the hosted view's rotation transform in the alongside block instead of adding a `CABasicAnimation` from `updateUIViewController`. This is the smaller change, so try it first and check that the example's panel stays exactly still.
  - Nested: host the nested content in a UIKit view as well, and turn that view in the alongside block. SwiftUI only lays the content out, unrotated, at its new size. This means more UIKit than the package usually wants, but only the rotation moves to UIKit.
  - It fixes the lag, not the layout gap. The new layout still lands at once, and UIKit can't animate SwiftUI's layout changes smoothly: earlier tests found shapes collapse.
- **Close the layout gap.** Apply the held rotation in the first layout pass that has the new window size, for example from the host's `viewWillTransition(to:with:)` or `viewWillLayoutSubviews`. That's later than the `viewWillTransition` attempt above and earlier than the alongside block.
- **In Wordhord:** give the held book a frame that doesn't change when the tab menu moves. Fill the screen and inset inside, so the frame change doesn't show during the turn.
- **Not checked:** the iPhone Duo, iPad window resizing, a real device, and the iOS 15 and 16 fallback since 7b9ef6f.

## Tools

The scratchpad of the session that wrote this has `rec.sh` (records the simulator), `run.sh` (builds and launches the example with its console), `runwh.sh` (builds Wordhord against these sources without touching its repository), and `tools/sheet` and `tools/frame` for contact sheets and frame strips. ffmpeg on this Mac is x86 and won't run. Rotate with the Xcode MCP `DeviceInteractionSynthesize` command `orientation <name>`.
