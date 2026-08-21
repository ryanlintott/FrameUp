# Changelog

## [Unreleased]

### Changed

- Raised minimum Swift version to 6.0 and minimum platform versions to iOS 15, macOS 12, watchOS 9, tvOS 15, and visionOS 1, meeting the minimum deployment versions required by Xcode 27.
- Extended `WidgetFamily`/`WidgetSize` support to visionOS, including the new `extraLargePortrait` size and widget family.
- Consolidated the package, example app, and tests into a single Xcode workspace located under `Example/`.
- Reorganized the example app's Xcode project groups into folders and removed the unused Frameworks group.
- Updated the README, removing the Twitter link in favour of Bluesky.

### Breaking Changes

- Removed the deprecated `HFlowLegacy` and `VFlowLegacy`; use `HFlow().forEach` and `VFlow().forEach` instead.
- Removed the deprecated `VGridMasonry`; use `VMasonry().forEach` instead.
- Removed the deprecated `FlowContentSizeKey`; use `FULayoutSizeKey` instead.
- Made `rotation3DEffect(_:axis:anchor:anchorZ:perspective:backsideFlip:back:)` unavailable on visionOS. Use `perspectiveRotationEffect(_:axis:anchor:anchorZ:perspective:backsideFlip:back:)` for a flat perspective effect or `rotation3DEffect(_:axis:anchor:backsideFlip:thickness:back:)` for a true 3D rotation.
- Added `WidgetSize.extraLargePortrait`, which requires exhaustive switches over `WidgetSize` to handle the new case.

### Fixed

- `HMasonry` had its horizontal and vertical spacing swapped: row heights were computed from `horizontalSpacing` and views within a row were spaced by `verticalSpacing`. This also affected `HMasonryLayout`.
- `HFlow` hashed only its alignment, so `AnyFULayout` treated two `HFlow`s that differed in spacing or max width as equal and skipped the relayout.
- `SmartScrollView` now applies `@ViewBuilder` to its content closure so it accepts more than one view.
- `justifiedByHairSpaces` ignored `justifyLastLine` for any text containing a line break.
- The visionOS `rotation3DEffect(_:axis:anchor:backsideFlip:thickness:back:)` never forwarded `backsideFlip`, so it was always `.automatic`. This also made `FlippingView(backsideFlip:)` inert on visionOS.
- `WidgetFamily.size` returned `.extraLarge` for `.systemExtraLargePortrait` instead of `.extraLargePortrait`.
- `ScaledContainerRelativeShape` folded the rect origin into its width and height, so it only scaled correctly for a rect at the origin.
- Corrected `WidgetSize.minimumSize` and `maximumSize`, which had drifted from the per-device size tables. They now list the smallest and largest frame across every device that supports the size, using the iPad design canvas rather than the Home Screen frame, and falling back to smallest or largest area where no candidate wins on both axes. `.accessoryInline` minimum was 234x26 and is now 225x26; `.extraLarge` minimum was the 540x260 iPad Home Screen frame and is now the 450x338 visionOS frame; `.accessoryRectangular` maximum was 172x76 and is now the 191x81.5 Apple Watch frame.

### Documentation

- Fixed `Text(item.value)` in every layout example; `item` is a `String`.
- Corrected README examples that named the wrong type or parameter: `TabMenuView`, `TagView` in the `TagViewForScrollView` section, `VFlow(maxWidth:)`, `HMasonry(columns:)`, `LayoutFromtFULayout`, `rotation3DEffect` without its required `axis:`, and the `.forEach()` example.
- Corrected the deprecation versions listed throughout the README; watchOS and tvOS listed their introduced versions rather than their deprecated ones.
- Fixed doc comments that described the wrong axis or the wrong default: `VMasonry`, `HMasonry`, `HMasonryLayout`, `VStackFULayout`, `BacksideFlip.vertical`, `SmartScrollView`, `FULayoutRow`, `FULayoutColumn`, and `FUInterfaceOrientation`.
- Fixed two broken README anchor links.

### Added

- Added GitHub Actions workflows to test Swift 6 compatibility and build on the latest Swift across all supported platforms.
- Enabled Swift Package Index to automatically build DocC documentation.
- Added the missing watchOS example app scheme.
- Added a DocC documentation catalog with a landing page that curates the public API into topic groups.

## [0.9.11]

See [releases](https://github.com/ryanlintott/FrameUp/releases) for changes prior to this version.

[Unreleased]: https://github.com/ryanlintott/FrameUp/compare/0.9.11...HEAD
[0.9.11]: https://github.com/ryanlintott/FrameUp/releases/tag/0.9.11
