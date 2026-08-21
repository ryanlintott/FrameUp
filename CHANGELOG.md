# Changelog

## [1.0.0] - Unreleased

Changes since the previous versioned release, `0.9.11`.

This release raises the baseline to Swift 6 and the minimum deployment versions required by Xcode 27, extends `WidgetFamily` and `WidgetSize` support to visionOS including the new `extraLargePortrait` size, and removes the layout APIs that were deprecated in earlier releases.

Before upgrading, resolve any deprecation warnings from `0.9.11` — `HFlowLegacy`, `VFlowLegacy`, `VGridMasonry`, and `FlowContentSizeKey` are now gone. Several widget frame values and availability annotations also changed in ways that can alter results or fail to compile without a version check, so read the Breaking Changes below before moving to this version.

### Breaking Changes

- Removed the deprecated `HFlowLegacy` and `VFlowLegacy`; use `HFlow().forEach` and `VFlow().forEach` instead.
- Removed the deprecated `VGridMasonry`; use `VMasonry().forEach` instead.
- Removed the deprecated `FlowContentSizeKey`; use `FULayoutSizeKey` instead.
- Made `rotation3DEffect(_:axis:anchor:anchorZ:perspective:backsideFlip:back:)` unavailable on visionOS. Use `perspectiveRotationEffect(_:axis:anchor:anchorZ:perspective:backsideFlip:back:)` for a flat perspective effect or `rotation3DEffect(_:axis:anchor:backsideFlip:thickness:back:)` for a true 3D rotation.
- Added `WidgetSize.extraLargePortrait`, which requires exhaustive switches over `WidgetSize` to handle the new case.
- `WidgetFamily.size` and `WidgetSize.widgetFamily` now require visionOS 26 or later, the version where visionOS gained WidgetKit widgets.
- `WidgetSize.sizesForWatch(watchSize:)` now keys its frame to `.accessoryRectangular` instead of `.medium`, so `WidgetSize.medium.sizeForWatch(watchSize:)` now returns nil and `.accessoryRectangular` returns the size.

### Added

- `WidgetSize.extraLargePortrait`, the equivalent of `WidgetFamily.systemExtraLargePortrait`.
- `WidgetSize.Platform`, an enum of every Apple platform that supports widgets, with `Platform.current` for the platform currently running.
- `WidgetSize.sizesForVisionOS()` and `sizeForVisionOS()` for visionOS widget frames.
- `WidgetSize.sizesForWatch(screenSize:)` and `sizeForWatch(screenSize:)`, which find the Apple Watch case size from the screen size before looking up the frame.
- `WidgetSize.sizeForCurrentDevice()` on visionOS and watchOS, alongside the existing iOS `sizeForCurrentDevice(iPadTarget:)`.
- `WidgetSize.supportedSizesForCurrentDevice` now works on macOS, watchOS, visionOS, Mac Catalyst, and CarPlay instead of iOS only.
- A DocC documentation catalog with a landing page that curates the public API into topic groups, and a `.spi.yml` so Swift Package Index builds that documentation automatically.
- A GitHub Actions workflow that checks Swift 6.0 compatibility and runs tests and per-platform builds on the latest Swift.
- The missing watchOS example app scheme.

### Changed

- Raised the minimum Swift tools version to 6.0, so the package now builds in the Swift 6 language mode, and raised minimum platform versions to iOS 15, macOS 12, watchOS 9, and tvOS 15, meeting the minimum deployment versions required by Xcode 27. visionOS stays at 1.
- Extended `WidgetFamily`/`WidgetSize` support to visionOS, including the new `extraLargePortrait` size and widget family.
- Consolidated the package, example app, and tests into a single Xcode workspace located under `Example/`, so Swift Package Index and xcodebuild-based CI build the package across all platforms instead of resolving the wrong scheme.
- Reorganized the example app's Xcode project groups into folders and removed the unused Frameworks group.
- Updated the README, removing the Twitter link in favour of Bluesky.

### Deprecated

- `WidgetSize.supportedSizes(for device: UIUserInterfaceIdiom)`; use `WidgetSize.supportedSizesForCurrentDevice` instead.

### Fixed

- `HMasonry` had its horizontal and vertical spacing swapped: row heights were computed from `horizontalSpacing` and views within a row were spaced by `verticalSpacing`. This also affected `HMasonryLayout`.
- `HFlow` hashed only its alignment, so `AnyFULayout` treated two `HFlow`s that differed in spacing or max width as equal and skipped the relayout.
- `SmartScrollView` now applies `@ViewBuilder` to its content closure so it accepts more than one view.
- `justifiedByHairSpaces` ignored `justifyLastLine` for any text containing a line break.
- The visionOS `rotation3DEffect(_:axis:anchor:backsideFlip:thickness:back:)` never forwarded `backsideFlip`, so it was always `.automatic`. This also made `FlippingView(backsideFlip:)` inert on visionOS.
- `WidgetFamily.size` returned `.extraLarge` for `.systemExtraLargePortrait` instead of `.extraLargePortrait`. Every case is now gated on the platform and SDK that provides it rather than on whether the case exists for any platform.
- `WidgetSize.widgetFamily` returned nil for the accessory sizes on watchOS and for `.extraLarge` on macOS and visionOS. Each case is now gated by platform and OS version so it returns the right family everywhere.
- `WidgetSize.supportedSizesForCurrentDevice` was missing the accessory sizes on iPad and returned an empty array on Mac Catalyst. It now reports the correct sizes for every supported platform and OS version.
- `ScaledContainerRelativeShape` folded the rect origin into its width and height, so it only scaled correctly for a rect at the origin.
- Corrected `WidgetSize.minimumSize` and `maximumSize`, which had drifted from the per-device size tables. They now list the smallest and largest frame across every device that supports the size, using the iPad design canvas rather than the Home Screen frame, and falling back to smallest or largest area where no candidate wins on both axes. `.accessoryInline` minimum was 234x26 and is now 225x26; `.extraLarge` minimum was the 540x260 iPad Home Screen frame and is now the 450x338 visionOS frame; `.accessoryRectangular` maximum was 172x76 and is now the 191x81.5 Apple Watch frame.
- The example app's `ContentView` did not build on visionOS.

### Documentation

- Documented, on `WidgetSize` and on every `sizeFor`/`sizesFor` lookup, which widget sizes a platform supports but FrameUp has no measured frame for yet, and that `minimumSize` and `maximumSize` can be used as a fallback.
- Corrected numerous README and doc comment errors, including `Text(item.value)` in every layout example, wrong type and parameter names, out-of-date deprecation versions, descriptions naming the wrong axis or default, and two broken README anchor links.

## [0.9.11] - 2025-05-06

See [releases](https://github.com/ryanlintott/FrameUp/releases) for changes prior to this version.

[Unreleased]: https://github.com/ryanlintott/FrameUp/compare/1.0.0...HEAD
[1.0.0]: https://github.com/ryanlintott/FrameUp/compare/0.9.11...1.0.0
[0.9.11]: https://github.com/ryanlintott/FrameUp/releases/tag/0.9.11
