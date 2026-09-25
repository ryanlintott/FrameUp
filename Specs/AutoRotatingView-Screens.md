# AutoRotatingView on every screen

Status: implemented, verified in the iPhone Duo simulator (no Duo hardware). Pitch pending: passing reserved regions and container corners through the rotation (last section)
Target: FrameUp `AutoRotatingView`. The package stays iOS 15+. The inner-screen behaviour needs iOS 27.1 (`onHingeChange`); earlier versions keep today's logic.

## Decisions

- **One `allowedOrientations` set, because Apple gives apps one.** The only static configuration is `UISupportedInterfaceOrientations` (with the old `~iphone`/`~ipad` variants). Xcode 27.1 has no per-screen key. An app can still vary orientations at runtime (a view controller's `supportedInterfaceOrientations`, or the iOS 27 per-scene `windowScene(_:supportedInterfaceOrientationsFor:)`), and `allowedOrientations` is already a parameter that can change at runtime, so it offers the same power. If the system itself treats the inner screen differently, `AutoRotatingView` must match that.
- **On the Duo inner screen, `allowedOrientations` is ignored, as the system ignores the app's set there** (Findings, Q4). The content always matches the interface orientation, so a portrait-only view becomes landscape when the device is unfolded and held like a folded phone. This is the most literal reading of the goal, chosen over keeping content locked on the inner screen.
- **SwiftUI only.** No `UIViewRepresentable`, no window scene access. The one UIKit dependency is the one `AutoRotatingView` already has: `UIDevice.orientationDidChangeNotification`, because SwiftUI has no device orientation API. The fold comes from SwiftUI's own `onHingeChange` (iOS 27.1).
- **Out of scope: iPad windowed scenes and Stage Manager.** Every window on one screen shares the same physical orientation, so they add nothing new.
- **Measured in the simulator only.** No physical Duo is available. Anything the simulator can't show (fold sensor behaviour mid-fold, real motion data) is recorded as unverified rather than assumed.

## Goal

`AutoRotatingView` should turn its content exactly as the system would turn the whole interface if the app's supported orientations were the view's `allowedOrientations`. That means:

- the content turns **at the same moment** the system would turn it,
- it turns **in the same direction** (the shortest path the system would take),
- it ends up **in the same orientation** the system would choose,

on every screen the scene can appear on, including both screens of the iPhone Duo. Where the system ignores an app's orientation restrictions, as on the Duo inner screen, `AutoRotatingView` ignores `allowedOrientations` too.

## Findings (iPhone Duo simulator, iOS 27.1, 2026-09-24)

Measured with an Orientation Probe screen in the example app (removed once the measurements were done; it's in commit `7a62ca2`), whose iPhone Info.plist allows portrait and `UI.landscapeRight`, and whose iPad key allows all four. Interface orientations use UIKit's names (`UI.`); device orientations use `UIDeviceOrientation`'s.

**Screens.** The simulator has two built-in screens, both with a native orientation of portrait: outer 466x678 pt (1398x2034 px) and inner 669x951 pt (2007x2853 px). A new `UIScreen` instance appears each time the device unfolds, so object identity can't tell them apart; native size can.

**Outer screen: offset 0°.** Device and interface orientation agree whenever the interface rotates. The iPhone Info.plist set is enforced: device upside down and device landscapeRight leave the interface where it was.

**Inner screen: offset is a quarter turn, not 180°.** In every hold orientation, fully open or partly open (127°):

| Device | Inner interface |
|--------|-----------------|
| portrait | `UI.landscapeLeft` |
| landscapeLeft | `UI.portrait` |
| portraitUpsideDown | `UI.landscapeRight` |
| landscapeRight | `UI.portraitUpsideDown` |

So `UIDevice.orientation` is in the outer screen's frame, and the inner screen's own portrait is turned a quarter from it. Holding the unfolded device like a folded phone in portrait gives a 951x669 landscape interface. This matches the hardware: the inner panel is two outer-sized halves side by side.

**Inner screen: the app's Info.plist orientations are ignored.** A second build set all three keys to different sets: base portrait and `UI.landscapeLeft`, `~iphone` portrait and `UI.landscapeRight`, `~ipad` portrait only. On the inner screen it still launched in `UI.landscapeLeft` and rotated through all four orientations. So the inner screen always follows the device, whatever the app declares. Not tested: whether `prefersInterfaceOrientationLocked` or `UIRequiresFullScreen` changes that (the example app sets neither).

**Screen changes follow `UIHinge.Status`, not the angle.** Opening moved the scene to the inner screen as the status went `closed` to `partiallyOpen` (24° and 27° in two runs). Closing moved it back when the status went to `closed`, which it already reported at 83°, so the status has hysteresis. The angle had no other effect on orientation. Device orientation did not change during a fold. The simulator has one orientation value for the whole device, so it can't show whether real hardware reports the orientation of one half while partly folded.

**Timing.** KVO on `windowScene.effectiveGeometry` fires for every rotation and every screen change. The system's rotation transition (`viewWillTransition(to:with:)`) starts within 1 ms of `UIDevice.orientationDidChangeNotification`, so the system rotates as soon as the notification arrives. The geometry KVO follows 40–70 ms later. On a screen change, the geometry event arrives before the window's bounds update.

**Rotation animation: 0.3 s ease-in-out.** The window's layers carry `position` and `bounds.size` animations of 0.3 s with timing curve `(0.42, 0, 0.58, 1)`, which is ease-in-ease-out, and is the same curve as SwiftUI's `.easeInOut(duration: 0.3)`. This was identical on both screens and for every quarter turn. The device notification and the geometry change are delivered inside that animation, so `UIView.inheritedAnimationDuration` reads 0.3 in both. The transition coordinator reports `transitionDuration` 0 and `isAnimated` false, so it can't be used as the source.

**When the system doesn't animate, the inherited duration is 0.** It was 0 for device changes the system ignored (unsupported orientation, or locked), and for the rotation that follows right after a fold (see below). Reading `UIView.inheritedAnimationDuration` in the device notification therefore says whether, and how long, the system is animating.

**The geometry is current by the next run loop turn.** A `DispatchQueue.main.async` from the device notification always saw the new interface orientation when the system rotated, and the unchanged one when it didn't. (The rotation's layout work delays that turn until just after the geometry KVO, about 55 ms.)

**Folding onto the outer screen picks the nearest supported orientation.** The outer screen's orientation is chosen when the scene arrives, from the device orientation at that moment:

| Device when folded | Outer screen chose | Runs |
|--------------------|--------------------|------|
| portrait | `UI.portrait` | 3 |
| portraitUpsideDown (unsupported) | `UI.landscapeRight` (device landscapeLeft, a quarter turn away, rather than portrait, a half turn away) | 3, from two different previous outer orientations |
| landscapeLeft | `UI.portrait` at the screen change, then `UI.landscapeRight` 0.6 s later, *not animated* | 2 |

Folding in landscape, the simulator's device orientation flips to the other landscape at the moment of the screen change (landscapeLeft to landscapeRight), then back about 0.6 s later. The system decides from the flipped value, and portrait is the supported orientation nearest to landscapeRight. The same flip happens in reverse when unfolding in landscape. Whether real hardware does this (perhaps because the sensor is in the half that turns over), or it's a simulator artifact, is unknown. Either way, the system and `AutoRotatingView` see the same notifications. History didn't matter: the previous outer orientation never changed the result.

**Orientation lock.** `prefersInterfaceOrientationLocked` (on a full-screen presented view controller) holds on both screens. `effectiveGeometry.isInterfaceOrientationLocked` becomes true and the interface ignores every rotation. On unfold the lock re-picks the inner screen's orientation to match the device (`UI.landscapeLeft` for device portrait) and then holds it.

**Oddities.** One fold reported a transition to size -19x687, so sizes seen mid-fold can be transient nonsense. In one build the probe's view left its window while folded and missed events, so observers must survive the view being detached.

## Why it breaks today

The current implementation makes two assumptions that held on every iPhone and iPad until the Duo:

1. **Device orientation is the orientation of the screen the app is on.** `changeOrientations()` reads `UIDevice.current.orientation` and treats it as if it were in the screen's frame. On the Duo it is in the outer screen's frame, and the inner screen is a quarter turn from that (see Findings), so on the inner screen every value is off by 90°.
2. **Orientation rules are the same on every screen.** The inner screen ignores the app's orientations and always follows the device, and folding back onto the outer screen picks the nearest supported orientation, neither of which the current logic knows. The Info.plist prediction itself is kept: `Bundle` resolves the `~iphone`/`~ipad` key, and a SwiftUI-only app normally has no other source of orientation restrictions.

## Terms

All orientations below use `FUInterfaceOrientation`, which is named from the device's point of view (`UIInterfaceOrientationLandscapeLeft` maps to `.landscapeRight`).

| Term | Meaning | Source |
|------|---------|--------|
| **Device orientation** | Physical orientation of the device, in the reference frame of the device's primary (outer) screen | `UIDevice.orientationDidChangeNotification` |
| **Restricted screen** | A screen where the system applies the app's supported orientations: every iPhone and iPad screen, and the Duo outer screen. Device orientation is in this screen's frame | Default |
| **Free screen** | A screen where the system ignores the app's supported orientations and always follows the device: the Duo inner screen. Device orientation is a quarter turn off from this screen's frame, but a free screen never needs it | A hinge that isn't `closed` (see Design 1) |
| **Interface orientation** | The orientation the system gave the scene | Predicted from Info.plist and the device orientation (Design 2); measured with UIKit in the probe only |
| **Content orientation** | The orientation `AutoRotatingView` shows its content in | Chosen by this view |
| **Content rotation** | Angle applied to the content: `interfaceOrientation.rotation(to: contentOrientation)`, accumulated to take the shortest path | Derived |

## Design

The probe used UIKit to measure the system. The implementation uses SwiftUI only, so it can't read the scene's interface orientation, its lock, or the inherited animation. It predicts them from the same inputs the system uses, following the measured rules.

### 1. Know which screen the view is on

`.onHingeChange` (SwiftUI, iOS 27.1) gives a `DeviceHingeContext`:

- `hinge` is non-nil and its status is `.partiallyOpen` or `.fullyOpen`: the **inner screen**.
- `hinge` is nil (no hinge), or its status is `.closed`: a **restricted screen** (the Duo outer screen, or any other device).
- Below iOS 27.1 every screen is restricted. No Duo runs those versions.

In the simulator the scene changed screens exactly when the status changed, in both directions, and the UIKit hinge update arrived just before the geometry update. Whether SwiftUI's `onHingeChange` arrives in the same order relative to the view's new size needs checking in the implementation, since a frame laid out at the new size with the old rotation would show.

### 2. Predict the interface orientation (restricted screens)

The system's supported set is `UISupportedInterfaceOrientations` from `Bundle.main.infoDictionary`, as today. `Bundle` resolves the device-specific key itself: with a base key of portrait and `UI.landscapeLeft`, and a `~iphone` key of portrait and `UI.landscapeRight`, it returned the `~iphone` set (measured). The rules, all measured:

- When the device orientation changes to a supported one, the interface turns to it.
- When it changes to an unsupported one, or to face up, face down or unknown, the interface stays.
- When the scene arrives on the outer screen from the inner one, the interface takes the supported orientation nearest to the device orientation (a quarter turn before a half turn). Ties are not measured; take the first in the supported list.
- On first appearance, as today: the device orientation if supported, otherwise the first supported orientation.

What SwiftUI-only can't see, and so can't match:
- a view controller's `supportedInterfaceOrientations` override, or the iOS 27 `windowScene(_:supportedInterfaceOrientationsFor:)`;
- `prefersInterfaceOrientationLocked`.

All three are UIKit configuration, which a SwiftUI-only app doesn't normally have. Control Center rotation lock is not measured.

### 3. Choose the content orientation

**On the inner screen**, the content orientation is the interface orientation. The content rotation is zero. The system ignores the app's orientations there, so `AutoRotatingView` ignores `allowedOrientations` (Decisions).

**On a restricted screen**, the same rules as section 2 applied to `allowedOrientations` instead of the app's set:

- Device orientation changes to an allowed one: the content turns to it. Otherwise it stays.
- Arriving from the inner screen: the allowed orientation nearest the device orientation.
- First appearance: the device orientation if allowed, otherwise the first allowed orientation.

The content rotation is `interfaceOrientation.rotation(to: contentOrientation)`, accumulated to take the shortest path (`closestEquivalent`), as today.

### 4. Timing and animation

- **Timing.** Handle the device notification immediately. The system starts its rotation within 1 ms of the notification (measured), so there's nothing to wait for.
- **When the system is rotating** (the prediction in section 2 changes the interface orientation), make the content change with no SwiftUI animation. The device notification arrives inside the system's UIKit rotation animation, and a change made without a SwiftUI animation is carried by it, with the system's exact timing and curve.
- **When only the content turns**, use `animation`, which defaults to `.easeInOut(duration: 0.3)`, the system's measured rotation animation (0.3 s, curve `(0.42, 0, 0.58, 1)`).
- **Screen changes** (hinge status changes) are not animated. The system replaces the scene's geometry at once.
- If interface and content orientation change together and stay equal, the content rotation is unchanged and nothing extra animates (the current `changeAnimation = nil` case).
- **Known deviation.** Folding in landscape, the system briefly settles to a different orientation and then rotates back *without* animation (Findings). SwiftUI can't tell that rotation apart from an animated one. This is only visible when content and interface orientations differ.

Measured with a green bar inside the content, which should stay level on screen through a system turn, recorded frame by frame:

| Animation during a system turn | Turns | Worst tilt |
|--------------------------------|-------|------------|
| None, joining the system's animation (the default) | 14 | 0.0° every turn |
| `.easeInOut(duration: 0.3)` | 20 | mostly 19–20° |
| `.default` | 26 | mostly 29–31° |

A SwiftUI animation replaces the system's with SwiftUI's own clock, which runs behind.

**Blank corners (accepted).** Mid-turn the window's background shows at some corners. The safe area centring offsets (alignment guides applied before and after the `rotationEffect`) change with the safe area and are interpolated in straight lines in two coordinate spaces while the angle between them changes, so the content drifts off the window's centre until the turn ends. Layout itself runs once per turn (logged), so rounding values doesn't help. A per-frame pivot (`GeometryEffect`) would remove the drift but was not adopted: the workaround is to give content that must cover the screen a background large enough to cover the safe area in every direction. Content-only turns show some background regardless, since a rectangle turning inside a screen of the same size can't cover its corners.

### 5. API

One initializer, as before, with a new default value:

```swift
public init(
    _ allowedOrientations: [FUInterfaceOrientation] = FUInterfaceOrientation.allCases,
    isOn: Bool = true,
    animation: Animation? = .easeInOut(duration: 0.3),
    @ViewBuilder content: () -> Content
)
```

- `animation` applies only when the content turns on its own. When the system rotates the interface, the content change never gets a SwiftUI animation, whatever `animation` is, because any SwiftUI animation falls behind the system's (Design 4). `nil` means content-only turns snap.
- The default changes from `.default` to the measured system animation. Calls that pass an animation compile unchanged and now stay in step during system rotations. Both go in the changelog.
- Screen changes are never animated.
- An earlier draft had two initializers and an `.system`/`.custom` enum so the default could differ from any `Animation` value. Once custom animations also stopped applying during system rotations, the system behaviour became expressible as a plain default value.

### 6. Availability

- iOS 27.1+: the full behaviour, including the inner screen (`onHingeChange`).
- iOS 15 to 27.0: today's logic, with the system-matched default animation. No Duo runs these versions.

## Open questions

These need measuring on the iPhone Duo (a Duo simulator running 27.1 is available; some of these may need the hardware).

**Q1. Which frame is `UIDevice.orientation` in?** *Answered in the simulator: the outer screen's; the inner screen is a quarter turn from it. Needs hardware confirmation.* Original question: Hypothesis: the outer screen, so on the inner screen it's off by 180°. Test: an app supporting all orientations, log device orientation and scene interface orientation together on each screen, holding the device in each of the four orientations. On the outer screen they should agree; on the inner screen the difference is the screen offset. It may also turn out to be 90° or 270° rather than 180° (the inner screen of a book-style foldable is often closer to square, with its natural portrait turned a quarter from the outer screen), so the design keeps the offset general.

**Q2. When partly folded, what drives the orientation?** *Partly answered: which screen the scene is on follows `UIHinge.Status`, and the angle has no other effect. What real hardware reports as the device orientation mid-fold can't be seen in the simulator.* Original question: Is it the orientation of one half (which one?), the outer screen's half, the whole device's average, or something else? At what hinge angle, or `UIHinge.Status`, does the system decide the scene belongs on the inner screen? Is there a point where the device orientation is reported as unknown while the hinge moves? Test: log device orientation, interface orientation, hinge angle and status (via `UIHingeInteraction`, iOS 27.1) while folding slowly in each hold orientation.

**Q3. How do we know which screen the scene is on?** *Answered: the hinge status, via SwiftUI's `onHingeChange` (Design 1). `UIScreen` identity doesn't work (a new instance on each unfold); native size does, but it's device-specific, so it's only the fallback. With option 1 the inner screen's offset is never needed.* Original question: Candidates: `windowScene.screen` identity or its `nativeBounds`/`bounds` size; `UIHinge.Status` (closed means outer, but partly open is ambiguous); inferring the offset by comparing device and interface orientation when both are known to match. Inference only works when the app supports the orientation the device is in, so it can't be the only source.

**Q4. Does the system honour the app's orientations on the inner screen?** *Answered in the simulator: no. The inner screen ignores every Info.plist orientation key and always follows the device (see Findings).* Original question: The developer can't configure a different set per screen, but the system might apply the set differently: for example treating the inner screen like an iPad and ignoring a portrait-only restriction (iOS 27 already ignores `UIRequiresFullScreen`), or letterboxing. Test: a portrait-only build and an all-orientations build, unfolded, in each hold orientation. If the system rotates a portrait-only app on the inner screen, `AutoRotatingView` should too, which means its effective allowed set on that screen is not simply `allowedOrientations`.

**Q5. What does the system do on fold when the device orientation isn't allowed on the outer screen?** *Answered in the simulator: it picks the supported orientation nearest to the device orientation at that moment (Findings). Tie-break not measured.* Original question: Unfolding is settled: the inner screen always follows the device. Folding while the device is in an orientation the app doesn't support (e.g. upside down, with portrait-only) still needs testing: does the outer screen take the first supported orientation, or something else?

**Q6. When does the system start its rotation relative to `UIDevice.orientationDidChangeNotification`?** *Answered in the simulator: immediately (within 1 ms). Decision: turn the content as soon as the notification arrives. Only add a delay if real data shows one.* Original question: Is there a delay or settling period? Does the notification arrive before or after the scene's geometry update? If the geometry update can follow the notification, a content-only turn must wait until we know the scene isn't also going to rotate, or it will start one animation and then get a second.

**Q7. How do we match the system's rotation animation?** *Answered: `.easeInOut(duration: 0.3)`, measured from the window's layer animations. It's the default (Design 4, API).* Original question: The system's rotation has its own duration and curve. Today the view uses the `animation` parameter. Should the default follow the system's animation when the scene rotates (e.g. by applying the change within the transaction of the geometry update), and use `animation` only for content-only turns?

**Q8. Does an orientation lock carry over to the inner screen?** *Answered: yes, `prefersInterfaceOrientationLocked` holds on both screens (Findings). With option 1 the content matches the locked interface, so no extra rule is needed on the inner screen. SwiftUI-only can't see the lock, but setting it needs UIKit, so a SwiftUI-only app won't have one. `UIRequiresFullScreen` not tested.* Original question: The inner screen ignores Info.plist, but `prefersInterfaceOrientationLocked` (iOS 26) or `UIRequiresFullScreen` might still hold it. If one does, it isn't a restriction `AutoRotatingView` can express, but the probe should confirm the free-screen rule doesn't misfire when it happens.

**Q9. How do we know, at the device notification, whether the system is about to rotate?** The system starts rotating at the notification, but its geometry update arrives 40–70 ms later. *Answered with UIKit: `effectiveGeometry.interfaceOrientation` on the next run loop turn is always right. Not used, since the implementation is SwiftUI only: it predicts from Info.plist instead (Design 2).*

## Verification plan

- The Orientation Probe that took the measurements above is in commit `7a62ca2`, if they need repeating on hardware. It showed device orientation, scene interface orientation, their offset, screen size, and hinge status and angle, live and in the unified log with timestamps.
- For each screen and each of the 4 × 4 combinations of (previous, new) orientation, with the app supporting all orientations and supporting only portrait, compare the system's result against `AutoRotatingView`'s. A side-by-side check: run the same content once as a plain view in an app restricted to the allowed set, and once inside `AutoRotatingView` in an app that allows all orientations. Record both and compare the timing and direction of the turn frame by frame, using the recording approach already used for the safe area work.
- Existing checks stay: safe area insets map correctly at rest and mid-rotation, on an odd-width device (iPhone 15 Pro) as well as the Duo.

## Pitch: passing reserved regions and container corners through the rotation

Status: steps 1 and 3a done (2026-09-25). Step 3b not started.

### Problem

`AutoRotatingView` re-creates the safe area inside the rotation, so content that reads or respects the safe area gets values in its own, rotated frame. It doesn't do the same for the two other kinds of container geometry SwiftUI exposes:

- **Reserved regions** (`GeometryProxy.reservedRegions(kind:options:layoutDirectionBehavior:)`, iOS 27.1). There are two kinds: `.occlusion`, an area covered by something the view doesn't own (the Dynamic Island, a camera, window controls), and `.division`, where content should split (the fold of a hinge). Each region has a `frame`, `margins`, `isActive` and an `id`.
- **Container corners**:
  - `GeometryProxy.containerCornerInsets` (iOS 26), the overlap of the view with the container's corners, which can include system UI and window or presentation corner radii. The `containerCornerOffset(_:sizeToFit:)` modifier (iOS 26) uses the same information to move a view clear of the corners.
  - The container *shape*, which drives `GeometryProxy.concentricCornerRadii` (iOS 27.0), `ConcentricRectangle` and `ContainerRelativeShape`.

A view inside the rotation that reads any of these may get values for the unrotated container. For example, portrait-only content shown in a landscape interface would find the camera on its left edge instead of its top. It might also get nothing, or axis-aligned bounds of rotated shapes. Which of these happens is unknown until measured (step 1).

### What SwiftUI lets a view supply to its children

| Value | Read with | Supply to children with |
|---|---|---|
| Safe area | `safeAreaInsets` | `safeAreaInset(edge:)`, already used by `AutoRotatingView` |
| Reserved regions | `reservedRegions(kind:…)` | Nothing. There's no modifier, and `ReservedRegion` has no public initializer |
| Container corner insets | `containerCornerInsets` | Nothing. `RectangleCornerInsets` has a public initializer, but no modifier accepts it |
| Container shape | `concentricCornerRadii` | `containerShape(_:)`, which takes any `RoundedRectangularShape`, including `UnevenRoundedRectangle(cornerRadii:)` (iOS 26) |

So only the container shape can be passed through so that SwiftUI's own APIs report the right values. The other two need a FrameUp API, or a documented limitation.

### Step 1: measure what content sees today

SwiftUI converts reserved regions and corner insets into the reading view's coordinate space. If that conversion includes `rotationEffect`'s transform, the values may already be right, or be close (for example, rotated frames reported as bounds). Before building anything:

- Add a probe to the example app. Inside a portrait-only `AutoRotatingView`, draw each reserved region's `frame` and `margins`, and label the four `containerCornerInsets` and the `concentricCornerRadii`. Outside the rotation, draw the same values from an unrotated reader for comparison.
- Devices, all simulator:
  - **iPhone Duo outer screen:** the camera is an occlusion region, and it's the only screen where content rotates.
  - **iPhone Duo inner screen:** has the fold as a division region. `AutoRotatingView` doesn't rotate here, so values should pass through unchanged, which confirms the baseline.
  - **An iPhone with a Dynamic Island,** for a second occlusion shape.
  - **iPad full screen,** where corner insets are expected to be zero, and **iPad windowed,** where they aren't.
- Check each of the four resting content rotations against the unrotated reference.
- Compare the reserved regions with the corner insets, to see whether corners already appear as regions. The docs overlap: occlusion regions include "window controls", and corner insets "may include pieces of system UI". An iPad window with its controls showing should appear in both if they're the same thing. Also check whether a screen's rounded display corners produce any occlusion region.
- Read `concentricCornerRadii` from a full-size reader on each screen, corner by corner. The Duo's corners are expected to differ, with only some rounded. Also check whether it's nil when the app sets no `containerShape`. `ConcentricRectangle`'s docs say the device's own rounded corners act as a container shape, but `concentricCornerRadii` is documented as nil "if no container shape is set", and step 3a needs a value to rotate.

If step 1 shows correct values, the work is documentation and a test. The rest of this pitch assumes they're wrong.

**Results so far (2026-09-25, Container Geometry Probe in the example app, full-size reader, no rotation):**

The iOS 27.1 simulator runtime only supports the iPhone Duo, so reserved regions (iOS 27.1) can only be read there. An iPad has to run iOS 27.0, where only the corner APIs exist.

| Device | Size | Corner insets TL / TR / BL / BR | Occlusion regions | Division regions |
|---|---|---|---|---|
| iPad Pro 13" (M5), iOS 27.0, full screen | 1032×1376 | 32×32 on all four | not readable (27.0) | not readable |
| Same iPad, windowed | 532×791 | **66×53** / 32×32 / 32×32 / 32×32 | not readable | not readable |
| iPhone Duo outer screen, iOS 27.1, portrait | 466×678 | 8×8 / **84×170** / 8×8 / 59×59 | **(382, 0) 84×170**; (399.7, 29.3) 37×37 | none |

- **System UI in a corner comes through as both.** On the Duo, the top-trailing capsule holding the camera, clock and Wi-Fi is an occlusion region *and* the top-trailing corner inset, with an identical 84×170 rectangle. The camera inside it is also its own, smaller occlusion region. By the same logic, the iPad's window controls (the 66×53 top-leading inset) are probably a region too, but that can't be checked until an iPad runs 27.1.
- **Rounded display corners are corner insets but not regions.** The iPad's 32×32 and the Duo's 8×8 and 59×59 appear only as corner insets. The docs say full-screen corner insets are zero on iPad; measured, they're the display's corner radius.
- **The Duo's outer screen corners are uneven:** 8×8 on the leading side (the fold side) and 59×59 at bottom trailing. So corner values rotated by `AutoRotatingView` have to move per corner (steps 2 and 3a).
- **`containerCornerOffset([.top, .leading])`** moved a label clear of the iPad's window controls, to x = 66.
- **The values settle over several layout passes.** On the Duo, the corners read all zero on the first pass, then the capsule's corner, then the radii, and the regions came last. Anything built on them must update as they change, not read them once.
**Inside an `AutoRotatingView` (Duo outer screen, iOS 27.1, device in portrait).** The view's only allowed orientation was changed so that it turned its content without the device rotating. A full-size reader inside the content reported, once settled:

| Content orientation | Occlusion regions | Corner insets TL / TR / BL / BR | Concentric radii TL / TR / BL / BR |
|---|---|---|---|
| Outside, for reference | capsule (382, 0) 84×170; camera (399.7, 29.3) 37×37 | 8×8 / 84×170 / 8×8 / 59×59 | 8 / 59 / 8 / 59 |
| Inside, portrait | same as outside | same as outside | same as outside |
| Inside, landscapeLeft | capsule (0, 0) 170×84; camera (29.3, 29.3) | 8×8 / 59×59 / 8×8 / 59×59 | 8 / 59 / 8 / 59 |
| Inside, landscapeRight | capsule (508, 382) 170×84; camera (611.7, 399.7) | 8×8 / 59×59 / 8×8 / 59×59 | 8 / 59 / 8 / 59 |
| Inside, upside down | capsule (0, 508) 84×170; camera (29.3, 611.7) | 8×8 / 59×59 / 8×8 / 59×59 | 8 / 59 / 8 / 59 |

- **Reserved regions are already correct.** SwiftUI maps them through the rotation: in every orientation the capsule and camera land where they physically are, in the content's coordinates, with width and height swapped on a quarter turn. `AutoRotatingView` doesn't need to do anything for regions.
- **Corner insets and concentric radii are wrong.** They're never rotated: every orientation reports the unrotated 8/59 pattern, and the capsule's 84×170 corner inset disappears altogether. Correct values for landscapeLeft, for example, would be corner insets 170×84 / 59×59 / 8×8 / 8×8 and radii 59 / 59 / 8 / 8.
- **`containerCornerOffset` is wrong as a result.** With the content turned to landscapeLeft, the label it positions sat on top of the capsule instead of beside it.
- **`concentricCornerRadii` isn't nil without a `containerShape`.** The device's rounded corners act as the container shape, so step 3a has values to rotate.
- **Values change on every frame of a content turn.** A reader inside the rotation reports regions and corners of the turning content, as bounding boxes, for the whole animation.
**Duo inner screen (iOS 27.1, unfolded, device in portrait, interface 951×669).** Outside and inside the `AutoRotatingView` reported identical values, as expected, since `AutoRotatingView` doesn't rotate on the inner screen:

| Corner insets TL / TR / BL / BR | Concentric radii | Occlusion regions | Division regions |
|---|---|---|---|
| 55×55 / 84×120 / 55×55 / 55×55 | 55 on all four | capsule (867, 0) 84×120; an inactive region at (677.3, 21) 58×37 | the fold: (455.5, 0) 40×669, margins 0, 20, 0, 20 |

- **The fold is a division region:** a 40 pt strip centred on the screen (475.5 = 951 ÷ 2), full height, with 20 pt margins on each side. It switched between active and inactive while the screen was open. What drives that (the hinge angle, or something else) isn't known.
- **The inner screen's corners are uniform** (55 pt), unlike the outer screen's.
- **The corner capsule is again both a region and a corner inset,** with an identical 84×120 rectangle, as on the outer screen.
- **Values changed during the unfold,** passing through the outer screen's values and intermediate capsule sizes (such as 134×82) before settling.
- Windowed apps on the inner screen: not checked.

### Step 2: the transform

Read everything outside the rotation from the full-size reader (the `fullProxy` that ignores the safe area, whose frame the content fills), and map it into the content's coordinate space. The content frame is `rotatedFullSize`, centred in `fullSize`, and turned by a whole number of quarter turns θ about the centre. So:

- A point `p` in the container maps to `R(−θ)(p − fullSize/2) + rotatedFullSize/2` in the content.
- Rectangles map corner to corner and stay axis-aligned, because θ is always a quarter turn at rest.
- `EdgeInsets` (region margins) rotate exactly as the safe area does, with the existing `EdgeInsets.rotated(by:layoutDirection:)`.
- Corners move one step per quarter turn, and each corner's `CGSize` swaps width and height on odd quarter turns. Leading and trailing follow the layout direction, as the insets helper already handles.
- Read regions with `layoutDirectionBehavior: .fixed` before rotating, and mirror afterwards if the caller asks for `.mirrors`. That way the physical rotation and the right-to-left mirroring aren't mixed up.

Values change at layout, once per turn, like the safe area (measured: layout runs once per turn, and SwiftUI interpolates the rendering).

### Step 3a: container shape, through SwiftUI

Inside the rotation, apply `.containerShape(UnevenRoundedRectangle(cornerRadii: rotatedRadii))`.

- **Where the radii come from:** `rotatedRadii` starts from the full-size reader's `concentricCornerRadii`. A reader that fills the container shares its corners, so its concentric radii are the container's own radii.
- **Each corner moves with the rotation.** The radii aren't necessarily uniform: on a screen where only some corners are rounded, such as the Duo's (to be confirmed in step 1), a quarter turn has to move each radius to the content corner that now sits on that physical corner. `UnevenRoundedRectangle` takes a radius per corner, so this works. A single radius, or radii left unrotated, would round the wrong corners.
- **Corners are named leading and trailing**, like the insets, so the mapping follows the layout direction in the same way.
- **Always applied, square until the radii are known.** Leaving the shape off while `concentricCornerRadii` is nil would change the content's view identity when the radii arrive, and they settle over several layout passes (step 1), which would reset the content's state. So from iOS 27 the modifier is always there, and a nil reading gives square corners until the real radii arrive. In practice it isn't nil (step 1).

This makes `ConcentricRectangle`, `ContainerRelativeShape` and `concentricCornerRadii` correct inside the rotation with no new API, and it reaches system views too. `UnevenRoundedRectangle` animates, so the shape can follow the turn. On the Duo's inner screen the content isn't rotated, so the radii pass through unchanged.

**Built (2026-09-25):** `RectangleCornerRadii.rotated(by:layoutDirection:)` (tested, including right to left) and an internal `containerCornerRadii(of:rotatedBy:layoutDirection:)` modifier, applied to the content after its `rotatedFullSize` frame. Gated on `canImport(SwiftUICore, _version: 8.0.84)` and iOS 27, because the radii are read with `concentricCornerRadii`. The shape modifier itself exists from iOS 26, but there's nothing to read the radii from before 27.

**Results (Duo outer screen, iOS 27.1, device in portrait), read by the probe's full-size reader inside the content once settled:**

| Content orientation | Concentric radii TL / TR / BL / BR | Corner insets TL / TR / BL / BR |
|---|---|---|
| Portrait | 8 / 59 / 8 / 59 | not recorded |
| landscapeLeft | **59 / 59 / 8 / 8** | 59×59 / 59×59 / 8×8 / 8×8 |
| landscapeRight | **8 / 8 / 59 / 59** | not recorded |
| Upside down | **59 / 8 / 59 / 8** | not recorded |

- **The container shape overrides the device corners.** That was the untested assumption, and it holds. Every orientation now reports the physical corners in the content's own frame.
- **It also fixes SwiftUI's `containerCornerInsets` for rounded corners, but not for system UI.** In landscapeLeft the insets used to read the unrotated 8 / 59 / 8 / 59 pattern. Now they follow the shape: 59×59 / 59×59 / 8×8 / 8×8. But the capsule's corner should read 170×84 at top leading, and it reads 59×59. The shape only carries radii, so the capsule's part of the inset is still lost. Step 3b still has to supply it, and `containerCornerOffset` still won't clear the capsule inside a rotation.
- **During a turn the radii animate,** starting from zero, since the turning content's corners leave the container's corners. They settle on the rotated values at the end.
- **Not checked yet:** the purple `ContainerRelativeShape` outline the probe now draws. The simulator's display showed only black to screenshots throughout this session, so everything here comes from the probe's log.

### Step 3b: corner insets, through a closure parameter

SwiftUI can't be given corner insets, and the only place they go wrong is inside the rotation. So `AutoRotatingView` hands them to its content, the way `GeometryReader` hands over a proxy:

```swift
AutoRotatingView([.portrait]) { geometry in
    Content()
        .padding(.leading, geometry.containerCornerInsets.topLeading.width)
}
```

- **A new initializer overload** takes a `@ViewBuilder` closure with the geometry parameter. The existing initializer stays, so nothing breaks.
- **The parameter is a FrameUp type,** for example `AutoRotatingGeometry`, because `GeometryProxy` has no public initializer. It holds, in the content's coordinate space and already mapped through the rotation (step 2):
  - `size`, the content frame (`rotatedFullSize`);
  - `safeAreaInsets`, the re-created safe area;
  - `containerCornerInsets`, an inset amount for each corner of the content, rotated with it, for use as padding or offsets:
    - **Why it's separate from the regions:** measured on the Duo, the corner areas aren't all reserved regions. Only the corner holding system UI (the top-trailing capsule) is also an occlusion region. The rounded display corners are corner insets only (step 1 results). So views that need to stay clear of the corners need these values as well as the regions.
    - **Type:** SwiftUI's `RectangleCornerInsets`, a `CGSize` for each of `topLeading`, `topTrailing`, `bottomLeading` and `bottomTrailing`. It has a public initializer, and SwiftUI's `EdgeInsets.inset(by:edges:)` turns it into padding, so FrameUp's value works anywhere SwiftUI's does.
    - **Availability:** `RectangleCornerInsets` needs iOS 26, while `AutoRotatingView` supports iOS 15. A stored property can't be limited by `@available`, so the geometry stores the four sizes itself and exposes `containerCornerInsets` as a computed property available from iOS 26. That matches where SwiftUI's own value exists.
    - **Rotation:** each corner's inset moves to the content corner that now sits on that physical corner, and swaps width and height on a quarter turn (step 2). On the Duo's outer screen, a quarter turn moves the 84×170 capsule inset to another content corner as 170×84.
    - **Using it:**

      ```swift
      AutoRotatingView([.portrait]) { geometry in
          Content()
              .padding(.top, geometry.containerCornerInsets.topTrailing.height)
      }
      ```
- **For views deeper in the content, or smaller than it:** like a proxy, the values describe the frame they came from, here the whole content. `AutoRotatingView` names the content's coordinate space, and the geometry has overloads that take the reader's own proxy and resolve the values for that reader's frame:
  - `containerCornerInsets(in: proxy)` intersects the reader's frame with each corner area, as SwiftUI does. A reader that touches no corner gets zero.

  Passing `geometry` down to those views is left to the caller, as with any value in SwiftUI.
- **Reserved regions aren't on the geometry.** Measured, SwiftUI already maps them through the rotation correctly (step 1 results), so content reads them from its own `GeometryProxy` as usual.
- **Concentric corner radii aren't on the geometry.** Step 3a makes SwiftUI's own `concentricCornerRadii` correct inside the rotation, for system views too.
- **Implementation:** the closure has to be stored and called in `body`, as `GeometryReader` does, rather than evaluated once in `init` as the content is today. A stored escaping `@ViewBuilder` closure in a custom container is where stale `@State` can appear (a view shows an old value the first time and the right one after), so follow the stale-closure guidance and test for it.

**Limits:** views that call SwiftUI's `containerCornerInsets` or `containerCornerOffset` directly, including system views, still get SwiftUI's unrotated values, which are wrong inside a rotation (step 1 results). A FrameUp equivalent of `containerCornerOffset(_:sizeToFit:)` could be built on the geometry, but is a separate decision.

**Considered and set aside: environment values.** One environment value for each feature, holding the container's values in a named coordinate space and resolved through the reader's proxy, with a public modifier to publish them anywhere in an app. It works deep in a tree without passing anything down. But the app-wide writer only exists for consistency, since SwiftUI's values are already correct outside a rotation. It also raises questions that the closure avoids: an empty default when there's no writer, and unique space names when writers nest. It could come back later as an optional convenience on top of the closure.

### Availability

| API | Runtime | Compile-time gate |
|---|---|---|
| `ReservedRegion`, `reservedRegions` | iOS 27.1 | `canImport(SwiftUICore, _version: 8.0.85)`, as `onDeviceScreenChange` uses |
| `concentricCornerRadii` | iOS 27.0 | SwiftUICore 8.0.84 in the iOS 27.0 SDK; confirm the threshold |
| `containerCornerInsets`, `containerShape(some RoundedRectangularShape)`, `UnevenRoundedRectangle` as that shape | iOS 26.0 | The iOS 26 SDK version, not yet looked up (no Xcode 26 installed) |

Below those versions, `AutoRotatingView` behaves as it does today.

### Decisions on this pitch

- **Build 3b,** the closure parameter.
- **No rotation on the geometry.** The content orientation and angle aren't included unless a need for them turns up.
- **Corner insets stay separate from reserved regions.** SwiftUI's `ReservedRegion.Kind` has no public initializer, so FrameUp can't add a corner kind to SwiftUI's kinds. It could only add one to its own mirror type, which would then disagree with SwiftUI about what a region is. The two also answer different questions: a region is a fixed frame that any intersecting view avoids, while corner insets are resolved per reader as the overlap with each corner. Step 1 checks whether any corner geometry already appears as a region. If it does, the geometry passes it through like any other region.
- **Naming** is to be reviewed later.

- **Corner insets go on the geometry, per corner.** Measured, the corner areas aren't included in the reserved regions (step 1), so `containerCornerInsets` carries an inset for each corner, as SwiftUI's `RectangleCornerInsets`.

- **Regions dropped from the geometry.** Measured, SwiftUI rotates reserved regions correctly, so only corner insets (3b) and the container shape (3a) need FrameUp's help.

### Questions still open

1. Should FrameUp offer its own `containerCornerOffset` equivalent built on the geometry?
2. Naming: the geometry type (`AutoRotatingGeometry`?) and the region type (`FUReservedRegion`?).
