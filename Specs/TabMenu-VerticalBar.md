# TabMenu in the iPhone Duo's vertical bar

Status: implemented (uncommitted), measured in the iPhone Duo simulator (iOS 27.1, no Duo hardware)
Target: FrameUp `TabMenu`. The package stays iOS 15+. The vertical layout needs iOS 27.1 (`toolbarVerticalEdge`, `reservedRegions`); earlier versions keep today's horizontal bar.

## Decisions

- **SwiftUI only.** iOS 27.1 SwiftUI reports everything needed: which edge the system's vertical bar is on (`EnvironmentValues.toolbarVerticalEdge`), and where the camera and status items sit inside it (`GeometryProxy.reservedRegions(kind: .occlusion)`). No UIKit, no window access. UIKit was used only to measure the system tab bar, in a temporary probe.
- **Follow the system, not the device.** `TabMenu` goes vertical exactly when the system would draw its own tab bar vertically, on the edge the system uses. It never works that out from device orientation, screen size or hinge state.
- **Keep TabMenu's own look, with names.** The system's vertical tab bar is a Liquid Glass capsule with icons only. `TabMenu` keeps its iOS 15–18 look (masked icon and name), laid out as a column.
- **A new modifier places the menu.** `TabMenu` placed by hand in a `VStack` stays horizontal, so existing layouts don't change. A new `.tabMenu(...)` modifier places the menu for the current screen, including in the column.
- **Match the system's vertical position.** The stack's bottom is where the system puts its capsule's bottom, not the bottom safe area edge.
- **`toolbarVerticalEdge` is nil on every device except the Duo.** Assumed, not measured, since only the Duo simulator runs iOS 27.1 here.

## Goal

On any screen where the system puts its bars in a vertical column (the Duo outer screen in every orientation, and the Duo inner screen in landscape), `TabMenu` sits in that column, on the same edge as the system's tab bar, stacked top to bottom, clear of the camera and status items, and works the same on the leading and trailing edges. Everywhere else it stays the horizontal bar it is today.

## Findings (iPhone Duo simulator, iOS 27.1, 2026-09-24/25)

Measured with a temporary probe screen in the example app, since removed: a system `TabView` with the same four items as `TabMenuExample` (and with 6 and 10 items), a bare view with no tab bar, and today's `TabMenu`. The probe logged SwiftUI's view of its container (safe area, `toolbarVerticalEdge`, `contentMargins(for: .container)`, reserved regions) and SwiftUI's hinge status (`onHingeChange`), next to a UIKit readout of the window and the system tab bar's frames. For this measurement only, the iPhone Info.plist was set to all four orientations.

### The vertical column belongs to the system, not the tab bar

The Duo reserves an **84 pt column** along one side of the window for the camera and status bar. It is there with no tab bar at all (bare view: safe area trailing 84, bottom 34, top 0). The system `TabView` puts its tab bar *inside* that column and adds no safe area of its own. On the Duo outer screen the status bar is drawn down the column, not across the top: `statusBarFrame` reports a 2 pt strip and the top safe area is 0.

### Where the column goes

Settled states. Frames are in window points. Interface orientations use UIKit's names (`UI.`).

| Screen | Interface | Window | `toolbarVerticalEdge` | Safe area | Occlusion regions (camera, status) | System tab bar |
|---|---|---|---|---|---|---|
| Outer | `UI.portrait` | 466×678 | trailing | trailing 84, bottom 34 | top of column: `[382,0 84×170]`, camera `[399.7,29.3 37×37]` | vertical capsule `[394,442 48×212]`, bottom 24 above the edge |
| Outer | `UI.landscapeRight` (device landscapeLeft) | 678×466 | leading | leading 84, bottom 34 | top of column: `[0,0 84×82]`, camera at top left | `[24,230 48×212]`, bottom 24 above the edge |
| Outer | `UI.landscapeLeft` (device landscapeRight) | 678×466 | trailing | trailing 84, bottom 34 | **bottom** of column: `[594,384 84×82]`, camera `[611.7,399.7 37×37]` | `[606,172 48×212]`, bottom at 384, the top of the occlusion region |
| Outer | upside down | — | — | — | — | the system doesn't rotate to it, even with all orientations allowed |
| Inner | `UI.landscapeLeft` or `UI.landscapeRight` | 951×669 | trailing | trailing 84, bottom 34 | top of column: `[867,0 84×120]`; inner camera region reported but inactive | `[879,433 48×212]`, bottom 24 above the edge |
| Inner | `UI.portrait` or `UI.portraitUpsideDown` | 669×951 | **nil** | top 82, bottom 34 | status bar across the top: `[535,0 134×82]` | horizontal capsule 400×62 at the bottom, with labels, adding bottom safe area |

- **Outer screen:** the column follows the camera. The camera is at the top right in portrait, so the column is on whichever side the camera is on, and in one landscape the camera ends up at the *bottom* of the column. In landscape the status bar is hidden and the occlusion region shrinks to the camera (84×82).
- **Inner screen:** in landscape the column is on the physical right in both orientations, with the status items at the top. The inner camera is reported as an *inactive* occlusion region and the system ignores it. In portrait there is no column: a normal status bar across the top, and a horizontal tab bar.
- **Right-to-left** (forced RTL, outer portrait and both inner landscapes): the column never moves. It stays on the physical right, and SwiftUI reports it as the **leading** edge in both `safeAreaInsets` and `toolbarVerticalEdge`, so the two agree and are layout-relative. Reserved regions queried with `layoutDirectionBehavior: .fixed` are physical.

### The system's vertical tab bar

- A Liquid Glass capsule 48 pt wide, **24 pt from the window's side**, the same as its distance from the bottom, and 12 pt from the content. It isn't centred in the 84 pt column: its buttons are centred 48 pt from the window's side. Buttons are 44×58 at a 50 pt pitch, with 2 pt padding: height = 50 × slots + 12.
- **Icons only.** The labels are laid out but drawn at alpha 0.
- **Bottom-anchored** in the column's free span: 24 pt above the window's bottom edge (inside the 34 pt bottom safe area), or flush with the top of an occlusion region that sits at the bottom of the column.
- **Grows upward** with more tabs: 6 tabs → 48×312. At most **8 slots** (7 tabs + More) on both screens, 48×412, where the iPhone bottom bar shows 5. The inner screen's horizontal bar also shows 8 slots, squeezed into a fixed 400 pt width.
- **Accessibility text sizes don't change it.** Same width, icons only, same 84 pt column at AX XXXL.

### The hinge

- `reservedRegions(kind: .division)` reports the inner screen's hinge as a 40 pt strip across the middle, with a 20 pt margin on each side: `[455.5,0 40×669]` (vertical) with the inner screen in landscape, `[0,455.5 669×40]` (horizontal) in portrait. On the outer screen there is none.
- It is **inactive when fully open**, and becomes **active about 1 s after the hinge reaches partly open** (`onHingeChange` status `.partiallyOpen`). It goes inactive again when fully open. Measured in both inner orientations.
- **The system's bars never meet it**, and don't react to it. In landscape the hinge is vertical and the column runs parallel to it at the right edge. In portrait the hinge is horizontal and the tab bar sits at the bottom, in the lower half. Nothing in the system tab bar's frame or the safe area changed while the hinge was active.
- A region's `frame` **already includes its margins**. SwiftUI's `reservedRegions(kind: .division)` returned the same frame and margins as UIKit's `UIView.reservedRegions(kind:)` for the same view, `[455.5,0 40×669]` with 20 pt margins each side, and UIKit documents that frame as including the margins. So the fold itself is a line at x 475.5, the middle of the 951 pt screen, and the frame should not be expanded again.
- **With the vertical bar disabled, the system's tab bar ignores the hinge too.** Inner screen in landscape, `toolbarVerticalBehavior(.disabled)`: the system draws a horizontal 400×62 capsule centred on the full width, `[275.7,586 400×62]`, straight across the fold. It stayed there through fully open, partly open with the division inactive, partly open with it active (about 1 s later), and fully open again, with no change to the window's safe area or the content frame.
### SwiftUI APIs (iOS 27.1)

| API | What it gave |
|---|---|
| `@Environment(\.toolbarVerticalEdge) -> HorizontalEdge?` | The column's edge, layout-relative. `nil` wherever the system uses a horizontal bar. Readable outside a `TabView` (the bare view got `.trailing`). |
| `GeometryProxy.reservedRegions(kind: .occlusion, options:, layoutDirectionBehavior:)` | The camera and status items as frames in the proxy's own space. It reports regions outside the proxy's bounds too, so a view inside the safe area still sees the column's contents. Each region has `isActive`; the inner camera is inactive. |
| `GeometryProxy.reservedRegions(kind: .division)` | The inner screen's hinge, active only while partly open. See The hinge. |
| `GeometryProxy.contentMargins(for: .container)` | 20 on the side opposite the column. Not needed here. |
| `EnvironmentValues.tabBarPlacement` | `nil` in every state. It isn't set in a plain `TabView` content view, so it can't be used. |

No UIKit or SwiftUI API names the column directly. `UIView.reservedRegions(kind:)` is the UIKit twin of the SwiftUI call and is not used.

### The old iPad tab bar (iOS 17.5)

Measured on an iPad Pro 11-inch (M4) simulator on iOS 17.5 in portrait (834 pt wide), for the horizontal bar's item positioning. Regular width lays each item out inline, an icon beside a 13 pt title, and spreads them across the whole width. The gaps between each item's content and the bar's edges are all equal ("space evenly"): about 226 pt with 2 tabs, 101 pt with 4 and 23 pt with 8. Each button reaches halfway into its gaps, 4 pt from the next. `UITabBar.itemPositioning` set to `.automatic`, `.centered` or `.fill` produced identical frames, with `itemWidth` and `itemSpacing` at their default of 0. So no iOS 15–18 bar centres a compact group of items; that look predates iOS 11's inline layout.

### Apps can turn the vertical bar off

iOS 27.1 lets an app opt out of the vertical bar: `toolbarVerticalBehavior(.disabled)` in SwiftUI, `UIViewController.preferredVerticalBarBehavior` returning `.disabled` in UIKit. The preference flows up to the window or the nearest presentation. Bar content then goes back to the horizontal top and bottom bars, the status bar returns to the top, and the column's safe area inset is removed.

Measured on the Duo's outer screen in portrait with `toolbarVerticalBehavior(.disabled)` on the TabMenu example: `toolbarVerticalEdge` becomes `nil`, so `TabMenu` goes horizontal along the bottom (444 pt wide, with the content across the full width), and back to the column when the bar is turned on again. Unlike UIKit's `UITraitCollection.verticalBarEdge`, which is documented to report the preferred edge even while no vertical bar is visible, SwiftUI's value follows the bar actually in use. No extra code is needed.

### Transients

During a rotation or a fold, SwiftUI reports several intermediate layouts within the same second: `toolbarVerticalEdge` can change a pass before the safe area does, occlusion regions arrive one pass after the geometry (the first read after launch was empty), and the system's own tab bar briefly takes its old position or its horizontal form. Every value settles within the rotation. `TabMenu` should simply follow the current values, as the system does, and never cache them.

### Today's TabMenu on the Duo

On the outer screen in portrait, `TabMenu` in a `VStack` below the content draws a horizontal bar across the 382 pt content width and leaves the 84 pt column empty, so it sits nowhere near the system's bars.

## Design

### 1. When to go vertical

`axis = toolbarVerticalEdge == nil ? .horizontal : .vertical`, read from the environment where `TabMenu` is placed. Below iOS 27.1 it is always horizontal. The API is guarded as `AutoRotatingView` guards `onHingeChange`: `#if canImport(SwiftUICore, _version: 8.0.85)` (the iOS 27.1 SDK) plus `if #available(iOS 27.1, *)`.

### 2. Where the column is

- **Edge:** `toolbarVerticalEdge` (leading or trailing). Use it as a layout-relative alignment, so SwiftUI mirrors it for right-to-left with no extra work.
- **Width:** the safe area inset on that edge, read from a `GeometryReader` that respects the safe area (84 pt on the Duo). The menu is drawn in the inset, outside the reader's bounds.
- **Free span:** the column's height, from the top of the window down to the bottom edge in section 3, minus every **active** occlusion region that overlaps the column horizontally. Occlusion regions sit at one end of the column, so the free span is what's left between them. Query with the default `.mirrors` behaviour so the region frames are in the same layout-relative space as the edge and the insets.
- **Hinge:** also subtract every division region that crosses the column, margins included, **whether active or not**. The hinge is physically there whenever the screen is open, and ignoring its active state means the menu doesn't jump when the device goes from fully to partly open. On the Duo no division region ever crosses the column (see The hinge), so this changes nothing today; it keeps the menu off a fold if a later device or layout puts one there. If the hinge splits the column in two, use the lower part, keeping the bottom anchor.

### 3. Layout in the column

- Items stack top to bottom in `items` order, the system's order.
- Each item is 50 pt tall, the same as the horizontal bar's height, and centred 48 pt from the window's side, where the system centres its buttons. That makes the items 72 pt wide in the 84 pt column, flush with the content side. A column too narrow for that uses its full width. The icon keeps its 22 pt height and the name sits below it at 10 pt, as today.
- The stack is **bottom-anchored** in the free span, like the system's capsule.
- **Bottom edge, matching the system:** 24 pt above the window's bottom edge, or the top of an active occlusion region at the bottom of the column, whichever is higher. This reproduces every measured state: outer portrait 654, outer `UI.landscapeRight` 442, outer `UI.landscapeLeft` 384 (the camera), inner landscape 645. The stack reaches 10 pt into the 34 pt bottom safe area, as the system's capsule does.
- **Overflow:** if `items.count × 50` is taller than the free span, items shrink evenly to fit, down to 44 pt. If they still don't fit, `TabMenu` falls back to the horizontal bar. On the Duo the smallest span is outer landscape with the camera at the bottom (384 pt: 7 items at 50 pt, 8 at 48 pt).
- **Names:** controlled by `isShowingName`, as today. In the column they are limited to one line and truncate at the tail. "Favourites" at 10 pt is 51 pt wide, inside the 64 pt left after the item's 4 pt padding.
- **Background:** none, as today. The column shows whatever the app draws behind it. The system also draws nothing in the column apart from its capsule and the status items.

### 4. Horizontal bar and the hinge

With the vertical bar enabled, the horizontal bar only appears with the inner screen in portrait, where the hinge is horizontal across the middle and the bar is at the bottom.

If an app disables the vertical bar, a horizontal bar can also appear on the inner screen in landscape, where the hinge crosses it. The menu still spans the full width, whether the hinge is active or not, because the system's own tab bar does (Findings, The hinge): it stays centred across the fold through a partial fold. The horizontal bar doesn't check division regions.

### 5. Content and safe area

The column is already outside the content's safe area, so the vertical `TabMenu` adds none. The horizontal bar keeps today's behaviour. In the new placement API it is a bottom `safeAreaInset`, so content moves up by the bar's height.

### 6. Changes

- Changes of edge, width, free span or axis are applied with no SwiftUI animation. They happen during the system's rotation or screen change, and `AutoRotatingView`'s measurements showed that a change made without an animation rides the system's own.
- The selection, `onReselect`, `onDoubleTap` and accessibility (the "Tab bar" container, "Tab n of m" hints, named actions) are the same on both axes. VoiceOver order is top to bottom, matching the visual order.

### 7. API

Sketch:

```swift
// Existing view, unchanged; stays horizontal wherever it is placed.
TabMenu(selection: $selection, items: items) { isSelected in ... }

// New: places the menu for the current screen.
content
    .tabMenu(selection: $selection, items: items, isShowingName: nil, itemPositioning: .fill) { isSelected in
        ...
    } onReselect: { ... } onDoubleTap: { ... }
```

`.tabMenu` reads `toolbarVerticalEdge` and the reserved regions and does one of two things:

- **nil (every screen except the Duo's column), or below iOS 27.1:** `.safeAreaInset(edge: .bottom, spacing: 0) { TabMenu(...) }`, today's look and position.
- **leading or trailing:** an overlay aligned to that edge, sized to the column's width and free span as in sections 2 and 3, drawing `TabMenu` with a vertical axis.

`TabMenu` gains an internal `axis`, and both it and `.tabMenu` gain `itemPositioning: TabMenuItemPositioning = .fill`, so existing calls compile unchanged.

**Item positioning** applies to the horizontal bar only; the vertical menu always stacks its items in the column.

- `.fill` (default): items share the full width equally, as `TabMenu` always has, like the iPhone bar in iOS 15–18.
- `.centered(maxItemWidth:spacing:)`: items at most `maxItemWidth` wide, including their padding, `spacing` apart, centred as a group. When there isn't room they shrink equally to fit.

There's no automatic switching. The old iPad bar (Findings) spreads its items across the width too, in an inline layout `TabMenu` doesn't have, so there is no old-system centred behaviour to match.

### 8. Availability

- iOS 27.1+: automatic vertical layout on the Duo.
- iOS 15 to 27.0: horizontal, as today. No Duo runs those versions.

## Open questions

1. **Keyboard, and scenes smaller than full screen.** Not measured.
2. **Hardware.** Everything above is simulator-only, including when the hinge region becomes active.

## Verification plan

Done so far (2026-09-25):
- On the Duo simulator the vertical menu sits in the column on both screens. Its items are centred 48 pt from the window's side, lined up with the system's buttons (checked visually, after logging showed they had first been centred in the column, 6 pt too close to the edge).
- Tapping a tab in the column works, even though the menu is outside the content's bounds (checked by hand on the Duo).
- `.centered` is checked on the iOS 17.5 iPad (logged frames) and on the Duo's inner screen in portrait (visually).
- With `toolbarVerticalBehavior(.disabled)`, the menu is horizontal along the bottom, and returns to the column when it's turned off again (Duo outer screen, portrait, logged frames).
- `.fill` is unchanged on an iPhone 17 Pro (iOS 27.0). The committed example (`TabMenu` in a `VStack`) and the new one (`.tabMenu`) put the bar at the same frame, with the same item frames, and the bar region matches pixel for pixel.

Not planned: a frame-by-frame comparison against the system's bar in every state, overflow, the hinge partly open, and recorded rotations.
