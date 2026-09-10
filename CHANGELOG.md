# Changelog

## [1.0.0] - Unreleased

Changes since the previous versioned release, `0.9.11`.

This release raises the baseline to Swift 6 and the minimum deployment versions required by Xcode 27, corrects the widget frames wherever Apple's published values are wrong or missing, and removes the layout APIs that were deprecated in earlier releases.

Apple's [published widget specifications](https://developer.apple.com/design/human-interface-guidelines/widgets#Specifications) have not been updated since iOS 18. They have no row for the 402, 420 and 440 point wide iPhones, no accessory row for iPad, no row at all for `.extraLargePortrait`, and iOS 26 changed the frame of every iPhone widget without the table changing with it. FrameUp's frames were a faithful copy of that table and were wrong in all the same ways.

Frames that Apple does not publish, or publishes values for that no longer hold, are now measured on a real system using a widget extension built for the purpose. That covers every iPhone frame on iOS 26 and later, every iPad accessory and Lock Screen frame, and `.extraLargePortrait` on both platforms. The rest stay as Apple publishes them: the iPhone frames for iOS 18 and earlier, which measurement confirmed, the iPad system frames, of which one screen size was confirmed, and the Apple Watch and visionOS frames, which were not measured. The raw measurements are committed under `Measurements/`.

Before upgrading, resolve any deprecation warnings from `0.9.11` — `HFlowLegacy`, `VFlowLegacy`, `VGridMasonry`, `TagView`, `TagViewForScrollView`, and `FlowContentSizeKey` are now gone. Widget frame values, availability annotations, and lookup behaviour also changed in ways that can alter results or fail to compile without a version check, so read the Breaking Changes below before moving to this version.

### Breaking Changes

- Removed the deprecated `HFlowLegacy` and `VFlowLegacy`; use `HFlow().forEach` and `VFlow().forEach` instead.
- Removed the deprecated `VGridMasonry`; use `VMasonry().forEach` instead.
- Removed the deprecated `FlowContentSizeKey`; use `FULayoutSizeKey` instead.
- Removed the deprecated `TagView` and `TagViewForScrollView`; use `HFlowLayout` with `ForEach` instead.
- Made `rotation3DEffect(_:axis:anchor:anchorZ:perspective:backsideFlip:back:)` unavailable on visionOS. Use `perspectiveRotationEffect(_:axis:anchor:anchorZ:perspective:backsideFlip:back:)` for a flat perspective effect or `rotation3DEffect(_:axis:anchor:backsideFlip:thickness:back:)` for a true 3D rotation.
- Added `WidgetSize.extraLargePortrait` and `WidgetSize.accessoryCorner`, which require exhaustive switches over `WidgetSize` to handle the new cases.
- `WidgetFamily.size` and `WidgetSize.widgetFamily` now require visionOS 26 or later, the version where visionOS gained WidgetKit widgets.
- `WidgetSize.sizesForWatch(watchSize:)` now keys its frame to `.accessoryRectangular` instead of `.medium`, so `WidgetSize.medium.sizeForWatch(watchSize:)` now returns nil and `.accessoryRectangular` returns the size. Both are deprecated; look up by screen size instead.
- Every iPhone widget frame is different on iOS 26 and later. The frame lookups return measured values on those systems rather than Apple's published ones. System sizes differ by up to 14 points, and the accessory sizes by more: `.accessoryInline` on a 402 point iPhone is 342x36 where Apple publishes 234x26. iOS 18 and earlier are unchanged and were confirmed correct by measurement.
- A widget size can now have a different frame depending on where it appears. An iPad `.small` is 155x155 on the Home Screen and 152x152 on the Lock Screen. A lookup that names no placement reports the Home Screen frame for sizes that have one and the Lock Screen frame for the accessory sizes, which is what the previous lookups returned, so this only affects callers that ask for a placement explicitly.
- A screen size with no exact entry now resolves to the nearest known screen size rather than falling through to the arm for the next smaller device. This is what corrected the 402, 420, and 440 point wide iPhones, and it also means an unrecognised Apple Watch screen size returns the nearest known frame instead of no frames at all.

### Added

- `WidgetSize.frame(platform:screenSize:majorOSVersion:displayScale:placement:)` and its plural `WidgetSize.frames(...)`, one lookup for every platform in place of the per-platform ones. The platform is a parameter rather than part of the method name, so code can ask for a frame given a platform, and a parameter a platform does not vary by can be left out: macOS and visionOS take only a platform.
- `WidgetFrame`, the type those lookups return. It carries `canvasSize`, the size widget content is laid out in, `renderedSize`, the size the widget is drawn at, and `scaleFactor`, the ratio between them. The two differ only on the iPad Home Screen, which is the only place a widget is scaled, so one lookup answers what `WidgetTarget` and `scaleFactorForiPad` took three.
- `WidgetSize.frameForCurrentDevice()`, replacing `sizeForCurrentDevice`. It exists on iOS, macOS, watchOS and visionOS, each taking only the parameters that platform varies by, and macOS gains a current-device lookup it never had.
- `WidgetSize.extraLargePortrait`, the equivalent of `WidgetFamily.systemExtraLargePortrait`.
- `WidgetSize.Platform`, an enum of every Apple platform that supports widgets, with `Platform.current` for the platform currently running.
- visionOS widget frames, reached with `WidgetSize.frames(platform: .vision)`.
- Apple Watch frames keyed on screen size rather than case size, reached with `WidgetSize.frames(platform: .watch, screenSize:)`. A case size cannot identify a watch: the Ultra 2 and Ultra 3 are both 49mm and report different frames.
- `frameForCurrentDevice()` on macOS, watchOS and visionOS, where no current-device lookup existed.
- `WidgetSize.supportedSizesForCurrentDevice` now works on macOS, watchOS, visionOS, Mac Catalyst, and CarPlay instead of iOS only.
- `WidgetSize.supportedSizes(platform:majorOSVersion:)`, the answer to what a platform can show for a device other than the one running, matching `frames(platform:...)`. `supportedSizesForCurrentDevice` is now this called with the current platform, so the two cannot drift.
- macOS frames, reached with `WidgetSize.frames(platform: .mac)` and the first widget frames FrameUp has had for that platform. Apple publishes no widget specifications for macOS at all, so these are measured. A `.macCatalyst` lookup resolves to the same frames, since widgets there are hosted by macOS.
- `WidgetPlacement`, an enum of the places a widget can appear. It mirrors `WidgetKit.WidgetLocation`, which cannot be used here because it is unavailable on macOS, tvOS, and visionOS and requires iOS 17.
- `majorOSVersion`, `displayScale` and `placement` parameters on the frame lookups, so a frame can be found for a device other than the one running. Every one defaults to the running device.
- Frames for the screen sizes Apple has never published a row for: the 402, 420, and 440 point wide iPhones, and the 1032x1376 iPad that every M4 and M5 13-inch iPad Pro reports.
- Lock Screen and `.extraLargePortrait` frames for the three iPad Display Zoom screen sizes, `1192x1590`, `970x1389` and `954x1373`, which previously fell back to the nearest unzoomed iPad. Measured by turning on More Space under Settings > Developer > Display Zoom, which also confirmed every system frame Apple publishes for them.
- iPad accessory frames, which Apple publishes for no iPad at all, plus the smaller `.small` frame an iPad uses on the Lock Screen. Measured on every iPad screen size.
- `.extraLargePortrait` frames on iPhone and iPad, measured on every screen size that iOS 27 and iPadOS 27 support. Apple publishes no row for this family on any platform. On iPad both the design canvas and the smaller rendered frame are covered; the rendered frame for a 820x1180 iPad was measured from a placed widget at 600x928 pixels and the rest follow the Home Screen grid, which is exact on every published row.
- Documented that an iPad Lock Screen widget is drawn at its design canvas size rather than scaled into the Home Screen grid, confirmed by measuring placed widgets at 126x126, 304x126 and 304x304 pixels on a 820x1180 iPad. The accessory sizes and the Lock Screen `small` frame therefore have one frame rather than two, so their `renderedSize` is their `canvasSize` and their `scaleFactor` is 1.
- `WidgetSize.accessoryCorner`, the Apple Watch corner complication and the only widget size that exists on no other platform. It has no frame: a corner complication is roughly triangular rather than rectangular, and a label can curve around its frame and extend past it, so the size WidgetKit reports does not bound what it draws. It has no frame on any platform and `minimumSize` and `maximumSize` return zero. `Measurements/README.md` records why as an open question.
- Apple Watch watch face frames for `.accessoryRectangular` and `.accessoryCircular`, measured on watchOS 27. Which of the two frames each watch reports belongs to which placement was confirmed by placing the probe on the 40mm and the 44mm, the second as a prediction made in advance from the first; the 46mm and Ultra 3 rows apply the rule those established rather than having been placed themselves, and `Measurements/README.md` marks which is which. Apple publishes only Smart Stack sizes, so a complication frame existed nowhere else. The lookups take a `placement` to choose between them; with none given they report the Smart Stack frame for `.accessoryRectangular` and the watch face frame for `.accessoryCircular`, which is where each appears.
- visionOS `.accessoryCircular` and `.accessoryRectangular` frames, measured on visionOS 27 where the family arrives. Apple publishes no accessory row for visionOS. `.accessoryInline` has no case in the visionOS SDK, so it does not exist there.
- `Sendable` conformance on `WidgetSize`, `WidgetSize.Platform`, and `WidgetTarget`.
- `Measurements/`, holding every raw measurement as JSON along with how it was captured, and `WidgetSizeProbe`, the widget extension in the example app that produced them.
- A DocC documentation catalog with a landing page that curates the public API into topic groups, and a `.spi.yml` so Swift Package Index builds that documentation automatically.
- `LayoutFromFULayout.sizeReplacingUnspecifiedDimensions`, the size used in place of any unspecified dimension in a proposed size. Defaults to the SwiftUI 10 by 10 default and is overridden by `HFlowLayout` and `VFlowLayout` so an unspecified dimension along the flow axis means unlimited.
- A GitHub Actions workflow that checks Swift 6.0 compatibility and runs tests and per-platform builds on the latest Swift.
- The missing watchOS example app scheme.

### Changed

- `WidgetDemoFrame.init?(_:cornerRadius:content:)` now returns nil for a widget size the current platform and OS version cannot show, rather than building a frame whenever one exists in the tables. The two tables agree today, so no size changes behaviour; the init no longer depends on that agreement, and a test now enforces it across every platform and version. `WidgetDemoFrame.minimumSize(_:cornerRadius:content:)` still builds a frame for any size on any device, which is the way to preview `extraLarge` on an iPhone.

- Raised the minimum Swift tools version to 6.0, so the package now builds in the Swift 6 language mode, and raised minimum platform versions to iOS 15, macOS 12, watchOS 9, and tvOS 15, meeting the minimum deployment versions required by Xcode 27. visionOS stays at 1.
- Extended `WidgetFamily`/`WidgetSize` support to visionOS, including the new `extraLargePortrait` size and widget family.
- Consolidated the package, example app, and tests into a single Xcode workspace located under `Example/`, so Swift Package Index and xcodebuild-based CI build the package across all platforms instead of resolving the wrong scheme.
- Reorganized the example app's Xcode project groups into folders and removed the unused Frameworks group.
- Split the internal iPad frame table into separate design canvas and Home Screen tables, each with one labelled row per screen size matching the iPhone tables, replacing the nested unlabelled tuples that packed both targets into one row. The frames are unchanged.
- A widget size that is never scaled now reports a `renderedSize` equal to its `canvasSize` rather than nothing. That covers every platform but the iPad Home Screen, and on iPad it covers the Lock Screen sizes, which are drawn at their canvas size. The deprecated `sizeForiPad(screenSize:target: .homeScreen)` still returns nil for those.
- Updated the README, removing the Twitter link in favour of Bluesky.
- `splitMultilineByCharacter` binary searches for each line break instead of measuring after every character, so breaking a long unbroken word no longer costs one text measurement per character.

### Deprecated

- `WidgetSize.supportedSizes(for device: UIUserInterfaceIdiom)`; use `WidgetSize.supportedSizesForCurrentDevice` instead.
- The per-platform widget frame lookups, replaced by `WidgetSize.frame(platform:...)` and `frameForCurrentDevice()`. They still return exactly what they did before, so this release only warns:
  - `sizesForiPhone(screenSize:)` and `sizeForiPhone(screenSize:)`; use `frames(platform: .phone, screenSize:)` and read `canvasSize`.
  - `sizesForiPad(screenSize:target:)` and `sizeForiPad(screenSize:target:)`; use `frames(platform: .pad, screenSize:)` and read `canvasSize` or `renderedSize` instead of naming a target.
  - `sizesForWatch(watchSize:)` and `sizeForWatch(watchSize:)`; use `frames(platform: .watch, screenSize:)`. A case size cannot distinguish an Ultra 2 from an Ultra 3.
  - `scaleFactorForiPad(screenSize:)` and `scaleFactorForCurrentDevice`; use `scaleFactor` on the frame.
  - `sizeForCurrentDevice(iPadTarget:)`; use `frameForCurrentDevice()`.
  - `WidgetSize.Size`, a tuple typealias nothing in the API takes any more.
- `WidgetTarget` is no longer used by any current API. It remains only so the deprecated iPad lookups keep their signatures, and goes when they do.

### Fixed

- The example app did not build for tvOS. `WidthReaderExample` used `Stepper`, which is unavailable there, and now falls back to the same plus and minus buttons the `Slider` alongside it already used.
- `HFlowLayout` and `VFlowLayout` collapsed to a single view per row or column when asked for their ideal size. `sizeThatFits` replaced an unspecified proposed dimension with the SwiftUI default of 10, so `HFlowLayout` inside `fixedSize(horizontal:)`, a horizontal `ScrollView`, or any other context that proposes no width measured itself as if only 10 points were available, reporting a size that did not match where the views were later placed. An unspecified dimension along the flow axis is now treated as unlimited, giving a single row or column.
- `HMasonry` had its horizontal and vertical spacing swapped: row heights were computed from `horizontalSpacing` and views within a row were spaced by `verticalSpacing`. This also affected `HMasonryLayout`.
- `HFlow` hashed only its alignment, so `AnyFULayout` treated two `HFlow`s that differed in spacing or max width as equal and skipped the relayout.
- `SmartScrollView` now applies `@ViewBuilder` to its content closure so it accepts more than one view.
- `justifiedByHairSpaces` ignored `justifyLastLine` for any text containing a line break.
- `justifiedByHairSpaces` took seconds to justify any line ending in right-to-left text and produced lines many times wider than `maxWidth`. It appended hair spaces one at a time and re-measured after each, but `NSString.size(withAttributes:)` ignores trailing whitespace when a line ends in a right-to-left run, so the measured width never grew and the loop only escaped once it had appended over 10,000 hair spaces. The count is now calculated from the width of a single hair space, which also corrects justified lines coming out one hair space per word too narrow.
- The visionOS `rotation3DEffect(_:axis:anchor:backsideFlip:thickness:back:)` never forwarded `backsideFlip`, so it was always `.automatic`. This also made `FlippingView(backsideFlip:)` inert on visionOS.
- `WidgetFamily.size` returned `.extraLarge` for `.systemExtraLargePortrait` instead of `.extraLargePortrait`. Every case is now gated on the platform and SDK that provides it rather than on whether the case exists for any platform.
- `WidgetSize.widgetFamily` returned nil for the accessory sizes on watchOS and for `.extraLarge` on macOS and visionOS. Each case is now gated by platform and OS version so it returns the right family everywhere.
- `WidgetSize.supportedSizesForCurrentDevice` was missing the accessory sizes on iPad and returned an empty array on Mac Catalyst. It now reports the correct sizes for every supported platform and OS version.
- `sizeForCurrentDevice(iPadTarget:)` and `scaleFactorForCurrentDevice` returned nil on Mac Catalyst even though `sizesForMac` resolves Catalyst to the macOS frames. They now report those frames and a scale factor of 1.
- The Apple Watch Smart Stack frames were wrong for every watch newer than Apple's published table. The 42mm and 46mm Series 10 and 11 watches have no published row and resolved to one meant for a smaller watch, reporting 165x72.5 and 184x80.5 against a measured 176x72.5 and 194x80.5. The Ultra 3 reported the Ultra 2's 191x81.5 against a measured 197x84: both are 49mm, but they have different screens, so a lookup keyed on case size cannot tell them apart and `sizesForWatch(watchSize:)` still cannot. `sizesForWatch(screenSize:)` now distinguishes them. The 40mm and 44mm frames measured exactly as published and are unchanged.
- Every visionOS frame except `.small` was wrong. Apple publishes a visionOS row that FrameUp copied, and measurement shows `.medium` and `.large` are 354 wide rather than 338, and `.extraLarge` is 550x354 rather than 450x338, with `.extraLargePortrait` 354x550 rather than 338x450. visionOS 26.5 and 27.0 report identical values, so unlike the iPhone case these did not change after the table was written; the published values were never right. The measured frames form a grid of 158 point cells with a 38 point gutter, which none of the published values fit. visionOS frames now also apply from version 26, where widgets arrived, rather than from version 1.
- Every iPhone with a 402, 420, or 440 point wide screen reported the frames of a narrower phone. `sizesForiPhone` matched on ranges of screen width in a fixed order, and Apple publishes no row for any of those widths, so an iPhone 16 Pro, 17, or Air fell through to the arm meant for a 393 point screen and an iPhone 16 Pro Max or 17 Pro Max to the arm meant for 430. On iOS 18 those fall-throughs happened to give the right answer, which is why this went unnoticed; on iOS 26 they did not.
- Accessory frames were reported for iOS 15, where accessory widgets do not exist. They now apply from iOS 16.
- Added the 744x1133 iPad row that Apple publishes and FrameUp lacked. It reached the same values through the default arm, so the result is unchanged.
- `ScaledContainerRelativeShape` folded the rect origin into its width and height, so it only scaled correctly for a rect at the origin.
- `WidgetSize.minimumSize` and `maximumSize` are now derived from the frame tables instead of being listed separately, so a new measurement widens the range without a second edit. Maintained by hand they drifted out of step twice, and every measurement added during this release left them further behind: `.extraLargePortrait` reported a 338x450 maximum while the measured frames reached 378x611.33, and `.accessoryInline` reported 257x26 while iPad measures 374x36. Corrected values are `.small` minimum 141x141 to 133x133, `.accessoryCircular` minimum 68x68 to 53x53, `.accessoryRectangular` minimum 153x68 to 133x53.5, `.accessoryInline` maximum 257x26 to 374x36, and `.extraLargePortrait` 338x450 to a 305.5x470 minimum and a 378x611.33 maximum. The corrected visionOS frames then moved two more on their own, which is the derivation doing its job: `.accessoryRectangular` maximum is now the 208x79 Vision Pro frame rather than the 191x81.5 Apple Watch one, and `.extraLarge` minimum the 634.5x305.5 iPad canvas rather than the visionOS frame. The rule is unchanged: the smallest and largest frame across every device that supports the size, using the iPad design canvas rather than the Home Screen frame, choosing by area where no candidate wins on both axes.
- `AutoRotatingView` sometimes animated a 90 degree orientation change as a 270 degree rotation the other way. The angle is now accumulated, always taking the shortest path.
- `AutoRotatingView` gave its content a frame with a safe area that jumped the moment a rotation began. SwiftUI stops expanding a view into the safe area once a `rotationEffect` is applied to it, so animating content that uses `ignoresSafeArea()` would cause it to jump to a new position before animating. The content is now laid out in the full space including the safe area, and the real safe area, read outside the rotation, is re-created inside and rotated to match the content. Content that ignores the safe area is edge to edge in every orientation, content that respects it stays clear of the real unsafe regions. The content centre is held at the frame centre for the whole rotation where it previously jumped on the first frame. The re-created safe area turns with the content rather than interpolating between the positions it rests in at either end. Interpolating moves the centre of the safe area in a straight line between two points on a circle, which drags content off the axis of rotation part way through a turn and is most obvious in a half turn, where the two ends are on opposite sides and the line between them passes through the centre. Measured on a marker at the centre of the content's safe area through a half turn, that drift was up to 84 points; it is now 0.4, the width of a rounding error.
- The example app's `ContentView` did not build on visionOS.

### Documentation

- Documented, on `WidgetSize` and on every `sizeFor`/`sizesFor` lookup, which widget sizes a platform supports but FrameUp has no measured frame for yet, and that `minimumSize` and `maximumSize` can be used as a fallback. These notes are current as of the last measurement run: only CarPlay, macOS `.extraLargePortrait`, and the iPad Home Screen frames for sizes other than the system ones are still unmeasured, along with the StandBy placement. Apple Watch `.accessoryInline` is measured but has no usable frame: it reports a small square that never renders, so it is deliberately left out. `Measurements/README.md` records why each of those cannot be captured.
- Corrected numerous README and doc comment errors, including `Text(item.value)` in every layout example, wrong type and parameter names, out-of-date deprecation versions, descriptions naming the wrong axis or default, and two broken README anchor links.

## [0.9.11] - 2025-05-06

See [releases](https://github.com/ryanlintott/FrameUp/releases) for changes prior to this version.

[Unreleased]: https://github.com/ryanlintott/FrameUp/compare/1.0.0...HEAD
[1.0.0]: https://github.com/ryanlintott/FrameUp/compare/0.9.11...1.0.0
[0.9.11]: https://github.com/ryanlintott/FrameUp/releases/tag/0.9.11
