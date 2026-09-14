# Widget frame measurements

Frame sizes reported by WidgetKit on real devices and simulators, captured with the `WidgetSizeProbe` widget extension in `Example/`.

These are the raw measurements behind the `WidgetSize` lookup tables. Apple does not publish a frame for every widget family on every platform, and the published tables lag new devices and OS betas, so measuring is the only way to fill the gaps.

## How it works

The probe is a widget extension embedded in `FrameUpExample`, so installing the example app installs the probe. Everything it learns leaves the device as a line in the unified log, except on iPad, where a rendered frame has to be read out of a screenshot instead.

| File | Role |
| --- | --- |
| `Example/WidgetSizeProbe/WidgetSizeProbeBundle.swift` | `@main`, the extension's entry point |
| `Example/WidgetSizeProbe/Info.plist` | Declares it a `com.apple.widgetkit-extension` |
| `Example/WidgetSizeProbe/WidgetSizeProbe.swift` | The widget, its timeline provider, and the two measuring instruments |
| `Example/WidgetSizeProbe/ProbeRecord.swift` | The record type, the device context, and log emission |
| `Measurements/findwidget.swift` | Measures a placed widget from a screenshot |
| `Measurements/watchplacement.swift` | Attributes a watchOS frame to the place the widget was in |
| `Measurements/widget-frames.json` | Every raw record, kept unmerged |
| `Sources/FrameUp/Widget/WidgetFrame+all.swift` | The lookup tables the measurements feed |

**The probe declares more families than it expects to get.** `supportedFamilies` lists every family the OS might offer rather than the ones `WidgetSize` believes are supported, and WidgetKit ignores any the device cannot show. Declaring the library's own list would leave the probe unable to discover a family the library has wrong, because that family would never be offered, never render and never be measured. `.contentMarginsDisabled()` is set for a related reason: without it the body is inset and the measured view size is the frame minus its margins.

**Each render is measured twice, by different means.** `ProbeProvider` reads `TimelineProviderContext.displaySize` in each of its callbacks and emits a record tagged `placeholder`, `snapshot` or `timeline`. That is WidgetKit declaring the frame. `FrameProbe`, a `Shape` in the entry view's background, receives the laid out rectangle in `path(in:)` and emits it as `viewSize`, tagged `render`. That is what the layout actually produced. It is a `Shape` rather than an `onAppear` because widget bodies render as static snapshots where appearance callbacks are not guaranteed to run, while `path(in:)` always is. The two agree on most platforms and disagree on iPad, where `displaySize` reports the design canvas and the widget draws smaller, and that disagreement is a finding rather than noise.

**Records travel as log lines.** `ProbeLog.emit` encodes a `ProbeRecord` as one line of JSON with sorted keys and writes it to `os.Logger` on subsystem `com.abetterwaytodo.FrameUpExample.WidgetSizeProbe`, behind the `WIDGET_SIZE_PROBE` marker. The interpolation is `privacy: .public`; without that the payload comes back from the log redacted. The device fields are read on whichever thread the provider happened to run on and return nil rather than hopping actors, which is why `displayScale` is absent from about a third of the records.

**iPad needs a third route.** `displaySize` there is the design canvas, so no log record can report the frame a placed widget draws at. The probe paints its container background magenta and fills its frame opaque white, and `findwidget.swift` finds that fill in a screenshot. Magenta is for the Home Screen and Today View; the white is what survives the Lock Screen, which removes the container background and renders vibrant.

**Two hops are done by hand, and the second one deliberately.**

```
probe render ──> os.Logger ──> log show ──> paste ──> widget-frames.json ──┐
                                                                           ├──> WidgetFrame+all.swift
screenshot ──> findwidget.swift ──> notes in this file ────────────────────┘
```

There is no merge script. Captured lines have the `WIDGET_SIZE_PROBE ` marker stripped and are pasted into the array in `widget-frames.json`, one object per line, with `CGSize` encoded as `[width, height]`. Turning those records into a table row is then a judgment call rather than a transform, for the reason given under [Fields](#fields), and the judgment is preserved as `// Measured on ...` provenance comments beside each row of `WidgetFrame+all.swift`.

Note the asymmetry in that sketch: screenshot measurements never reach `widget-frames.json`, whose schema has no place for them. They go from the tool's output into the notes in this file and into the table, so their provenance lives only in prose.

## What cannot be captured in a simulator

**Use the Simulator app from Xcode 26.6, not Xcode 27.** Xcode 27 ships no `Simulator.app` at all; it is replaced by Device Hub, which does not accept injected touch events. Everything below was retested under the Xcode 26.6 Simulator before being called impossible.

**StandBy.** StandBy needs the device locked, charging and in landscape at once. `simctl status_bar override --batteryState charging` only changes what the status bar draws, not what the system believes about power, so rotating a locked simulator gives a landscape Lock Screen rather than StandBy. `WidgetPlacement.standBy` therefore needs real hardware.

**CarPlay.** The simulator does implement CarPlay, unlike StandBy. `I/O > External Displays > CarPlay` brings up a working 800x480 screen, `com.apple.CarPlayApp` runs, and the framebuffer can be captured with `simctl io --display external`. What does not work is touching it: clicks do not reach the CarPlay window, which is a long standing Apple bug reported against many Xcode versions and reproducible with Apple's own sample apps. See [Cannot interact with CarPlay external display in Xcode](https://developer.apple.com/forums/thread/736554). The reported workaround, quitting and reconnecting the display several times with the phone locked, did not help here. Apple's suggested alternative is the standalone CarPlay Simulator from Additional Tools, which needs a physical iPhone tethered to the Mac.

**Widget placement in a preview.** Every `Preview` macro overload takes `as family:` and nothing else, and `WidgetPreviewContext` has one initialiser, `init(family:)`. A preview can choose which family renders but not where, so previews cannot reach StandBy, CarPlay or the Lock Screen.

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

To measure a Display Zoom row, turn on **Settings > Developer > Display Zoom > More Space** and let the device restart. The probe records `screenSize`, so a sweep can be checked for the zoomed value before its frames are trusted.

On iPad, `displaySize` reports the design canvas, so a rendered frame has to be measured from a screenshot instead. `findwidget.swift` decodes a screenshot and reports the bounding box of the probe's fill in pixels and points. It runs directly, with no build step:

```sh
xcrun simctl io <udid> screenshot shot.png
Measurements/findwidget.swift shot.png 2            # Home Screen and Today View
Measurements/findwidget.swift shot.png 2 bright     # Lock Screen, which renders vibrant
```

The second argument is the pixels per point of the device the screenshot came from, used to convert the measured box to points. An optional fourth argument, `x,y,width,height` in pixels, narrows the search when something else on screen also matches. Complete regions are discovered before the crop is applied, so a crop that crosses a widget still reports its full box in screenshot coordinates.

A match is a run of pixels that pass a colour threshold, so a partly covered edge pixel is not counted and a measured frame can read up to one pixel short on each side. That is 0.5pt at @2x and 0.33pt at @3x, always in the same direction, which is worth remembering when a screenshot disagrees with a `displaySize` by a fraction of a point.

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
| `widgetKind` | Which probe widget produced the record. Absent on records captured before the watchOS placement work added it. |
| `showsWidgetLabel` | Whether the render happened somewhere that shows a widget label. Tried as a way to tell a watch face complication from a Smart Stack widget; it does not separate them. Absent on records captured before it was added, and always absent on macOS, which has no such value. |
| `capturedPlacement` | Where the operator had placed the widget for that capture. Added by `watchplacement.swift` after the fact rather than read from the device, because no record reports a placement. Absent on every record captured before the tool existed. |

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

`834×1112` and `768×1024` have no entry because iPadOS 27 does not run on any iPad reporting those screen sizes.

**On iPad this family is offered in Today View, not on the Home Screen grid.** WidgetKit's own `WidgetLocation` has no Today View case, so it is recorded against the Home Screen like every other Today View size, but it cannot be added to the Home Screen itself.

**The rendered frame is derivable after all, and measurement confirms it.** An earlier note here said it could not be, because applying the scale factor to the canvas gives a value that is not a whole number of pixels. That is true of the scale factor and false of the grid. Every published Home Screen row is an exact grid — `medium` is two cells plus a gutter, `large` the same square, `extraLarge` four cells plus three gutters — with no rounding error on any of the ten screen sizes. The canvas rows are the ones carrying a half point, because they are that grid divided by the scale factor.

`extraLargePortrait` measures two cells wide by three tall on the canvas, so it is two by three on the Home Screen grid too:

| Screen | Cell | Gutter | Rendered `extraLargePortrait` | Pixels at 2x |
| --- | --- | --- | --- | --- |
| 1024×1366 | 160 | 36 | 356×552 | 712×1104 |
| 834×1194 | 136 | 28 | 300×464 | 600×928 |
| 820×1180 | 136 | 28 | **300×464** | **600×928** |
| 810×1080 | 124 | 24 | 272×420 | 544×840 |
| 744×1133 | 120 | 20 | 260×400 | 520×800 |

The bold row is measured: a widget placed in Today View on a 820×1180 iPad rendered 600×928 pixels against a 342×529 design canvas, a ratio of 0.8772, the same scale factor every other size on that iPad uses. The rest are derived from the grid and land on whole pixels. `1032×1376` has no row, because it has no published Home Screen row to build a grid from and its canvas frames measured identical to `1024×1366`, so it resolves there by nearest width exactly as its system sizes do.

Measuring a placed widget is the only way to get an iPad rendered frame, since `displaySize` there reports the canvas. The probe paints its container background a saturated magenta for exactly this reason, so its bounds can be found in a screenshot by testing pixels rather than by eye.

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

**iPad Lock Screen widgets are not scaled.** Placing all three on a 820×1180 iPad and measuring the rendered pixels gives 126×126, 304×126 and 304×304, which is 63×63, 152×63 and 152×152 points — exactly the design canvas values above. Had the Lock Screen scaled its widgets the way the Home Screen does, the same factor would have produced 110.5, 266.7×110.5 and 266.7 pixels, none of them whole. So the canvas frame is the size a Lock Screen widget draws at, and these sizes have one frame rather than two.

That answers what looked like a missing measurement. `WidgetTarget` separates the canvas from the frame it is scaled into on the Home Screen grid, and the Lock Screen does not use that grid, so there is no second frame to find for the accessory sizes or for the Lock Screen `small`.

`1032×1376` has no row in `WidgetSize` at all. Every M4 and M5 13-inch iPad Pro reports it. Its design canvas system frames were measured and are identical to those of 1024×1366, so the nearest width fallback already gives the right answer for those, but its Lock Screen frames differ and now have their own row.

### visionOS

Measured on the Apple Vision Pro simulator on visionOS 26.5 and 27.0, which agree exactly on every family both offer. Apple publishes a visionOS row but only `small` matches.

| Family | Measured | Apple publishes |
| --- | --- | --- |
| `small` | 158×158 | 158×158 |
| `medium` | 354×158 | 338×158 |
| `large` | 354×354 | 338×354 |
| `extraLarge` | 550×354 | 450×338 |
| `extraLargePortrait` | 354×550 | 338×450 |
| `accessoryCircular` | **75×75** | no row |
| `accessoryRectangular` | **208×79** | no row |

The system frames form a grid of 158 point cells with a 38 point gutter, so one, two and three cells are 158, 354 and 550 points. Every one of them lands on it: `medium` is two cells by one, `large` two by two, `extraLarge` three by two, and `extraLargePortrait` the same two by three the other way up.

**Apple's table contradicts itself, and the one place it disagrees with itself is the place it agrees with the measurement.** It publishes `large` as 338×354. A two by two widget has to be square, and this one is not. Every other place a two cell span appears in the table it is written 338, but `large`'s height is written 354, which is exactly what every two cell span measures. Three cells is published as 450, and no gutter reproduces that from a 158 point cell: three cells need 474 points before any gutter at all, so 450 would require a gutter of −12.

`small` is the only row that matches, at 158×158, and its millimetre column of 268×268 matches too. The table gives millimetres alongside points at a consistent 1.696 mm per point, so it was written for visionOS specifically rather than copied from the iPhone rows.

Because 26.5 and 27.0 agree, this is a published table that was never right rather than frames that changed the way iPhone's did in iOS 26.

The published values are not an earlier visionOS either. Widgets arrived on visionOS in version 26: every one of the 103 visionOS availability annotations in WidgetKit is 26.0, the two accessory cases are 27.0, and none is lower. A widget extension will not compile for visionOS 2 at all — `WidgetFamily`, `Timeline` and even `WidgetBundle.main()` are all 26.0. The published table also has an `Extra large portrait` row, and that family is visionOS 26.0 in the SDK, arriving there a release before iOS and macOS got it, so a table describing an earlier visionOS could not have listed it.

The accessory sizes arrive in visionOS 27. A 26.5 sweep offered every other family and not these, which is what pins the version. `accessoryInline` has no case in the visionOS SDK at all, so it does not exist there.

The accessory frames are recorded against the Home Screen rather than the Lock Screen, which visionOS does not have. They render with a container background and report `isPreview` false, the same as every other visionOS family, unlike an iPhone Lock Screen accessory which renders vibrant and without one.

visionOS records have no `screenSize` or `displayScale`. A visionOS widget is placed on a surface in the room rather than on a screen, `UIScreen` is unavailable on the platform, and each surface is rendered at whatever scale its distance calls for.

#### Capturing on visionOS

The probe extension needs `xros xrsimulator` added to `SUPPORTED_PLATFORMS`, device family 7, and an `XROS_DEPLOYMENT_TARGET` of 26. Its embed phase carries no `platformFilter`, so unlike the macOS case nothing else has to be changed to get it into the app bundle.

Interaction is the part that is different. visionOS is a 3D scene rather than a screen with touch events, so there is no gallery to open by tapping. The widget gallery is a system app, `com.apple.RealityWidgets`, and launching it directly renders every supported family:

```sh
xcrun simctl launch <udid> com.abetterwaytodo.FrameUpExample
xcrun simctl launch <udid> com.apple.RealityWidgets
```

No pointer or keyboard input is needed, which is why visionOS could be measured where CarPlay could not.

### Apple Watch — watchOS 26 and 27

Measured on every Apple Watch simulator, one per case size, on watchOS 26.5 and again on 27.0 with identical results. Apple publishes one Smart Stack frame per case size and nothing for the watch face.

| Case | Screen | Smart Stack rectangular | Watch face rectangular | Watch face circular | Corner | Apple publishes |
| --- | --- | --- | --- | --- | --- | --- |
| 40mm | 162×197 | 152×69.5 | 162×69 | 42×42 | 32×32 | 152×69.5 |
| 42mm | 187×223 | 176×72.5 | 176×72.5 | 47×47 | 30×30 | no row |
| 44mm | 184×224 | 173×76.5 | 184×78 | 47×47 | 36×36 | 173×76.5 |
| 46mm | 208×248 | 194×80.5 | 196×80.5 | 51×51 | 34×34 | no row |
| 49mm Ultra 3 | 211×257 | 197×84 | 199×84.5 | 51×51 | 39×39 | 191×81.5 |

Every frame here was read from a widget placed in that location. Each Smart Stack frame matches Apple's published row wherever Apple publishes one, and Apple's table is explicitly Smart Stack sizes. The corner values are measured but stored as no frame, for the reason under [Findings](#findings).

The 2027 models add nothing. Series 12 42mm and 46mm report 187×223 and 208×248 and the Ultra 4 reports 211×257, each with frames identical to the watch it shares a screen with, so they resolve to the rows above.

Launching the watch app is enough to capture the frame *values*. No gallery to open and no interaction, which makes watchOS the easiest platform to sweep. Attributing a frame to a placement is the part that takes hands, and [Verifying a new watch](#verifying-a-new-watch) is how it is done.

#### Which frame belongs to which placement

A registration sweep reports two frames for each family — for 44mm, `accessoryRectangular` at both 173×76.5 and 184×78 — and nothing readable at render time says where a render came from.

Two approaches failed. `showsWidgetLabel` does not separate them: both frames appear with it true and false. `disfavoredLocations` does not either, because it does not change what WidgetKit pre-renders — a probe disfavouring the Smart Stack still reported both frames.

What worked is the method that settled the iPad Lock Screen: place the widget and read the `timeline` stage.

**Where the two frames differ, the smaller is the Smart Stack and the larger is the watch face.** That holds on every watch measured. It is a habit rather than a law, though, because the 42mm reports the same frame in both places and so says nothing either way, which is why no test asserts it and why a new watch is placed rather than predicted.

**A picker preview reports the frame of the place it is offering.** On the 46mm the complication picker previewed at 196×80.5 and the Smart Stack picker at 194×80.5, and on the Ultra 3 at 199×84.5 and 197×84, each matching what the widget reported once placed there. These are `snapshot` records with `isPreview` true, which `watchplacement.swift` keeps in a column of their own. It is a small sample and nothing relies on it, but if it holds then browsing a picker reads a placement's frame without placing anything.

`disfavoredLocations` does work for what it is for: a probe disfavouring the Smart Stack was not offered in the Smart Stack gallery at all, while still appearing in the complications picker. It gates where a widget can be added, not what gets pre-rendered.

#### Verifying a new watch

This is the procedure behind every value in the table above, and the one to run when a new watch ships. Step 2 alone answers whether it reports a screen size the table has never seen; the rest attributes its frames to a placement.

Five older watches cannot be reached by it at all — 136×170, 156×195, 176×215, 198×242 and 205×251, which are the 38mm, the 42mm Series 1 to 3, the 41mm, the 45mm and the Ultra 2. No simulator for any of them ships in the watchOS 26 or 27 runtimes, so they would need an older runtime or real hardware, and they keep Apple's published Smart Stack row in the meantime.

`Measurements/watchplacement.swift` does the reading for a run. It separates the frames a placed widget reported from the ones WidgetKit pre-rendered, and says where the placed frame sits among that pair:

```sh
Measurements/watchplacement.swift                                     # whatever the booted watch has logged
Measurements/watchplacement.swift --placement watchFace --last 5m
Measurements/watchplacement.swift --placement watchFace --records
Measurements/watchplacement.swift --placement smartStack --json >> capture.json
Measurements/watchplacement.swift --file console.log --placement watchFace
```

A run that reports one size per family may be reporting a pair whose halves are equal, which is why each size carries the number of records that reported it. The 42mm is that case.

It cannot know where the widget was, so `--placement` is an assertion: the widget goes in one place and nowhere else, and the placed records in that window belong to that place. What the tool does know is which records a placed widget could have produced, which is finer than the stage alone:

| Group | Records | What it means |
| --- | --- | --- |
| `placed` | `snapshot` or `timeline` with `isPreview` false | A provider callback for a widget that is really on the watch. The only group the verdict uses. |
| `preview` | anything with `isPreview` true | A gallery browse, which produces `snapshot` records that look exactly like a placed widget's until this field is read. |
| `pre-rendered` | `placeholder` | WidgetKit asking for each frame it intends to pre-render. This is where a family's pair of frames shows up, on a placed widget and during a gallery browse alike, so it attributes nothing on its own. |
| `rendered` | `render` | The probe's own `Shape`, measuring the laid out body. Runs for a placed widget and a pre-render alike, with nothing to tell them apart. |

A run, start to finish:

1. Boot the watch, build, and install. The probe extension is embedded in the Watch App, so installing that installs the probe.

   ```sh
   xcrun simctl boot "Apple Watch Series 11 (42mm)"
   xcodebuild -workspace Example/FrameUp.xcworkspace \
     -scheme "FrameUpWatchExample Watch App" \
     -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (42mm)' \
     -derivedDataPath /tmp/probe build
   xcrun simctl install booted "/tmp/probe/Build/Products/Debug-watchsimulator/FrameUpWatchExample Watch App.app"
   xcrun simctl launch booted com.abetterwaytodo.FrameUpExample.watchkitapp
   ```

2. Take a baseline, with no placement asserted. Launching the app is enough to pre-render every family, so the pre-rendered column fills in and the placed column stays empty. That is the sweep: it records the screen size and the pair of frames, and confirms the probe is registered before any placing is attempted.
3. Place the probe in **one** place and nowhere else, by hand. Xcode 27's Device Hub accepts clicks from a person even though it does not accept injected touches, so this step cannot be scripted but needs no older Xcode.
   - **Watch face:** long press the face, tap Edit, swipe to the complications screen, tap the slot for the family being measured, and turn the crown to Widget Size Probe.
   - **Smart Stack:** swipe up from the face, scroll to the bottom of the stack, tap Edit, and add Widget Size Probe.
4. Let it render. Leave the face showing for a complication, or the stack open for a Smart Stack widget. A placed widget only reports a frame when the system asks it to draw.
5. Run the tool again with the placement used and a window that starts after the placing. One placement reports one frame per family. Two frames for one family means the window covers both placements, and the tool lists the placed records with timestamps and widget kinds so they can be told apart — narrow `--last` and run it again rather than guessing.
6. Capture that placement before making the next one. A widget already on the face keeps reporting every time the face redraws, so a window taken after the second placing contains records from both, and two placements that report the *same* frame cannot be separated by value either. Removing the first placement avoids the overlap entirely; capturing in order is enough if the frames differ.
7. Place it in the other place and repeat from step 4. The cleanest result is one widget reporting two frames from two places on the same watch, which is how the 40mm was done.
8. Capture with `--json`, paste the lines into `widget-frames.json`, and write the values and what they settle into this file. Turning records into a table row stays a judgment call rather than a transform, for the reason under [Fields](#fields).

A watch keeps its face configuration across installs, so a watch that has ever been placed can be re-confirmed without placing anything again: install, launch, and the widgets already on the face reload and report. That is how the Ultra 3's watch face frames were read.

The probe draws its own `displaySize` in the widget body, so a screenshot reads the frame back independently of the log, and shows where the widget is at the same time:

```sh
xcrun simctl io booted screenshot face.png
```

That is worth taking on any run that settles a row, because it is the one artefact that shows the frame and the placement together.

#### Findings

**Apple's table has no row for the 42mm and 46mm watches.** Series 10, 11 and 12 case sizes. They resolved to rows meant for a smaller watch, 165×72.5 and 184×80.5, against measured 176×72.5 and 194×80.5.

**Case size does not identify a watch.** The Ultra 2 and Ultra 3 are both 49mm but report 205×251 and 211×257 screens and different Smart Stack frames, 191×81.5 against a measured 197×84. Apple's published 49mm row describes the Ultra 2. Any lookup keyed on case size alone returns the same answer for both and is wrong for one of them.

**A complication is not the same size as a Smart Stack widget, except when it is.** On the 44mm they are 184×78 and 173×76.5, and on the 40mm 162×69 and 152×69.5. On the 42mm both are 176×72.5. Apple publishes only the Smart Stack figure, so the watch face frame exists nowhere else either way.

**A sweep's pair can be two identical values.** The 42mm pre-renders `accessoryRectangular` twice at 176×72.5:

```
2026-09-11 22:58:43.181  placeholder  accessoryRectangular  176×72.5
2026-09-11 22:58:43.185  placeholder  accessoryRectangular  176×72.5
```

Counting distinct sizes reads that as a family with one frame and invites the conclusion that the watch has no watch face frame at all. Count the records, not the sizes — `watchplacement.swift` prints both.

**`accessoryCircular` was only ever observed placed on the watch face.** Placing it produced a watch face record and the Smart Stack offered rectangular widgets, so it is recorded against the watch face only. That it *cannot* appear in the Smart Stack was not tested. Its watch face frame is the larger of its pair on every watch, each read from a placed complication.

**`accessoryInline` has no usable frame.** It reports a small square — 11×11 on the 40mm up to 13.5×13.5 on the 49mm — and never renders, producing only a placeholder record. It is left out of the table rather than recorded as a frame.

**Watch face complication frames do not vary by watch face.** The frames measured on one face were checked against others on the same watch and match, so the single watch face value per family is a property of the device rather than of whichever face happened to be selected. This was worth testing because the watch face to Smart Stack ratio clusters by model rather than by screen size, 1.066 and 1.064 on the SE 3 against 1.010 and 1.010 on the Series 11 and Ultra 3, which looked like face dependence. It is not.

**`accessoryCorner` is measured but has no frame in the lookup.** Its 44mm value is confirmed by a placed widget, but the value does not bound what the complication draws, because the shape is not a rectangle. See the open question below. `WidgetSize.accessoryCorner` exists as a case, and the measurements are here, but no frame is stored.

#### Capturing on watchOS

The probe extension needs `xros`-style treatment plus three things specific to watchOS:

- `SDKROOT = auto`, because the Watch App is `watchos` while the extension inherits `iphoneos` and otherwise builds for the wrong platform and is rejected as mismatched embedded content.
- `PRODUCT_BUNDLE_IDENTIFIER[sdk=watch*]` nested under the watch app's identifier, since an embedded binary must be prefixed by its parent app's.
- An embed phase and target dependency on the Watch App, which has neither by default.

`WKInterfaceDevice` supplies the screen size and scale in place of `UIScreen`, which watchOS does not have. It is not main actor isolated, so unlike iOS the screen size is captured whichever thread the provider runs on — worth having, since screen size is the key these frames are stored against.

```sh
xcrun simctl launch <udid> com.abetterwaytodo.FrameUpExample.watchkitapp
```

A full run, including the build and install that come before that launch, is in [Verifying a new watch](#verifying-a-new-watch).

### iPad Display Zoom, iPadOS 27

The three screen sizes Apple marks with a `*`, measured by turning on More Space under Settings > Developer > Display Zoom. Apple publishes the system frames for these and nothing else.

| Zoomed screen | Native | Small | Medium | Large | Extra large | Matches published |
| --- | --- | --- | --- | --- | --- | --- |
| 1192×1590 | 1024×1366 | 188 | 412×188 | 412×412 | 860×412 | yes |
| 970×1389 | 834×1194 | 162 | 350×162 | 350×350 | 726×350 | yes |
| 954×1373 | 820×1180 | 162 | 350×162 | 350×350 | 726×350 | yes |

Every published value is confirmed. The frames these three had no value for at all are below.

| Zoomed screen | extraLargePortrait | Lock Screen small | circular | rectangular | inline |
| --- | --- | --- | --- | --- | --- |
| 1192×1590 | 412×636 | 154.5 | 63 | 154.5×63 | 411×36 |
| 970×1389 | 350×538 | 152.5 | 62 | 152.5×62 | 406×36 |
| 954×1373 | 350×538 | 149 | 60.5 | 149×60.5 | 398×36 |

`extraLargePortrait` came back exactly as the Home Screen grid predicts, two cells by three, on all three. That is the third independent confirmation of the grid rule.

**A zoomed frame still cannot be derived from its native one.** The zoomed *screen* sizes are a consistent multiple of the native ones, 1.164, 1.163 and 1.163, and the frames are not: `small` goes 170 to 188 on one device, a factor of 1.106, and 155 to 162 on the other two, a factor of 1.045. The ratio also differs by widget size on the same device, where 1192×1590 is 1.106 for `small`, 1.089 for `medium` and 1.082 for `extraLarge`.

The Lock Screen frames are stranger still. Zooming a 1024×1366 iPad grows its Lock Screen `small` from 149 to 154.5 and zooming a 834×1194 grows it from 152 to 152.5, but zooming a 820×1180 *shrinks* it, from 152 to 149. Nothing about the native row predicts that.

`970×1389` and `954×1373` have identical system frames but different Lock Screen frames, 152.5 against 149, so they need separate rows. That is the same pattern as `1024×1366` and `1032×1376`.

### macOS and Mac Catalyst

Measured on macOS 26.6.2 with the widgets in Notification Center, and on macOS 27.0 with them on the desktop. Apple publishes no widget specifications for macOS at all, so these values exist nowhere else.

| Family | Frame | Pixels at 2x | From |
| --- | --- | --- | --- |
| `small` | 164×164 | 328×328 | macOS 26 |
| `medium` | 344×164 | 688×328 | macOS 26 |
| `large` | 344×344 | 688×688 | macOS 26 |
| `extraLarge` | 704×344 | 1408×688 | macOS 26 |
| `extraLargePortrait` | 344×704 | 688×1408 | macOS 27 |

The frames form a grid with a 16 point gutter: `medium` is two `small` plus a gutter, `extraLarge` is two `large` plus a gutter, and `extraLargePortrait` is `extraLarge` turned on its side. In `small` cells that is two by four, where the iPad Home Screen grid makes it two by three, so the exact rotation is particular to macOS.

macOS 27 reports the same four frames macOS 26 does, and moving the widgets from Notification Center to the desktop changes none of them. The accessory sizes do not exist on macOS.

A Mac widget is not placed on a screen grid the way an iPhone widget is, so there is no screen size to key on, and the lookup ignores the screen size passed to it. This was checked: the same widgets report the same frames on a 2560×1440 point external display and on a roughly 1728×1117 point built-in one. Both displays are 2x, so a display of a different scale is still untested, though every Mac that runs macOS 26 has a 2x built-in display.

Widgets in a Mac Catalyst app are hosted by macOS, so the lookup resolves Catalyst to these same frames rather than storing them twice.

#### Capturing on macOS

macOS needs more setup than a simulator. The widget extension has to build for macOS, which means gating the UIKit access, and both the app and the extension need the App Sandbox entitlement or the system will not register the extension at all. The extension's embed phase and target dependency also carry `platformFilter = ios` by default, which silently skips embedding it on macOS.

The probe's unified log output does not appear on macOS, on 26 or 27, and the reason is not yet understood, so these frames were read off the widgets on screen, which the probe view displays for exactly this reason.

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

**A placed visionOS widget is the same size as its gallery preview.** Checked by placing the probe on a surface in the simulator and comparing it against the preview, which matched. This is the same result as on iPhone and iPad, where a placed widget was measured on screen and agreed with the gallery, so reading frames from the gallery is valid on every platform measured so far. Unlike those two this was confirmed by eye in the environment rather than from a `timeline` stage record, because the placed widget did not re-render inside the log window.

**Apple's published visionOS frames are wrong for every family except `small`.** `medium` and `large` are published 338 wide and measure 354, and `extraLarge` is published 450x338 and measures 550x354. visionOS 26.5 and 27.0 report identical values, so unlike the iPhone case this is not a frame that changed after the table was written — the table was never right. The measured values form a clean 158 point grid with a 38 point gutter and the published ones fit no grid at all, which is the strongest evidence the measurements are the real frames.

**iPad frames did not change in iOS 26.** The same iPad Air reports identical frames on iPadOS 18.6 and 26.5, and a third iPad agrees on 27.0. Whatever changed for iPhone in iOS 26 left iPad alone, so the iPad table needs no OS version axis.

**The iPad design canvas and Home Screen frames are both confirmed, and the scaling is still real.** Apple's published values for 820×1180 are a 155 point canvas and a 136 point Home Screen frame. `displaySize` returns 155 whether the widget is in the gallery or placed, and the placed widget measures 136 points on screen. The ratio is 0.877, matching `scaleFactorForiPad`. Content is still laid out large and scaled down on iPadOS 26.

**414×896 splits by display scale for every family measured on it.** The system frames, the accessory frames and `extraLargePortrait` all differ between the 2x iPhone 11 and the 3x iPhone 11 Pro Max. It is a rule for that screen size rather than a quirk of one family.

**Screen size alone is not always enough. Scale can split a row.** 414×896 exists at both 2x (iPhone XR, 11) and 3x (iPhone XS Max, 11 Pro Max). On iOS 26 those two report different frames: 166.5 versus 171.33 points, a difference of 4.83 points. Both are whole pixels at their own scale — 333 px and 514 px — and neither value is a whole pixel at the other scale. A lookup keyed on screen size alone cannot serve both, so the display scale belongs in the key.

This is the only screen size known to split. It was found by noticing that 166.5 points is not a whole number of pixels at 3x, which is what prompted measuring the 3x device.

**Two devices sharing a screen size report identical frames.** iPhone 11 Pro and iPhone 13 mini both report 375×812 and both give 159 / 333.67×159 / 333.67×349. Combined with the iPhone 13 and 17e agreeing at 390×844, screen size plus OS is enough to determine the frame.

**The iOS 26 grid is finer than the old one.** On iOS 18, 390, 393 and 402 point wide screens all produced the same 158×158 small widget. On iOS 26 they produce 162, 162.67 and 164.33. A lookup table for iOS 26 cannot reuse the coarse screen-width boundaries the old table used.

**Frames land on whole pixels.** Every `displaySize` is an integer number of pixels, which is why values are fractional exactly when the pixel count is not divisible by the scale factor: thirds on @3x, halves on @2x, never anything else.

**A widget size can have more than one frame on the same device, depending on where it is placed.** An iPad `systemSmall` is 155×155 on the Home Screen and 152×152 on the Lock Screen. A widget placed on the Lock Screen reports 152 from its `timeline` callback, so this is a real placement rather than a preview artefact. 152 points is also the width of `accessoryRectangular`, which suggests the Lock Screen widget column is 152 points wide and a system small placed there is sized to that column.

This is a different axis from ``WidgetTarget``. That distinguishes an iPad's design canvas from its scaled Home Screen frame; this distinguishes one placement from another.

`widgetRenderingMode` does not identify the placement. Both frames appear in `vibrant`, `fullColor` and `accented` renders, because the gallery previews a widget in several modes before it is placed. The reliable signal is a `displaySize` from the `timeline` stage of a placed widget. That signal is what settled both the iPad Lock Screen and the two Apple Watch placements.

**The iPad accessory frames were never published, and are measured here.** Apple's table has no accessory row for iPad. They are `accessoryCircular` 63×63, `accessoryRectangular` 152×63 and `accessoryInline` 372×36, the same on iPadOS 18.6 and 26.5, and placing them confirmed a Lock Screen widget is drawn at those sizes rather than scaled.

**Measuring a placed widget needs a marking that survives the rendering mode.** The probe paints its container background magenta, which works on the Home Screen and in Today View. The Lock Screen removes the container background and renders vibrant, turning content into a material keyed on luminance, so the magenta never draws. The probe therefore also fills its whole frame with opaque white, which is the brightest thing vibrant mode can produce and is what made the Lock Screen frames measurable. Content margins are disabled, so that fill is exactly the frame.

## Open questions

**Most of the iOS 18 and earlier values are unverified, and most of them are measurable.** Seven of the ten rows in that table are still only Apple's published numbers. Three carry a measurement, and two of those were confirmed indirectly by a device that has no row of its own and fell through to a narrower one.

There is no iOS 19 through 25. Apple renamed its OS versions in 2025 to align them on the year, so the release before iOS 26 is iOS 18, and a value that differs between the two is pinned to iOS 26 exactly.

The iOS 17.5 and 18.6 runtimes are both installed, and both support the older device types, which are simply not created by default. Creating them covers `430x932`, `428x926`, `414x896` at both display scales, `393x852`, `390x844`, `375x812` and `375x667`. Only three rows cannot be reached: `414x736` and `320x568`, whose devices top out at iOS 16 and iOS 15, and `360x780`, which no device reports.

Worth doing for one reason beyond confirming transcription. `414x896` splits by display scale on iOS 26, which is why the lookup key includes the scale, and Apple publishes a single row for it. Both an iPhone 11 at 2x and an iPhone 11 Pro Max at 3x run on iOS 18.6, so whether that split predates iOS 26 is answerable. If it does, the iOS 18 row is wrong for one of those two devices.

**`displaySize` is the trustworthy value; `viewSize` is not.** On iPad the rendered `viewSize` for `systemMedium` and `systemLarge` came back as 341.911765 rather than 342. That is 11625/34, which is not a whole number of pixels, while every `displaySize` is. The gallery appears to render the widget through a transform, so `viewSize` measured there reflects the render rather than the frame.

**`accessoryCorner` reports a frame that does not bound what it draws.** A corner complication is not a rectangle. It sits in the curve of the bezel, roughly triangular, and a label can curve around the frame and extend beyond it. The reported 32x32 on a 162 point wide watch is therefore not a box the content fits inside, which is what every other widget frame in this file means.

That also explains why the numbers do not behave: 32 on a 162 point wide watch, 36 on a 184, 30 on a 187, 34 on a 208 and 39 on a 211, which sorted by screen width is not monotonic. A non-rectangular region's reported size has no reason to scale the way a rectangle's does. `WidgetSize.accessoryCorner` exists as a case and the measurements are recorded here, but no frame is stored, because storing one would imply a bound that does not hold.
