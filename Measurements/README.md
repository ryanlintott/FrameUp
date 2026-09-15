# Widget frame measurements

Apple does not publish a frame for every widget family on every platform, and the frames it does publish describe iOS 18 and earlier. FrameUp fills the gaps by measuring, using the `WidgetSizeProbe` widget extension in `Example/`.

The measured values live in one place, [`WidgetFrameRecord+all.swift`](../Sources/FrameUp/Widget/WidgetFrameRecord+all.swift). Each row carries a `// Measured on` or `// Confirmed on` comment naming the device and OS it came from. This folder holds the tools used to take a measurement and the rules the table relies on.

| File | Role |
| --- | --- |
| `Example/WidgetSizeProbe/` | The probe widget, embedded in the example apps |
| `Measurements/probelog.swift` | Reads the probe's log and summarises the frames it reported |
| `Measurements/findwidget.swift` | Measures a placed widget from a screenshot |

## The probe

- It declares every family the OS might offer, not the ones `WidgetSize` believes are supported, so a family the library has wrong still gets measured. WidgetKit ignores families the device cannot show.
- Content margins are disabled, so the body is exactly the frame.
- Each provider callback logs `TimelineProviderContext.displaySize` as one JSON line, tagged `placeholder`, `snapshot` or `timeline`. The body also logs the size it was laid out in, tagged `render`. Records go to `os.Logger` on subsystem `com.abetterwaytodo.FrameUpExample.WidgetSizeProbe`.
- It draws its own `displaySize` as text over a magenta container background, which shows in a screenshot on the Home Screen and in Today View. Wherever the container background is not drawn it fills its frame with opaque white instead, which survives the Lock Screen's vibrant rendering. The white is clear everywhere else, since a full bleed white would hide the magenta.

## Measuring

Every step can be run by Claude against a simulator. Xcode 27's Device Hub accepts the taps, swipes and screenshots needed to open the widget gallery and place a widget, so nothing below needs to be done by hand.

1. **Install.** Build the example app for the target simulator and install it. The probe comes with it.

   ```sh
   xcodebuild -workspace Example/FrameUp.xcworkspace -scheme FrameUpExample \
     -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=27.0' -derivedDataPath /tmp/probe build
   xcrun simctl install booted /tmp/probe/Build/Products/Debug-iphonesimulator/FrameUpExample.app
   ```

   Name the OS in the destination, since the same device name usually exists in more than one runtime. Use the `FrameUpWatchExample Watch App` scheme for Apple Watch.

2. **Make WidgetKit render every family.**

   | Platform | How |
   | --- | --- |
   | iPhone, iPad | Long press the Home Screen, tap Edit, Add Widget, and open the FrameUp entry. The gallery renders every supported family. |
   | Apple Watch | Launch the watch app. |
   | visionOS | Launch the app, then launch the gallery with `xcrun simctl launch booted com.apple.RealityWidgets`. |
   | macOS | Add the widgets to the desktop and read each frame off the widget itself. The probe's log does not appear on macOS. |

3. **Read the log.**

   ```sh
   Measurements/probelog.swift --last 5m
   ```

   The summary shows each family's frames by stage group, with a count beside any size reported more than once.

4. **Place the widget, only where the frame depends on placement.** The gallery reports the same frame a placed widget does, so most measurements stop at step 3. Place the probe in one place only, let it render, and run `probelog.swift --placement <placement>` with a window that starts after the placing. Capture one placement before making the next, because a widget already placed keeps reporting.

   | Frame | Why placing is needed |
   | --- | --- |
   | iPad Lock Screen `systemSmall` | The gallery pre-renders both the Home Screen and Lock Screen frame |
   | Apple Watch watch face and Smart Stack | Every family is pre-rendered at two frames, one for each place |
   | iPad rendered frames on the Home Screen and in Today View | `displaySize` reports the design canvas, so the drawn size has to come from a screenshot |

   For a screenshot measurement:

   ```sh
   xcrun simctl io booted screenshot shot.png
   Measurements/findwidget.swift shot.png 2            # Home Screen and Today View
   Measurements/findwidget.swift shot.png 2 bright     # Lock Screen, which renders vibrant
   ```

   The second argument is the display scale. An optional fourth, `x,y,width,height` in pixels, narrows the search. The measured box can read up to one pixel short on each side.

5. **Record it.** Update the row in `WidgetFrameRecord+all.swift`, writing frames in pixels where the table does, and set the provenance comment to the device model and OS version. Run the tests, since `minimumSize` and `maximumSize` are derived from the table.

For Display Zoom, turn on Settings > Developer > Display Zoom > More Space and let the device restart. The probe records `screenSize`, so check it shows the zoomed size before trusting the frames.

### Reading the stage groups

| Group | Records | Meaning |
| --- | --- | --- |
| `placed` | `snapshot` or `timeline` with `isPreview` false | A widget that is really on the device. The only group that says anything about placement. |
| `preview` | anything with `isPreview` true | A gallery or picker browse. |
| `pre-rendered` | `placeholder` | Every frame WidgetKit intends to pre-render, including a family's pair of placement frames. |
| `rendered` | `render` | The laid out body. Not trustworthy on iPad, where the gallery renders through a transform and reports sizes such as 341.91 that are not whole pixels. |

Trust `displaySize`. Count records rather than distinct sizes: the 42mm watch pre-renders `accessoryRectangular` twice at the same 176×72.5, which looks like a family with one frame until the records are counted.

### What cannot be measured in a simulator

- **StandBy** needs the device locked, charging and in landscape. The simulator's charging state is cosmetic, so `WidgetPlacement.standBy` needs real hardware.
- **CarPlay** runs in the simulator as an external display, but touches never reached it in the Xcode 26 Simulator. It has not been retried with Device Hub.
- **Older Apple Watches** (the 38mm, the Series 1 to 3 42mm, 41mm, 45mm and Ultra 2) have no simulator in the watchOS 26 or 27 runtimes. They keep Apple's published Smart Stack frame.

## Rules the table relies on

**Frames land on whole pixels.** Values are fractional exactly when the pixel count is not divisible by the scale, which is why the measured rows are written in pixels.

**iPhone frames changed in iOS 26.** The same iPhone 13 reports 158 / 338×158 / 338×354 on iOS 18.6 and 162 / 342×162 / 342×358 on iOS 26.5. The accessory frames changed by more: `accessoryInline` is 36 points tall on every iPhone, where Apple publishes 26. Every iOS 18 frame measured so far matches Apple's published value, including screen sizes Apple never published a row for, so iPhone needs exactly two variants per screen size. iOS 26 and 27 agree.

**Screen size and OS determine the frame, except where scale splits it.** Devices sharing a screen size report identical frames. The one exception is 414×896, which is 2x on an iPhone 11 and 3x on an iPhone 11 Pro Max and reports different frames for every family from iOS 26. That is why display scale is part of the key.

**iPad frames did not change in iOS 26.** iPadOS 18.6, 26.5 and 27.0 agree.

**An iPad has two frames on the Home Screen and one on the Lock Screen.** `displaySize` is the design canvas. The Home Screen scales it into a slot on an exact grid of cells and gutters, which is how the rendered `extraLargePortrait` frames are derived: two cells by three, confirmed by a placed widget on an 820×1180 iPad. Lock Screen widgets are not scaled, and the Lock Screen `systemSmall` is exactly as wide as `accessoryRectangular`.

**A Display Zoom frame cannot be derived from the native one.** Zoomed screens are a consistent 1.163 times their native size, but their frames grow by between 1.045 and 1.106, and a zoomed 820×1180 iPad's Lock Screen frames shrink. Every zoomed row is measured.

**Where a widget is placed can change its frame, and only a placed widget says which.** `widgetRenderingMode`, `showsWidgetLabel` and `disfavoredLocations` do not identify a placement. A `placed` record does.

**On Apple Watch, the smaller of a pair is usually the Smart Stack frame, but not always.** On the 42mm both frames are 176×72.5. Place the probe on a new watch rather than predicting. Case size does not identify a watch: the Ultra 2 and Ultra 3 are both 49mm with different screens and frames. Watch face frames do not vary between watch faces, and a watch keeps its face configuration across installs, so placed widgets report again after a reinstall.

**Two watch families have no usable frame.** `accessoryInline` reports a small square and never renders. `accessoryCorner` reports a frame that does not bound what it draws, since a corner complication is not a rectangle, and the values do not scale with screen width. `WidgetSize.accessoryCorner` exists as a case with no frame.

**visionOS frames sit on a 158 point grid with a 38 point gutter.** Apple's published visionOS row is wrong for every family but `small`, and 26.5 and 27.0 agree, so it was never right. The accessory families arrive in visionOS 27, and visionOS has no `accessoryInline`. visionOS records have no screen size or scale.

**macOS frames sit on a grid with a 16 point gutter** and do not depend on the display. `extraLargePortrait` arrives in macOS 27 as `extraLarge` turned on its side. Mac Catalyst widgets are hosted by macOS and use the same frames.

## Open questions

- **Seven of the ten iOS 18 iPhone rows are unverified.** The iOS 17.5 and 18.6 runtimes support every older device type except those reporting 414×736, 320×568 and 360×780. Measuring an iPhone 11 and an iPhone 11 Pro Max on 18.6 would also show whether the 414×896 scale split predates iOS 26.
- **Why the probe's log does not appear on macOS** is not understood.
- **A Mac display at a scale other than 2x** is untested.
