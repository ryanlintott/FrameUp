# Changelog

## [Unreleased]

### Changed

- Raised minimum Swift version to 6.0 and minimum platform versions to iOS 15, macOS 12, watchOS 9, tvOS 15, and visionOS 1, meeting the minimum deployment versions required by Xcode 27.
- Extended `WidgetFamily`/`WidgetSize` support to visionOS, including the new `extraLargePortrait` size and widget family.
- Consolidated the package, example app, and tests into a single Xcode workspace located under `Example/`.
- Reorganized the example app's Xcode project groups into folders and removed the unused Frameworks group.
- Updated the README, removing the Twitter link in favour of Bluesky.

### Added

- Added GitHub Actions workflows to test Swift 6 compatibility and build on the latest Swift across all supported platforms.
- Enabled Swift Package Index to automatically build DocC documentation.
- Added the missing watchOS example app scheme.
- Added a DocC documentation catalog with a landing page that curates the public API into topic groups.

## [0.9.11]

See [releases](https://github.com/ryanlintott/FrameUp/releases) for changes prior to this version.

[Unreleased]: https://github.com/ryanlintott/FrameUp/compare/0.9.11...HEAD
[0.9.11]: https://github.com/ryanlintott/FrameUp/releases/tag/0.9.11
