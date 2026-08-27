# Widget frame measurements

Frame sizes reported by WidgetKit on real devices and simulators, captured with the `WidgetSizeProbe` widget extension in `Example/`.

These are the raw measurements behind the `WidgetSize` lookup tables. Apple does not publish a frame for every widget family on every platform, and the published tables lag new devices and OS betas, so measuring is the only way to fill the gaps.

## What cannot be captured in a simulator

**Use the Simulator app from Xcode 26.6, not Xcode 27.** Xcode 27 ships no `Simulator.app` at all; it is replaced by Device Hub, which does not accept injected touch events and has a reduced Settings app. Everything below was retested under the Xcode 26.6 Simulator before being called impossible.

**StandBy.** StandBy needs the device locked, charging and in landscape at once. `simctl status_bar override --batteryState charging` only changes what the status bar draws, not what the system believes about power, so rotating a locked simulator gives a landscape Lock Screen rather than StandBy. `WidgetPlacement.standBy` therefore needs real hardware.

**Display Zoom.** The simulator's Settings app has no Display & Brightness pane, so More Space cannot be turned on. `simctl ui` offers only appearance, contrast and content size, the device type profile defines no zoom variants, and no zoom preference domain exists on a booted device. The three iPad rows marked with a `*` in Apple's table, `1192x1590`, `970x1389` and `954x1373`, therefore keep their published system frames and fall back to the nearest measured screen size for the Lock Screen frames.

Those zoomed sizes are a consistent 1.164 times the native screen size, but the widget frames do not follow that ratio: the small widget goes 170 to 188 on one device, a factor of 1.106, and 155 to 162 on another, a factor of 1.045. There is no way to derive them.

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

On iPad, `displaySize` reports the design canvas, so a rendered frame has to be measured from a screenshot instead. `findwidget.py` decodes a PNG and reports the bounding box of the probe's fill in pixels and points:

```sh
xcrun simctl io <udid> screenshot shot.png
python3 Measurements/findwidget.py shot.png 2            # Home Screen and Today View
python3 Measurements/findwidget.py shot.png 2 bright     # Lock Screen, which renders vibrant
```

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

### Apple Watch — watchOS 27

Measured on every Apple Watch simulator, one per case size. Apple publishes one Smart Stack frame per case size and nothing for the watch face.

| Case | Screen | Smart Stack rectangular | Watch face rectangular | Watch face circular | Corner | Apple publishes |
| --- | --- | --- | --- | --- | --- | --- |
| 40mm | 162×197 | **152×69.5** | **162×69** | **42×42** | 32×32 | 152×69.5 |
| 42mm | 187×223 | 176×72.5 | *none reported* | 47×47 | 30×30 | no row |
| 44mm | 184×224 | **173×76.5** | **184×78** | **47×47** | **36×36** | 173×76.5 |
| 46mm | 208×248 | 194×80.5 | 196×80.5 | 51×51 | 34×34 | no row |
| 49mm Ultra 3 | 211×257 | 197×84 | 199×84.5 | 51×51 | 39×39 | 191×81.5 |

Launching the watch app is enough to capture the frame *values*. No gallery to open and no interaction, which makes watchOS the easiest platform to sweep, and all five case sizes above were swept that way.

**Which frame belongs to which placement is a separate question, and it was answered on two of the five watches.** Bold values are confirmed by a placed widget. The 46mm and Ultra 3 rows assign the smaller frame to the Smart Stack and the larger to the watch face by applying the rule those two established, rather than having been placed themselves.

The rule was tested as a prediction rather than assumed. After the 44mm established it, the 40mm frames were predicted in advance — Smart Stack 152×69.5, watch face 162×69, circular 42×42 — and all three came back as predicted. On the 40mm the same widget was placed in both locations and reported both frames, which is the cleanest form of the result: one widget, two places, two frames.

Both confirmed watches' Smart Stack frames also match Apple's published rows exactly, and Apple's table is explicitly Smart Stack sizes.

The 42mm is the one watch where the sweep reports a single rectangular frame rather than a pair. That reproduces across runs with a long settle, so it is not a truncated capture, but with only one frame there is nothing to attribute and no second value is recorded for it.

#### Every family reports two frames, and which is which had to be established

A registration sweep reports two frames for each family — for 44mm, `accessoryRectangular` at both 173×76.5 and 184×78. Nothing readable at render time says where a render came from, so the placement had to be established rather than assumed.

Two approaches failed. `showsWidgetLabel` does not separate them: both frames appear with it true and false. `disfavoredLocations` does not either, because it does not change what WidgetKit pre-renders — a probe disfavouring the Smart Stack still reported both frames.

What worked is the method that settled the iPad Lock Screen: place the widget and read the `timeline` stage. On a 44mm watch:

| Watch | Placed | Family | `timeline` displaySize |
| --- | --- | --- | --- |
| 44mm | Smart Stack | `accessoryRectangular` | 173×76.5 |
| 44mm | Watch face | `accessoryRectangular` | 184×78 |
| 44mm | Watch face | `accessoryCircular` | 47×47 |
| 44mm | Watch face | `accessoryCorner` | 36×36 |
| 40mm | Smart Stack | `accessoryRectangular` | 152×69.5 |
| 40mm | Watch face | `accessoryRectangular` | 162×69 |
| 40mm | Watch face | `accessoryCircular` | 42×42 |

On both watches the smaller frame of each pair is the Smart Stack and the larger is the watch face.

`disfavoredLocations` does work for what it is for, which both sessions showed: the probe disfavouring the Smart Stack was not offered in the Smart Stack gallery at all, while still appearing in the complications picker. It gates where a widget can be added, not what gets pre-rendered.

#### Findings

**Apple's table has no row for the 42mm and 46mm watches.** Series 10 and 11 case sizes. They resolved to rows meant for a smaller watch, 165×72.5 and 184×80.5, against measured 176×72.5 and 194×80.5.

**Case size does not identify a watch.** The Ultra 2 and Ultra 3 are both 49mm but report 205×251 and 211×257 screens and different Smart Stack frames, 191×81.5 against a measured 197×84. Apple's published 49mm row describes the Ultra 2. Any lookup keyed on case size alone returns the same answer for both and is wrong for one of them.

**A complication is not the same size as a Smart Stack widget.** On the 44mm they are 184×78 and 173×76.5. Apple publishes only the Smart Stack figure, so the watch face frame exists nowhere else.

**`accessoryCircular` was only ever observed placed on the watch face.** Placing it produced a watch face record and the Smart Stack offered rectangular widgets, so it is recorded against the watch face only. That it *cannot* appear in the Smart Stack was not tested. Its watch face frame is the larger of its pair on both the 40mm and the 44mm, and the larger is taken as the watch face frame on the other watches.

**`accessoryInline` has no usable frame.** It reports a small square — 11×11 on the 40mm up to 13.5×13.5 on the 49mm — and never renders, producing only a placeholder record. It is left out of the table rather than recorded as a frame.

**`accessoryCorner` was measured** but has no ``WidgetSize`` case, so it is in the raw data only.

#### Capturing on watchOS

The probe extension needs `xros`-style treatment plus three things specific to watchOS:

- `SDKROOT = auto`, because the Watch App is `watchos` while the extension inherits `iphoneos` and otherwise builds for the wrong platform and is rejected as mismatched embedded content.
- `PRODUCT_BUNDLE_IDENTIFIER[sdk=watch*]` nested under the watch app's identifier, since an embedded binary must be prefixed by its parent app's.
- An embed phase and target dependency on the Watch App, which has neither by default.

`WKInterfaceDevice` supplies the screen size and scale in place of `UIScreen`, which watchOS does not have. It is not main actor isolated, so unlike iOS the screen size is captured whichever thread the provider runs on — worth having, since screen size is the key these frames are stored against.

```sh
xcrun simctl launch <udid> com.abetterwaytodo.FrameUpExample.watchkitapp
```

### macOS and Mac Catalyst

Measured on macOS 26.6.2 with the widget in Notification Center. Apple publishes no widget specifications for macOS at all, so these values exist nowhere else.

| Family | Frame | Pixels at 2x |
| --- | --- | --- |
| `small` | 164×164 | 328×328 |
| `medium` | 344×164 | 688×328 |
| `large` | 344×344 | 688×688 |
| `extraLarge` | 704×344 | 1408×688 |

The frames form a grid with a 16 point gutter: `medium` is two `small` plus a gutter, and `extraLarge` is two `large` plus a gutter.

`extraLargePortrait` did not appear because it arrives in macOS 27 and this Mac runs 26. The accessory sizes do not exist on macOS.

A Mac widget is not placed on a screen grid the way an iPhone widget is, so there is no screen size to key on, and the lookup ignores the screen size passed to it. This was checked: the same widgets report the same frames on a 2560×1440 point external display and on a roughly 1728×1117 point built-in one. Both displays are 2x, so a display of a different scale is still untested, though every Mac that runs macOS 26 has a 2x built-in display.

Widgets in a Mac Catalyst app are hosted by macOS, so the lookup resolves Catalyst to these same frames rather than storing them twice.

#### Capturing on macOS

macOS needs more setup than a simulator. The widget extension has to build for macOS, which means gating the UIKit access, and both the app and the extension need the App Sandbox entitlement or the system will not register the extension at all. The extension's embed phase and target dependency also carry `platformFilter = ios` by default, which silently skips embedding it on macOS.

The probe's unified log output did not appear on macOS and the reason is not yet understood, so these frames were read off the widgets on screen, which the probe view displays for exactly this reason.

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

## Open questions

**The pre-iOS-26 values are unverified.** No iOS 25 or earlier runtime is installed, so the older rows are still only Apple's published numbers. They have never been confirmed by measurement.

**`displaySize` is the trustworthy value; `viewSize` is not.** On iPad the rendered `viewSize` for `systemMedium` and `systemLarge` came back as 341.911765 rather than 342. That is 11625/34, which is not a whole number of pixels, while every `displaySize` is. The gallery appears to render the widget through a transform, so `viewSize` measured there reflects the render rather than the frame.

**Measuring a placed widget needs a marking that survives the rendering mode.** The probe paints its container background magenta, which works on the Home Screen and in Today View. The Lock Screen removes the container background and renders vibrant, turning content into a material keyed on luminance, so the magenta never draws. The probe therefore also fills its whole frame with opaque white, which is the brightest thing vibrant mode can produce and is what made the Lock Screen frames measurable. Content margins are disabled, so that fill is exactly the frame.

**A widget size can have more than one frame on the same device, depending on where it is placed.** An iPad `systemSmall` is 155×155 on the Home Screen and 152×152 on the Lock Screen. A widget placed on the Lock Screen reports 152 from its `timeline` callback, so this is a real placement rather than a preview artefact. 152 points is also the width of `accessoryRectangular`, which suggests the Lock Screen widget column is 152 points wide and a system small placed there is sized to that column.

This is a different axis from ``WidgetTarget``. That distinguishes an iPad's design canvas from its scaled Home Screen frame; this distinguishes one placement from another.

`widgetRenderingMode` does not identify the placement. Both frames appear in `vibrant`, `fullColor` and `accented` renders, because the gallery previews a widget in several modes before it is placed. The reliable signal is a `displaySize` from the `timeline` stage of a placed widget.

**The iPad accessory frames were never published.** Apple's table has no accessory row for iPad and `WidgetSize` documents them as unknown. They are `accessoryCircular` 63×63, `accessoryRectangular` 152×63 and `accessoryInline` 372×36, the same on iPadOS 18.6 and 26.5.
