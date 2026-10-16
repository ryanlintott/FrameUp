# System bar geometry

**Status:** design agreed with the user on 2026-10-16. No code yet.

| Question | Decision |
|---|---|
| Scope | **Both** the bottom bar (by convention: 50 pt plus the bottom safe area) and the measured vertical toolbar. |
| Measuring | **A root modifier**, `.measuresSystemBarGeometry()`, outside any rotation. `AutoRotatingView` and `AutoRotatingView(topEdges:)` turn the value for their content. |
| Edges | **Layout-relative**, like SwiftUI's `EdgeInsets`, `safeAreaInset(edge:)` and `toolbarVerticalEdge`. This includes `FUInterfaceTurn`'s edges. |
| Helpers | **`systemBarInset`** and **`FUInterfaceTurn`** (replaces the earlier `autoRotatingUp`). |
| `systemBarInset` away from the bar | The bar is always drawn where the system's bar is, reaching past the view if need be; the view's content is inset only by the overlap. The view doesn't have to ignore the safe area or reach the screen's edge. |
| Turn value | `FUInterfaceTurn`, an enum of four quarter turns relative to the interface, with `interfaceEdge(of:)` and `localEdge(of:)`. |

A public tool that tells a view **where the system would put its tab bar**, in that view's own frame, even inside `AutoRotatingView` or `AutoRotatingView(topEdges:)`. It's there to help an app place its own bar; it isn't a bar. `TabMenu` stays a plain view the app places, and `.tabMenu` keeps its own placement rules, rebuilt on top of this tool.

Driven by Wordhord's move to `AutoRotatingView(topEdges:)` (Wordhord `Specs/CustomRotationCovers.md`), where the book frame and its tab bar turn inside a frame fixed to the device, and the bar has to land in the iPhone Duo's system column.

## What passes through a rotation today

Inside `AutoRotatingView` (and so inside `AutoRotatingView(topEdges:)`, which is two of them):

| Value | Passes through turned? | How |
|---|---|---|
| Safe area | **Yes** | Read outside the rotation, turned into the content's frame, and applied with `HeldLayout`, animated with the turn. |
| Container corner insets and radii | **Yes**, through `AutoRotatingGeometryProxy` | SwiftUI's own values describe the unturned container. |
| Size | **Yes** | The content's frame is the turned size. |
| `reservedRegions` (camera, hinge) | **Yes, once settled** | SwiftUI maps them through the rotation, inside the `.locked` host too (probe, below). During a turn, fold or window change they can be stale for a few layout passes. |
| `toolbarVerticalEdge` | **No, and stale** | Not turned. Inside the `.locked` host it's also stuck: it read `leading` in every state while outside it changed between `leading`, `trailing` and nil (probe, below). |
| `tabMenuVerticalEdge`, `tabMenuGeometry` | **No** | Same: environment values in the interface's frame. |

So an app could already read the safe area correctly inside a rotation, but it can't tell which part of it is the system column, which edge the column is on, or where the camera is.

## The tool

### `SystemBarGeometry` (public, environment)

```swift
/// Where the system puts its tab bar, in the reading view's own frame.
public struct SystemBarGeometry: Equatable, Sendable {
    public enum Kind: Sendable { case bottom, verticalToolbar }

    /// Bar along the bottom, or the system's vertical toolbar (the Duo's column).
    public let kind: Kind
    /// The edge of the reading view's frame the bar is on, after any turn.
    public let edge: Edge
    /// How deep the bar is from that edge: 50 + bottom safe area along the bottom, 84 for the Duo column.
    public let depth: CGFloat
    /// The part of the bar's length the system leaves free for its items, clear of the camera, status items and hinge, as insets from the bar's two ends in the reading view's frame.
    public let usableStart: CGFloat
    public let usableEnd: CGFloat
    /// Depth the app must reserve itself because the system names the bar without a safe area for it (the Duo's left split window), or 0.
    public let reservedDepth: CGFloat
}

extension EnvironmentValues {
    /// Nil where nothing is measuring, or there's no system bar.
    public var systemBarGeometry: SystemBarGeometry? { get }
}
```

Values are in the reading view's frame, so the same code works upright or turned: a view inside a book frame whose top points to the user's left sees `edge == .bottom` when the column is on the user's right.

### Measuring: one root modifier

```swift
ContentView()
    .measuresSystemBarGeometry()   // at the root, outside any rotation
```

- Measures once, outside any rotation, from `toolbarVerticalEdge`, `reservedRegions` and the safe area, as `SystemToolbarVerticalGeometryReader` does today, plus the bottom-bar case.
- Sets the environment value for everything inside.
- `AutoRotatingView` (and so `AutoRotatingView(topEdges:)`) turns it into its content's frame, the same way it turns the safe area: the edge rotates with the content, and the depth and usable range move with the turn's timing.
- `.tabMenu` uses the same measurement internally, so there's one source of truth.

### Placing: one small helper

```swift
/// Draws a view where the system's bar is, sized to it and limited to its usable length, and insets this view's content by however much of the bar overlaps it.
func systemBarInset<V: View>(@ViewBuilder content: (SystemBarGeometry) -> V) -> some View
```

- The geometry is measured against the **container**: the window at the root, and inside a rotation the turned frame `AutoRotatingView` fills, which is the window seen from inside the turn.
- The root modifier, and each `AutoRotatingView` for its turned frame, sets a FrameUp coordinate space on that container. The helper measures the reading view's frame in it, so it knows where the bar is relative to the view.
- The bar is drawn where the system's bar is, ignoring the safe area on the bar's edge itself, even where that's past the view's own frame (like a `background` that reaches out). The view's content is inset only by the part of the bar that overlaps it, plus `reservedDepth` where the system gives no safe area. A view that fills the container, like Wordhord's book frame, gets the whole bar; a view nowhere near that edge gets no inset.
- It only places and sizes. Spreading, grouping and styling the items stay with the app.

### Which edge is which: `FUInterfaceTurn`

How a view is turned relative to the interface the system laid out, whatever the interface's orientation. The interface's top is always the top. Outside any rotation it's `.none`; inside a turned-back `AutoRotatingView`, such as each upright tab item, it's `.none` again.

```swift
public enum FUInterfaceTurn: Hashable, Sendable, CaseIterable {
    case none
    case quarterClockwise
    case half
    case quarterCounterclockwise

    /// Where one of this view's edges is in the interface. turn.interfaceEdge(of: .top) is where this view's top points.
    public func interfaceEdge(of localEdge: Edge) -> Edge
    /// Which of this view's edges is at an edge of the interface. turn.localEdge(of: .top) is the edge to start from to list items top to bottom.
    public func localEdge(of interfaceEdge: Edge) -> Edge
    public var isSideways: Bool
    /// The turn as an angle, for drawing.
    public var angle: Angle
}

extension EnvironmentValues {
    public var interfaceTurn: FUInterfaceTurn { get }   // .none outside any rotation
}
```

**Why an enum, not an `Angle`.** The value is a state, not something that animates. `AutoRotatingView` animates the turn itself, with its own accumulating angle and the host's Core Animation; the environment value changes once, when the content takes its new rotation at the start of the turn, just as the content's layout does. So an enum doesn't affect the animation, and it's exact: no floating-point comparisons, `switch` covers every case, and it's `Hashable` for `onChange`. `angle` is there for anyone who wants to draw with it.

Edges are layout-relative, like the rest of this tool.

## Probe results (2026-10-16, iPhone Duo simulator, iOS 27.1)

`TopEdgesProbe` logs size, safe area, `reservedRegions` and `toolbarVerticalEdge` on the `AutoRotatingView(topEdges:)` ("outside") and on its content ("inside"), category `TopEdges`. The user turned the outer screen through all four orientations, unfolded, turned the inner screen through all four, and opened split screen on the left and right.

- **Safe area:** always turned correctly inside, and it animates through the turn with the system's timing (for example top 82 → 0 and bottom 34 → 84 over the turn).
- **Reserved regions, settled:** mapped correctly inside in every state. Outer landscape, column on the left: the column-top occlusion is `(-84,0 84×82)` outside and `(350,-84 82×84)` inside, the content's top-right corner. Inner screen: the hinge division `(455,0 40×669)` outside becomes `(-34,455 669×40)` inside. In the right split window, the column-top occlusion lands in the content's bottom safe area, as it should.
- **Reserved regions, mid-change:** for a few passes after a fold, a turn or a split, both sides can report stale frames: outside, an occlusion outside the window; inside, a frame left unturned (`(455,-81 40×669)` for the hinge) or off the content (`y 626` in a 469-high frame). They settle within the change.
- **`toolbarVerticalEdge`:** inside it read `leading` in all 222 logs. Outside it was `leading` 10 times, `trailing` 16 times and nil 7 times. The value doesn't reach hosted content, so nothing inside a locked rotation can use it.

**Where the column is, as the user sees it** (checked in every orientation with `TopEdgesExample`'s toolbar check, which logs `toolbar check ok/MISMATCH`):

| Screen | portrait | landscapeRight | landscapeLeft | portraitUpsideDown |
|---|---|---|---|---|
| Outer | right | right | left | wherever the last orientation left it* |
| Inner | none (bottom) | right | right | none (bottom) |

*An iPhone app's interface doesn't turn upside down, so held upside down the outer interface stays in the last orientation and the column stays on its edge: the user's left after portrait, bottom after landscape right, top after landscape left. A `topEdges` set that should keep content beside the column leaves upside down out. `SystemBarGeometry` reports the column correctly in all three cases.

Similarly the inner screen's left split window has its column on the left, so a set keyed only on the screen is wrong there; choose it from the measured bar when the window changes.

`toolbarVerticalEdge` names the interface's edge, not the user's. On the outer screen held upside down the interface may stay in portrait, as iPhones don't turn upside down, and then it reads `trailing` for a column on the user's left. Anything comparing it with what the user sees has to turn it by the difference between the interface and the device.

A dictionary for `AutoRotatingView(topEdges:)` that keeps content facing away from the column has to be known before each turn, since the toolbar's new edge arrives after the turn starts. These tables are what Wordhord's dictionaries are built from.

**What this means for the design:** measuring once at the root and turning the result, as designed, is the only way to get the toolbar's edge inside a rotation. It also gives one consistent source for the reserved regions instead of each view's own transient readings. The root measurement keeps the last good value through stale passes, as `SystemToolbarVerticalGeometryReader` does now, and ignores regions outside the window.

## Steps

1. ~~**Probe**~~ (done, results above): in the example's `-FUTopEdgesScreen`, log `reservedRegions` and the safe area from inside the turned content (inner and outer screens, all orientations, left split window) and compare them with the same values measured outside. This decides whether the rotation can rely on SwiftUI's reserved regions or must turn its own.
2. ~~`SystemBarGeometry`, the root modifier, and turning it in `AutoRotatingView`.~~ Done: `Sources/FrameUp/SystemBarGeometry/`, tests in `SystemBarGeometryTests`. Internally the bar is kept in physical terms (`SystemBar`: side, depth, usable insets read clockwise round the container) and turned exactly like the safe area; the public value names it for the layout direction. The root modifier keeps the last good measurement and ignores reserved regions outside the window. The turned value changes at once when the content takes its new rotation, not with the turn's timing like the safe area; `systemBarInset` (step 3) will need to animate its placement the way `HeldLayout` does. Unit tests for turning a geometry by each quarter turn, for both kinds and every edge.
3. ~~`systemBarInset` and `FUInterfaceTurn`~~ Done: `SystemBarInset.swift`, `FUInterfaceTurn.swift`, tests in `SystemBarPlacementTests` and `FUInterfaceTurnTests`. Changes from the design: the bar view fills the whole bar, from the container's edge to its depth, so a background covers it, and the app keeps items in the usable part with `usableStart`/`usableEnd`. `FUInterfaceTurn`'s edge conversions take a `layoutDirection:` parameter, since leading and trailing depend on it. Each `AutoRotatingView` sets an internal coordinate space on its turned frame, so `systemBarInset` can place the bar from anywhere inside. Through a turn (fixed 2026-10-16, checked from recordings of the Duo's outer screen):
   - Each `AutoRotatingView` keeps its content's turned bar from when the turn starts until the new measurement arrives, since the root measures it a layout pass after the content takes its new rotation. Without this, the old bar turned by the new rotation pushed the content over for the whole turn.
   - `HeldLayout` animates the content frame's size in layout (`animatableFrame(_:)`), as it already did the safe area, so the content changes shape with the turn instead of taking its final shape as it starts. `systemBarInset` places the bar against that animating size.
   - Content that fills an enclosing `AutoRotatingView` takes the safe area that view is moving to, not each step of its animation, so a nested layer's safe area doesn't swing round mid-turn.

   Not yet: right-to-left checked on a device.
4. Rebuild `.tabMenu`'s system-toolbar placement on it, keeping its tests passing.
5. Example: the hand-placed bar in `TopEdgesExample` uses the geometry to sit in the column, group its items there, and order them top to bottom with `interfaceTurn.localEdge(of: .top)`.
