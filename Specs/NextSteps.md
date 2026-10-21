# Next steps

Improvements noted while reworking TabMenu placement and `onSizeChange` (2026-10-09). None of these have been started.

## Measuring with a `Layout` on iOS 16 and later

`ScaledView` and `RelativePaddingViewModifier` both measure their content with `onSizeChange`, store the size in state and lay out again. On iOS 16 and later, a custom `Layout` could ask the content for its size and place it in a single pass, with no state. iOS 15 has no `Layout`, so each would keep the `onSizeChange` path there.

- **`ScaledView`**: measures the content's own size to work out the scale that fits the target frame.
- **`RelativePaddingViewModifier`**: pads the content by a fraction of its size.

## Check `RelativePaddingViewModifier`'s measurement

It measures after applying the padding (`.padding(insets).onSizeChange`), so the size it bases the padding on already includes the padding.

- In a container that proposes a fixed size, this doesn't matter: the measured size is the proposed size.
- Around content that sizes itself, such as `Text`, each measurement adds padding, which changes the size, which triggers another measurement. With a factor `f`, the size `s` settles at `t / (1 - 2f)` for content size `t`, after several layout passes, and only when `f` is below 0.5. At 0.5 or more the padding keeps growing.

Untested. Decide whether the padding is meant to be relative to the space offered or to the content, then check it in a preview with a `Text`.

## Check `AutoRotatingView(topEdges:)` and its tab bar right to left

Added 2026-10-17. The turn clock, the UIKit hold and the reworked tab bar (masked items sized to their label, the bar's depth animating with the turn, a fixed item order) were only checked left to right.

- Launch the Top Edges example right to left (`-AppleLanguages "(ar)" -AppleTextDirection YES -NSForceRightToLeftWritingDirection YES`) on an iPhone, the iPhone Duo's outer and inner screens, and an iPad.
- Check that the tab view's top faces the right edge in each orientation, that the system's bar lands on the tab view's bottom through every turn, and that the tab items are centred and keep their order without jumping.
- Do the same in Wordhord, whose covers and tab bar use the same views.

## AutoRotatingView follow-ups

Noted 2026-10-20, after replacing the turn's magic numbers ([AutoRotatingView-SystemTurn.md](AutoRotatingView-SystemTurn.md)). None of these have been started.

- **`.hold` inside a navigation stack doesn't hold.** SwiftUI places `RotationLockingHost`'s view controller in a view controller it shows in the navigation stack, and that gets a stand-in transition with no turn: identity `targetTransform`, not animated, duration 0. The host's guard skips it, so the content isn't held. The rotation reader had the same problem and now sits under the window's root view controller. The host could take the system's coordinator from the reader, through the shared `TurnAnnouncement`, instead of its own `viewWillTransition`. It was the same before the magic-number work.
- **The iPad multitasking rule isn't tested with a UIKit view controller.** `systemOrientations(in:)` follows the top view controller on iPad only when the app requires the full screen or leaves an orientation out of its Info.plist. It's unit-tested and was run on the iPad Pro 11-inch simulator, but not with an app whose own view controller limits its orientations. That needs a small test app or an example screen with a UIKit root.
- **The Fullscreen example's dashed safe-area edge jumps at the start of a turn.** On the iPhone 18 Pro simulator, turning from landscape left to portrait, the right dashed edge jumps in the first frame, then slides back into place by the end. It was the same at 44bae61, before the magic-number work. Content that turns with the interface gets its new frame and safe area at once (`LayerTurnGeometry`: only held content starts from the frame before the turn), while the system animates the window from the old size. Not confirmed as the whole cause.
- **TabMenu and SmartScrollView still use the heuristics AutoRotatingView dropped.** `TabMenuVerticalBehavior` and `SmartScrollView` read `InfoDictionary.supportedInterfaceOrientations` and the app's foreground scene (`FUInterfaceOrientation.windowScene`). They could use the view's own window and `FUInterfaceOrientation.systemOrientations(in:)`.

## Example app

- `SizeMatchingViewExample` calls `onSizeChange`, which is deprecated from visionOS 2, so it warns when the example app is built for visionOS. It could use `onGeometryChange(for:of:action:)` directly. `OnSizeChangeExample` demonstrates `onSizeChange` itself, so its warning is expected.

## Effects applied to the whole tab menu

Moved to [TabMenu-Styles.md](TabMenu-Styles.md).
