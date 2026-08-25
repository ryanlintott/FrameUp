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

### iPhone accessory frames, iOS 26 and later

Every iPhone screen size that iOS 26 supports, all on iOS 26.5 except 402×874 which is 27.0.

| Screen | circular | rectangular | inline | Apple publishes circular |
| --- | --- | --- | --- | --- |
| 440×956 @3x | 60 | 158×60 | 370×36 | 76 |
| 430×932 @3x | 60 | 158×60 | 370×36 | 76 |
| 428×926 @3x | 60 | 156×60 | 364×36 | 76 |
| 420×912 @3x | 57.67 | 153×57.67 | 360×36 | no row |
| 414×896 @3x | 63.67 | 156.67×63.67 | 358×36 | 76 |
| 414×896 @2x | 60 | 154×60 | 358×36 | 76 |
| 402×874 @3x | 58 | 148×58 | 342×36 | no row |
| 393×852 @3x | 58 | 147.67×58 | 341×36 | 72 |
| 390×844 @3x | 58 | 146×58 | 336×36 | 72 |
| 375×812 @3x | 58 | 143×58 | 327×36 | 72 |
| 375×667 @2x | 56 | 141×56 | 323×36 | 68 |

### iPhone extraLargePortrait, iOS 27

Apple publishes no row for this family on any platform. Every iPhone screen size that iOS 27 supports is measured here, and every one of them offers the family.

| Screen | Frame | Pixels |
| --- | --- | --- |
| 440×956 @3x | 378×611.33 | 1134×1834 |
| 430×932 @3x | 372×601.33 | 1116×1804 |
| 428×926 @3x | 371.67×599.67 | 1115×1799 |
| 420×912 @3x | 366.67×591.33 | 1100×1774 |
| 414×896 @3x | 362.67×584.67 | 1088×1754 |
| 414×896 @2x | 356×576.5 | 712×1153 |
| 402×874 @3x | 349.67×565.67 | 1049×1697 |
| 393×852 @3x | 344.67×557.33 | 1034×1672 |
| 390×844 @3x | 342×554 | 1026×1662 |
| 375×812 @3x | 333.67×539 | 1001×1617 |
| 375×667 @2x | 319×490 | 638×980 |

On every device the width is identical to `systemMedium` and `systemLarge`, so this is the same column made taller rather than a differently proportioned frame.

### iPad extraLargePortrait, iPadOS 27

Design canvas frames. Apple publishes no row for this family on any platform.

| Screen | Frame | Pixels |
| --- | --- | --- |
| 1032×1376 | 378.5×586.5 | 757×1173 |
| 1024×1366 | 378.5×586.5 | 757×1173 |
| 834×1194 | 342×529 | 684×1058 |
| 820×1180 | 342×529 | 684×1058 |
| 810×1080 | 320.5×494.5 | 641×989 |
| 744×1133 | 305.5×470 | 611×940 |

The width is identical to `systemMedium` and `systemLarge` on every iPad, the same rule that holds on iPhone.

`834×1112` and `768×1024` have no entry because iPadOS 27 does not run on any iPad reporting those screen sizes. The Home Screen frame is not measured for any of these, and it cannot be derived from the scale factor of the other sizes because that gives a value which is not a whole number of pixels.

This run also confirmed the published `systemExtraLarge` frames on iPadOS 27, which previously had only been checked on 26.5 and 18.6.

### iPad Lock Screen, iPadOS 18 and later

Apple's table has no accessory row for iPad. Every value here is measured, all on iPadOS 26.5 except 820×1180 which is also confirmed on 18.6. All are design canvas values at 2x.

| Screen | systemSmall | circular | rectangular | inline |
| --- | --- | --- | --- | --- |
| 1032×1376 | 150.5 | 60 | 150.5×60 | 372×36 |
| 1024×1366 | 149 | 59.5 | 149×59.5 | 374×36 |
| 834×1194 | 152 | 61 | 152×61 | 372×36 |
| 834×1112 | 152 | 61 | 152×61 | 372×36 |
| 820×1180 | 152 | 63 | 152×63 | 372×36 |
| 810×1080 | 146 | 58 | 146×58 | 372×36 |
| 768×1024 | 135.5 | 53 | 135.5×53 | 372×36 |
| 744×1133 | 133 | 53.5 | 133×53.5 | 372×36 |

On every iPad the Lock Screen `systemSmall` is exactly as wide as `accessoryRectangular`. The Lock Screen widget column is that wide and a system small is sized to fit it. On a 834×1112 iPad the Lock Screen frame is **larger** than the Home Screen frame, 152 against 150, so it is not simply a shrunken version.

`1032×1376` has no row in `WidgetSize` at all. Every M4 and M5 13-inch iPad Pro reports it. Its design canvas system frames were measured and are identical to those of 1024×1366, so the nearest width fallback already gives the right answer for those, but its Lock Screen frames differ and now have their own row.

### iPad

All at 820×1180 @2x, and identical on iPadOS 18.6, 26.5 and 27.0. `displaySize` reports the design canvas, not the Home Screen frame.

| Family | Frame | Source |
| --- | --- | --- |
| `systemSmall` on the Home Screen | 155×155 | published |
| `systemSmall` on the Lock Screen | **152×152** | measured, not published |
| `systemMedium` | 342×155 | published |
| `systemLarge` | 342×342 | published |
| `systemExtraLarge` | 715.5×342 | published |
| `accessoryCircular` | **63×63** | measured, not published |
| `accessoryRectangular` | **152×63** | measured, not published |
| `accessoryInline` | **372×36** | measured, not published |

A small widget placed on the Home Screen of the 26.5 iPad renders **272 pixels wide, which is 136 points**, while reporting a 155 point `displaySize`. Measured by decoding the screenshot and scanning for the widget's near-white fill across 29 scanlines.

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

**The iPhone accessory frames changed in iOS 26 too, and by more than the system frames.** Every published value is wrong on iOS 26 and later. `accessoryInline` is the extreme case: 342 points wide on a 402 point iPhone where Apple publishes 234, 46 percent wider, against a worst case of 8 percent for the system sizes.

Two patterns hold across every iPhone measured. `accessoryInline` is 36 points tall on all of them, where Apple publishes 26. And 414×896 splits by display scale here as it does for the system sizes, so the scale key is needed for accessory frames too.

There is no formula. Circular is not proportional to screen width, at 0.136, 0.144 and 0.149 of it across the range, and it moves by the same 2 points across both a 38 point and a 27 point difference in screen width. Every screen size had to be measured.

**iPad frames did not change in iOS 26.** The same iPad Air reports identical frames on iPadOS 18.6 and 26.5, and a third iPad agrees on 27.0. Whatever changed for iPhone in iOS 26 left iPad alone, so the iPad table needs no OS version axis.

**The iPad design canvas and Home Screen frames are both confirmed, and the scaling is still real.** Apple's published values for 820×1180 are a 155 point canvas and a 136 point Home Screen frame. `displaySize` returns 155 whether the widget is in the gallery or placed, and the placed widget measures 136 points on screen. The ratio is 0.877, matching `scaleFactorForiPad`. Content is still laid out large and scaled down on iPadOS 26.

**414×896 splits by display scale for every family measured on it.** The system frames, the accessory frames and `extraLargePortrait` all differ between the 2x iPhone 11 and the 3x iPhone 11 Pro Max. It is a rule for that screen size rather than a quirk of one family.

**Screen size alone is not always enough. Scale can split a row.** 414×896 exists at both 2x (iPhone XR, 11) and 3x (iPhone XS Max, 11 Pro Max). On iOS 26 those two report different frames: 166.5 versus 171.33 points, a difference of 4.83 points. Both are whole pixels at their own scale — 333 px and 514 px — and neither value is a whole pixel at the other scale. A lookup keyed on screen size alone cannot serve both, so the display scale belongs in the key.

This is the only screen size known to split. It was found by noticing that 166.5 points is not a whole number of pixels at 3x, which is what prompted measuring the 3x device.

**Two devices sharing a screen size report identical frames.** iPhone 11 Pro and iPhone 13 mini both report 375×812 and both give 159 / 333.67×159 / 333.67×349. Combined with the iPhone 13 and 17e agreeing at 390×844, screen size plus OS is enough to determine the frame.

**The iOS 26 grid is finer than the old one.** On iOS 18, 390, 393 and 402 point wide screens all produced the same 158×158 small widget. On iOS 26 they produce 162, 162.67 and 164.33. A lookup table for iOS 26 cannot reuse the coarse screen-width boundaries the old table used.

**Frames land on whole pixels.** Every `displaySize` is an integer number of pixels, which is why values are fractional exactly when the pixel count is not divisible by the scale factor: thirds on @3x, halves on @2x, never anything else.

## Open questions

**The pre-iOS-26 values are unverified.** No iOS 25 or earlier runtime is installed, so the older rows are still only Apple's published numbers. They have never been confirmed by measurement.

**`displaySize` is the trustworthy value; `viewSize` is not.** On iPad the rendered `viewSize` for `systemMedium` and `systemLarge` came back as 341.911765 rather than 342. That is 11625/34, which is not a whole number of pixels, while every `displaySize` is. The gallery appears to render the widget through a transform, so `viewSize` measured there reflects the render rather than the frame.

**A widget size can have more than one frame on the same device, depending on where it is placed.** An iPad `systemSmall` is 155×155 on the Home Screen and 152×152 on the Lock Screen. A widget placed on the Lock Screen reports 152 from its `timeline` callback, so this is a real placement rather than a preview artefact. 152 points is also the width of `accessoryRectangular`, which suggests the Lock Screen widget column is 152 points wide and a system small placed there is sized to that column.

This is a different axis from ``WidgetTarget``. That distinguishes an iPad's design canvas from its scaled Home Screen frame; this distinguishes one placement from another.

`widgetRenderingMode` does not identify the placement. Both frames appear in `vibrant`, `fullColor` and `accented` renders, because the gallery previews a widget in several modes before it is placed. The reliable signal is a `displaySize` from the `timeline` stage of a placed widget.

**The iPad accessory frames were never published.** Apple's table has no accessory row for iPad and `WidgetSize` documents them as unknown. They are `accessoryCircular` 63×63, `accessoryRectangular` 152×63 and `accessoryInline` 372×36, the same on iPadOS 18.6 and 26.5.
