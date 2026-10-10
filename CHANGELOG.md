# Changelog

## [1.0.0] - Unreleased

Changes since the previous versioned release, `0.9.11`.

This release raises the baseline to Swift 6 and the minimum deployment versions required by Xcode 27, moves the widget tools to their own package, [WidgetFrames](https://github.com/ryanlintott/WidgetFrames), and removes the layout APIs that were deprecated in earlier releases.

Before upgrading, resolve any deprecation warnings from `0.9.11` — `HFlowLegacy`, `VFlowLegacy`, `VGridMasonry`, `TagView`, `TagViewForScrollView`, and `FlowContentSizeKey` are now gone. Code that uses FrameUp's widget tools needs the WidgetFrames package, so read the Breaking Changes below before moving to this version.

### Breaking Changes

- Removed the deprecated `HFlowLegacy` and `VFlowLegacy`; use `HFlow().forEach` and `VFlow().forEach` instead.
- Removed the deprecated `VGridMasonry`; use `VMasonry().forEach` instead.
- Removed the deprecated `FlowContentSizeKey`; use `FULayoutSizeKey` instead.
- Removed the deprecated `TagView` and `TagViewForScrollView`; use `HFlowLayout` with `ForEach` instead.
- Made `rotation3DEffect(_:axis:anchor:anchorZ:perspective:backsideFlip:back:)` unavailable on visionOS. Use `perspectiveRotationEffect(_:axis:anchor:anchorZ:perspective:backsideFlip:back:)` for a flat perspective effect or `rotation3DEffect(_:axis:anchor:backsideFlip:thickness:back:)` for a true 3D rotation.
- Moved the widget tools to the [WidgetFrames](https://github.com/ryanlintott/WidgetFrames) package. `WidgetSize`, `WidgetDemoFrame`, `AccessoryInlineImage`, `WidgetRelativeShape`, `ScaledContainerRelativeShape` and the `WidgetFamily` extensions are no longer declared in FrameUp, so an app that imports both packages sees one of each. Add WidgetFrames and import it. WidgetFrames keeps the 0.9.11 members it does not have under the same name, such as `WidgetSize.sizeForiPhone(screenSize:)` and `minimumSize`, as deprecated functions that forward to their replacements. WidgetFrames measures the frames Apple's published table gets wrong, so many values differ from 0.9.11, most on iOS 26 and later.

### Added

- `tabMenu(selection:items:isShowingName:horizontalDistribution:maskedView:onReselect:onDoubleTap:)`, which places a `TabMenu` where the system would put its tab bar. On most screens that's along the bottom. On the iPhone Duo it's the system's vertical column beside the content, on either edge, stacked at the bottom of the column and clear of the camera, the status items and the hinge, squeezing the items rather than leaving the column when there isn't room. In the Duo's left split window, which names a column without a safe area for it, the menu reserves the column and moves the content over. It reads the column from SwiftUI's `toolbarVerticalEdge` and `reservedRegions`, so the column needs iOS 27.1. A `TabMenu` placed by hand stays horizontal, as before.
- `tabMenuVerticalBehavior(_:)` and `TabMenuVerticalBehavior`, modelled on `toolbarVerticalBehavior(_:)`. `.system`, the default, uses only the system's vertical column. `.automatic` also gives an iPhone in landscape a custom vertical bar against the edge away from the Dynamic Island, with the content moved over to make room; it needs iOS 16. `.disabled` keeps the menu along the bottom. It sets `toolbarVerticalBehavior` to match, but an app's own `toolbarVerticalBehavior` further out takes precedence.
- `EnvironmentValues.tabMenuVerticalEdge`, the edge of the vertical bar holding the tab menu, or nil when it runs along the bottom. `tabMenuVerticalBehavior(_:)` sets it for everything inside it. Without it, it matches `toolbarVerticalEdge`. Like that edge, it's layout-relative, while the bar keeps its physical side in a right-to-left layout.
- `TabMenuHorizontalDistribution` and `TabMenu`'s `horizontalDistribution` parameter. `.equal`, the default, shares the full width between the items as before. `.grouped(maxItemWidth:spacing:)` keeps them at a fixed width, centred as a group.
- `onDeviceScreenChange(_:)` and `FUDeviceScreen`, which report whether a view is on the outer or inner screen of a foldable iPhone, with the starting screen once the system reports it. They read the hinge through SwiftUI's `onHingeChange`, so they need iOS 27.1, and only report an actual change of screen rather than every hinge movement.
- A DocC documentation catalog with a landing page that curates the public API into topic groups, and a `.spi.yml` so Swift Package Index builds that documentation automatically.
- `LayoutFromFULayout.sizeReplacingUnspecifiedDimensions`, the size used in place of any unspecified dimension in a proposed size. Defaults to the SwiftUI 10 by 10 default and is overridden by `HFlowLayout` and `VFlowLayout` so an unspecified dimension along the flow axis means unlimited.
- A GitHub Actions workflow that checks Swift 6.0 compatibility and runs tests and per-platform builds on the latest Swift.
- The missing watchOS example app scheme.

### Changed

- `AutoRotatingView` turns in step with the system. When the system rotates the interface, the content change now joins the system's own rotation animation whatever `animation` is, so the content stays exactly level on screen through the turn; any SwiftUI animation there fell behind, up to 30 degrees with `.default`. `animation` now applies only when the content turns on its own, and its default changes from `.default` to the system's rotation animation, `.easeInOut(duration: 0.3)`, measured in the iPhone simulator.

- Raised the minimum Swift tools version to 6.0, so the package now builds in the Swift 6 language mode, and raised minimum platform versions to iOS 15, macOS 12, watchOS 9, and tvOS 15, meeting the minimum deployment versions required by Xcode 27. visionOS stays at 1.
- Consolidated the package, example app, and tests into a single Xcode workspace located under `Example/`, so Swift Package Index and xcodebuild-based CI build the package across all platforms instead of resolving the wrong scheme.
- Reorganized the example app's Xcode project groups into folders and removed the unused Frameworks group.
- Updated the README, removing the Twitter link in favour of Bluesky.
- `onSizeChange(perform:)` uses `onGeometryChange(for:of:action:)` where it's available, and is deprecated in its favour from iOS 16, macOS 13 and tvOS 16, and from watchOS 10 and visionOS 2, a version after FrameUp's minimums there.
- `splitMultilineByCharacter` binary searches for each line break instead of measuring after every character, so breaking a long unbroken word no longer costs one text measurement per character.

### Fixed

- The example app did not build for tvOS. `WidthReaderExample` used `Stepper`, which is unavailable there, and now falls back to the same plus and minus buttons the `Slider` alongside it already used.
- `HFlowLayout` and `VFlowLayout` collapsed to a single view per row or column when asked for their ideal size. `sizeThatFits` replaced an unspecified proposed dimension with the SwiftUI default of 10, so `HFlowLayout` inside `fixedSize(horizontal:)`, a horizontal `ScrollView`, or any other context that proposes no width measured itself as if only 10 points were available, reporting a size that did not match where the views were later placed. An unspecified dimension along the flow axis is now treated as unlimited, giving a single row or column.
- `HMasonry` had its horizontal and vertical spacing swapped: row heights were computed from `horizontalSpacing` and views within a row were spaced by `verticalSpacing`. This also affected `HMasonryLayout`.
- `onSizeChange(perform:)` reported a size of zero for a view containing a `safeAreaInset` with empty content. SwiftUI also passes the preference key's default value to `reduce` there, and `SizeKey` kept whichever value came last. It now ignores the default.
- `HFlow` hashed only its alignment, so `AnyFULayout` treated two `HFlow`s that differed in spacing or max width as equal and skipped the relayout.
- `SmartScrollView` now applies `@ViewBuilder` to its content closure so it accepts more than one view.
- `SmartScrollView` only grew into more space when the device rotated to one of the app's supported orientations. On a foldable iPhone it stayed at the outer screen's size after unfolding, which sends no orientation change, and at the wrong size after the inner screen rotated to an orientation missing from Info.plist, which that screen ignores. On iOS 16 and later it now measures the space its parent offers and measures again whenever that grows where space was limiting it. That covers rotation, folding, window resizing, the keyboard hiding, a parent frame growing and a sibling shrinking, without an `.id` modifier. Growth where the view had already shrunk to fit smaller content is ignored, so a stack with flexible siblings doesn't reset it repeatedly. iOS 15 keeps the orientation check.
- The `SmartScrollView` example showed a single "Hello" instead of its list of items. Both `SmartScrollView` examples now use their `.id` workaround only before iOS 16.
- `justifiedByHairSpaces` ignored `justifyLastLine` for any text containing a line break.
- `justifiedByHairSpaces` took seconds to justify any line ending in right-to-left text and produced lines many times wider than `maxWidth`. It appended hair spaces one at a time and re-measured after each, but `NSString.size(withAttributes:)` ignores trailing whitespace when a line ends in a right-to-left run, so the measured width never grew and the loop only escaped once it had appended over 10,000 hair spaces. The count is now calculated from the width of a single hair space, which also corrects justified lines coming out one hair space per word too narrow.
- The visionOS `rotation3DEffect(_:axis:anchor:backsideFlip:thickness:back:)` never forwarded `backsideFlip`, so it was always `.automatic`. This also made `FlippingView(backsideFlip:)` inert on visionOS.
- `AutoRotatingView` rotated its content on the inner screen of a foldable iPhone, where the device orientation is a quarter turn from the screen's own, so content ended up sideways. The system ignores an app's supported orientations on that screen and always follows the device, so `AutoRotatingView` now does the same: the content matches the interface and `allowedOrientations` has no effect there. The view tracks which screen it's on with `onHingeChange` (iOS 27.1). Folding back to the outer screen picks the allowed orientation nearest the device orientation, as the system does, and moving between screens is not animated.
- `AutoRotatingView` sometimes animated a 90 degree orientation change as a 270 degree rotation the other way. The angle is now accumulated, always taking the shortest path.
- `AutoRotatingView` gave its content a frame with a safe area that jumped the moment a rotation began. SwiftUI stops expanding a view into the safe area once a `rotationEffect` is applied to it, so animating content that uses `ignoresSafeArea()` would cause it to jump to a new position before animating. The content is now laid out in the full space including the safe area, with the container's own safe area, read outside the rotation where it is still correct, re-created as a real safe area region inside it and moved to the edges it meets at the content's angle. Content that ignores the safe area is edge to edge in every orientation and content that respects it stays clear of the real unsafe regions, which lie along the content's left and right edges when it is rotated a quarter turn.
- `AutoRotatingView` content drifted off the axis of rotation part way through a turn. Content sits centred in the safe area rather than in the container.
- The example app's `ContentView` did not build on visionOS.

### Documentation

- Corrected numerous README and doc comment errors, including `Text(item.value)` in every layout example, wrong type and parameter names, out-of-date deprecation versions, descriptions naming the wrong axis or default, and two broken README anchor links.

## [0.9.11] - 2025-05-06

See [releases](https://github.com/ryanlintott/FrameUp/releases) for changes prior to this version.

[Unreleased]: https://github.com/ryanlintott/FrameUp/compare/1.0.0...HEAD
[1.0.0]: https://github.com/ryanlintott/FrameUp/compare/0.9.11...1.0.0
[0.9.11]: https://github.com/ryanlintott/FrameUp/releases/tag/0.9.11
