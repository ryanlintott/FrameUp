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

### iPhone — iOS 26 and later

Every value here is a measurement, not a published figure. Apple's table has no rows for 402, 420, 428 or 440 point wide screens, and its values for the sizes it does list describe iOS 18.

| Screen | Small | Medium | Large | Devices |
| --- | --- | --- | --- | --- |
| 440×956 | 176.67 | 378×176.67 | 378×394 | iPhone 16/17 Pro Max |
| 430×932 | 174.67 | 372×174.67 | 372×388 | iPhone 15/16 Pro Max, 14/15/16 Plus |
| 428×926 | 174.33 | 371.67×174.33 | 371.67×387 | iPhone 12/13/14 Pro Max |
| 420×912 | 172.67 | 366.67×172.67 | 366.67×382 | iPhone Air |
| 414×896 @2x | 166.5 | 356×166.5 | 356×371.5 | iPhone 11, XR |
| 414×896 @3x | 171.33 | 362.67×171.33 | 362.67×378 | iPhone 11 Pro Max, XS Max |
| 402×874 | 164.33 | 349.67×164.33 | 349.67×365 | iPhone 16/17 Pro, iPhone 17 |
| 393×852 | 162.67 | 344.67×162.67 | 344.67×360 | iPhone 14 Pro, 15, 16 |
| 390×844 | 162 | 342×162 | 342×358 | iPhone 12, 13, 14, 17e |
| 375×812 | 159 | 333.67×159 | 333.67×349 | iPhone 11 Pro, 12/13 mini, X, XS |
| 375×667 | 146 | 319×146 | 319×318 | iPhone SE 2/3, 8 |

`360×780` is not covered. No simulator device reports it — the 12/13 mini report 375×812 — so it appears to be a Display Zoom mode rather than a device's native size.

### iPhone — iOS 18 and earlier

Spot checks confirming Apple's published values, including two screen sizes Apple never published a row for.

| Screen | Small | Medium | Large | Matches current `WidgetSize`? |
| --- | --- | --- | --- | --- |
| 440×956 | 170 | 364×170 | 364×382 | yes |
| 402×874 | 158 | 338×158 | 338×354 | yes |
| 390×844 | 158 | 338×158 | 338×354 | yes |

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

**Screen size alone is not always enough. Scale can split a row.** 414×896 exists at both 2x (iPhone XR, 11) and 3x (iPhone XS Max, 11 Pro Max). On iOS 26 those two report different frames: 166.5 versus 171.33 points, a difference of 4.83 points. Both are whole pixels at their own scale — 333 px and 514 px — and neither value is a whole pixel at the other scale. A lookup keyed on screen size alone cannot serve both, so the display scale belongs in the key.

This is the only screen size known to split. It was found by noticing that 166.5 points is not a whole number of pixels at 3x, which is what prompted measuring the 3x device.

**Two devices sharing a screen size report identical frames.** iPhone 11 Pro and iPhone 13 mini both report 375×812 and both give 159 / 333.67×159 / 333.67×349. Combined with the iPhone 13 and 17e agreeing at 390×844, screen size plus OS is enough to determine the frame.

**The iOS 26 grid is finer than the old one.** On iOS 18, 390, 393 and 402 point wide screens all produced the same 158×158 small widget. On iOS 26 they produce 162, 162.67 and 164.33. A lookup table for iOS 26 cannot reuse the coarse screen-width boundaries the old table used.

**Frames land on whole pixels.** Every `displaySize` is an integer number of pixels, which is why values are fractional exactly when the pixel count is not divisible by the scale factor: thirds on @3x, halves on @2x, never anything else.

## Open questions

**The pre-iOS-26 values are unverified.** No iOS 25 or earlier runtime is installed, so the older rows are still only Apple's published numbers. They have never been confirmed by measurement.

**`displaySize` is the trustworthy value; `viewSize` is not.** On iPad the rendered `viewSize` for `systemMedium` and `systemLarge` came back as 341.911765 rather than 342. That is 11625/34, which is not a whole number of pixels, while every `displaySize` is. The gallery appears to render the widget through a transform, so `viewSize` measured there reflects the render rather than the frame.

**A second, smaller `systemSmall` frame appears on iPad.** Most records report 155×155 but some report 152×152, from both `placeholder` and `render`. Both are whole pixel values. It is not yet known which placement produces the smaller frame.
