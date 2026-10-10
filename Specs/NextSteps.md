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

## Example app

- `SizeMatchingViewExample` calls `onSizeChange`, which is deprecated from visionOS 2, so it warns when the example app is built for visionOS. It could use `onGeometryChange(for:of:action:)` directly. `OnSizeChangeExample` demonstrates `onSizeChange` itself, so its warning is expected.

## Effects applied to the whole tab menu

Moved to [TabMenu-Styles.md](TabMenu-Styles.md).
