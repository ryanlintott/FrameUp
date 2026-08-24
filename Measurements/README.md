# Widget frame measurements

Frame sizes reported by WidgetKit on real devices and simulators, captured with the `WidgetSizeProbe` widget extension in `Example/`.

These are the raw measurements behind the `WidgetSize` lookup tables. Apple does not publish a frame for every widget family on every platform, and the published tables lag new devices and OS betas, so measuring is the only way to fill the gaps.

## How to capture

1. Build and install the example app on the target device or simulator. The probe extension is embedded in `FrameUpExample`.
2. Read the probe's log. Prefer querying history after the fact rather than streaming, because a long-lived `log stream` can be killed and lose everything it was buffering:

   ```sh
   xcrun simctl spawn booted log show --style compact --last 30m \
     --predicate 'subsystem == "com.abetterwaytodo.FrameUpExample.WidgetSizeProbe"'
   ```

   `log stream` with the same predicate also works for watching live. On a physical device, use Console.app and filter on the same subsystem.
3. On the device, enter jiggle mode, choose **Add Widget**, and open the **FrameUp** entry in the gallery. Opening the entry is enough — WidgetKit renders every supported family to build the gallery carousel, so the widget does not need to be placed on the Home Screen.
4. Merge the captured `WIDGET_SIZE_PROBE` lines into `widget-frames.json`.

## Fields

| Field | Meaning |
| --- | --- |
| `deviceModel` | Model identifier such as `iPhone18,3`. Reports the simulated device on a simulator. |
| `idiom` | User interface idiom. Nil if the probe did not run on the main thread. |
| `systemVersion` | OS version the measurement was taken on. |
| `screenSize` | Screen size ignoring orientation. This is the key the `WidgetSize` tables switch on. |
| `family` | `WidgetFamily.description`. |
| `displaySize` | Frame from `TimelineProviderContext.displaySize`. |
| `viewSize` | Frame measured while rendering the widget body, with content margins disabled. On iPad this may be the design canvas while `displaySize` is the Home Screen frame. |

The file keeps every distinct record rather than a merged summary. Deriving a single frame per device and family is deliberately left to the step that generates the lookup table, because the raw records disagree in ways that are still being investigated. See the notes below.

## What has been measured

All values are `displaySize`, in points.

### iPhone

| Screen | OS | Device | Small | Medium | Large | vs. current `WidgetSize` |
| --- | --- | --- | --- | --- | --- | --- |
| 390×844 | 18.6 | iPhone 13 (`iPhone14,5`) | 158 | 338×158 | 338×354 | matches |
| 402×874 | 18.6 | iPhone 16 Pro (`iPhone17,1`) | 158 | 338×158 | 338×354 | matches |
| 440×956 | 18.6 | iPhone 16 Pro Max (`iPhone17,2`) | 170 | 364×170 | 364×382 | matches |
| 390×844 | 26.5 | iPhone 13 (`iPhone14,5`) | 162 | 342×162 | 342×358 | **wrong** |
| 390×844 | 26.5 | iPhone 17e (`iPhone18,5`) | 162 | 342×162 | 342×358 | **wrong** |
| 390×844 | 27.0 | iPhone 17e (`iPhone18,5`) | 162 | 342×162 | 342×358 | **wrong** |
| 402×874 | 26.5 | iPhone 17 (`iPhone18,3`) | 164.33 | 349.67×164.33 | 349.67×365 | **wrong** |
| 402×874 | 27.0 | iPhone 17 (`iPhone18,3`) | 164.33 | 349.67×164.33 | 349.67×365 | **wrong** |
| 402×874 | 27.0 | iPhone 17 Pro (`iPhone18,1`) | 164.33 | 349.67×164.33 | 349.67×365 | **wrong** |
| 420×912 | 27.0 | iPhone Air (`iPhone18,4`) | 172.67 | 366.67×172.67 | 366.67×382 | **wrong** |
| 440×956 | 27.0 | iPhone 17 Pro Max (`iPhone18,2`) | 176.67 | 378×176.67 | 378×394 | **wrong** |

### iPad

| Screen | OS | Device | Small | Medium | Large |
| --- | --- | --- | --- | --- | --- |
| 820×1180 | 27.0 | iPad A16 (`iPad15,7`) | 155 | 342×155 | 342×342 |

## Findings

**The existing table is correct for iOS 18 and earlier, including screen sizes Apple never published.** The 402 and 440 point wide iPhones have no row in the HIG, so `sizesForiPhone` resolves them through arms meant for narrower devices — and on iOS 18.6 those fall-throughs return exactly the right values. Nothing needs fixing on the pre-26 side.

**Only the iOS 26 and later branch is wrong,** and it is wrong for every iPhone screen size measured so far.

**iPhone widget frames changed in iOS 26.** An iPhone 13 reports 158 / 338×158 / 338×354 on iOS 18.6 and 162 / 342×162 / 342×358 on iOS 26.5 — same device, same screen, different OS. Apple's published values are correct for iOS 18 and earlier and have not been updated since. Because iOS 18 and iOS 26 are consecutive major releases, the change is pinned to iOS 26 with no untested versions in between.

**The lookup therefore needs exactly two variants per screen size:** iOS 18 and earlier, and iOS 26 and later. iOS 26.5 and 27.0 agree with each other.

**The difference is the OS, not the device.** An iPhone 13 from 2021 and an iPhone 17e report identical values on the same OS, so keying the lookup on screen size remains correct.

**Apple's table has no row at all above 430×932.** The 402, 420, and 440 point wide iPhones fall through to arms meant for narrower devices.

**iPad appears unaffected.** The one iPad measured matches the HIG exactly, so whatever changed in iOS 26 did not change iPad frames.

**Placed widgets report the same frame as gallery previews.** A `systemSmall` widget placed on the Home Screen of an iPhone 17 reports 164.333×164.333, identical to what the gallery reported for the same device. Measuring the placed widget's rendered pixels on a screenshot gives 493 px wide at @3x, which is exactly 164.333 pt. Reading sizes from the gallery is therefore a valid shortcut, and no widget needs to be placed to collect a measurement.

Records with `"stage": "timeline"` come from a placed widget. Gallery reads produce only `placeholder` and `snapshot` stages, so `stage` distinguishes the two contexts where `isPreview` does not.

**Frames land on whole pixels.** Every `displaySize` is an integer number of pixels, which is why values are fractional exactly when the pixel count is not divisible by the scale factor: thirds on @3x, halves on @2x, never anything else.

## Open questions

**The pre-iOS-26 values are unverified.** No iOS 25 or earlier runtime is installed, so the older rows are still only Apple's published numbers. They have never been confirmed by measurement.

**`displaySize` is the trustworthy value; `viewSize` is not.** On iPad the rendered `viewSize` for `systemMedium` and `systemLarge` came back as 341.911765 rather than 342. That is 11625/34, which is not a whole number of pixels, while every `displaySize` is. The gallery appears to render the widget through a transform, so `viewSize` measured there reflects the render rather than the frame.

**A second, smaller `systemSmall` frame appears on iPad.** Most records report 155×155 but some report 152×152, from both `placeholder` and `render`. Both are whole pixel values. It is not yet known which placement produces the smaller frame.
