# TabMenu action items and the bar split

Status: spec (2026-10-14). Not started.
Target: FrameUp 1.0 `TabMenu`, `TabMenuItem` and `tabMenu(...)`. iOS 16 is the floor for TabMenu: its types become `@available(iOS 16, *)` and the iOS 15 branch of `tabMenu(...)` goes. Raising the whole package's floor is a separate decision. Breaking changes are fine, since 1.0 is unreleased; they go in the CHANGELOG's existing TabMenu migration note.

## Problem

Every item in a `TabMenu` is a tab: tapping it sets the selection. Apps also want buttons in the same bar that do something else, such as a "+" that opens a compose sheet, and today they can't add one without faking a tab and resetting the selection.

`TabMenu` also does two jobs in one view:

- **Bar layout:** the stack, the axis, the horizontal distribution, the cell frames and padding, the 50 point height and the "Tab bar" container.
- **Item behaviour:** selection, reselect and double tap, the tap area, and each item's VoiceOver hint and traits.

Adding a second kind of item to that view would tangle both jobs with the kind. Splitting them first means action items only touch the behaviour, and later layout changes only touch the bar.

## Decisions

- **One item type with a kind, not a second type.** `TabMenuItem` gains an action kind. `items` stays `[TabMenuItem<Tab>]`, so the placement code, `SystemToolbarVerticalGeometryReader` and the vertical layout's item count are unchanged. A separate `TabMenuButton` would need an enum or a result builder for `items`, for no gain to callers.
- **Items stay data-driven.** A `@ViewBuilder` of items would need `Group(subviews:)` (iOS 18) to wrap each child, the "Tab n of m" hint needs each tab's index among the tabs, and the style system relies on every item being a `Label` with a title.
- **An action item is identified by its own `id`.** It has no tab, so its initialisers take an `id: some Hashable`. `TabMenuItem.id` becomes `TabMenuItemID<Tab>`, which keeps tab and action ids apart even if they hold equal values.
- **An action item is a `Button`.** It never changes the selection and is never selected. As a `Button` with `.plain` style it gets the `.isButton` trait, responds to `.disabled(_:)`, and works with Full Keyboard Access, without code of its own. Reselect and double tap never apply to it.
- **Tab items keep their gestures.** Double tap needs `onTapGesture(count: 2)`, which a `Button` can't express, so tab items keep today's behaviour exactly.
- **The style knows the kind.** `TabMenuItemStyleConfiguration` gains `role`, so a style can draw an action differently, such as a filled circle behind "+". `.masked` ignores it: an action item is drawn in the unselected colour, which is what an unselected tab looks like.
- **The bar is a `Layout`, internal.** iOS 16 makes a custom `Layout` available, which gives each item its share of the bar directly. It replaces the `HStack`/`VStack`, the `frame(maxWidth: .infinity)` chain and the centring frame, and its maths can be unit tested. The bar stays internal; making it public, for a bar of plain buttons with no tabs, can come later without breaking anything.
- **A cell is shared by both kinds.** The bar decides each item's share; the item fills it. Both kinds put their styled label in a cell (padding plus a rectangular content shape) and attach their behaviour to the cell, so the whole share takes taps, padding included, as today.

## Layers after the split

| Layer | Type | Knows about tabs? |
|---|---|---|
| Placement: bottom, custom bar or system toolbar | `TabMenuModifier` (unchanged) | No |
| Bar: shares, spacing, centring, height, container accessibility | `TabMenuBar` view and `TabMenuBarLayout` (new, internal) | No |
| Cell: padding, fills its share, content shape | `TabMenuCell` (new, internal) | No |
| Behaviour: tab or action, and the item's accessibility | `TabMenuTabItem` and `TabMenuActionItem` (new, internal) | Yes |
| Appearance | `TabMenuItemStyle` (gains `role`) | Only through `role` |

`TabMenu` becomes the composition: it reads the environment, puts each item in the behaviour for its kind, and hands them to the bar.

## API

### Items

```swift
public struct TabMenuItem<Tab: Hashable>: Identifiable {
    /// The item's tab, or nil for an action item.
    public var tab: Tab? { get }              // was `let tab: Tab`
    public var id: TabMenuItemID<Tab> { get } // was `Tab`
    public let label: Label<Text, TabMenuItemIcon>

    // Tab items: the four existing initialisers, unchanged.

    // Action items, mirroring Button(_:systemImage:action:) and Button(action:label:).
    public init(_ titleKey: LocalizedStringKey, systemImage: String, id: some Hashable, action: @escaping @MainActor () -> Void)
    @available(iOS 17, *)
    public init(_ titleKey: LocalizedStringKey, image: ImageResource, id: some Hashable, action: @escaping @MainActor () -> Void)
    public init<Icon: View>(_ titleKey: LocalizedStringKey, id: some Hashable, action: @escaping @MainActor () -> Void, @ViewBuilder icon: () -> Icon)
    public init<Icon: View>(id: some Hashable, title: Text, action: @escaping @MainActor () -> Void, @ViewBuilder icon: () -> Icon)
}

/// Identifies an item in a ``TabMenu``: a tab item by its tab, an action item by the id it was given.
public enum TabMenuItemID<Tab: Hashable>: Hashable {
    case tab(Tab)
    case action(AnyHashable)
}
```

Internally the item stores its kind:

```swift
enum Kind {
    case tab(Tab)
    case action(id: AnyHashable, perform: @MainActor () -> Void)
}
```

`id` is required for an action item because `ForEach` needs a stable identity across updates, and the title can't provide one: a `LocalizedStringKey` can't be compared or hashed from outside.

Example:

```swift
let items: [TabMenuItem<Tab>] = [
    TabMenuItem("Home", systemImage: "house", tab: .home),
    TabMenuItem("New Post", systemImage: "plus", id: "compose") { isComposing = true },
    TabMenuItem("Profile", systemImage: "person", tab: .profile)
]
```

### Item style configuration

```swift
public struct TabMenuItemStyleConfiguration {
    public let label: Label<Text, TabMenuItemIcon>
    /// Always false for an action item.
    public let isSelected: Bool
    public let edge: Edge?
    /// Whether the item selects a tab or runs an action.
    public let role: TabMenuItemRole
}

public enum TabMenuItemRole: Hashable, Sendable {
    /// Selects a tab.
    case tab
    /// Runs an action and leaves the selection as it is.
    case action
}
```

FrameUp isn't built with library evolution, so a later case, such as `.menu`, would break exhaustive switches in app styles. Document that styles should handle unknown roles with `default`.

### Unchanged

`TabMenu(selection:items:)`, `tabMenu(selection:items:)`, the distributions, the vertical behaviour, `onTabMenuItemReselect` and `onTabMenuItemDoubleTap`, `TabMenuGeometry` and the edge environment values keep their signatures. They gain `@available(iOS 16, *)` where they don't have it.

## Internal design

### `TabMenuBarLayout`

```swift
struct TabMenuBarLayout: Layout {
    let axis: Axis
    /// The longest an item's share can be along the axis, padding included. Infinity to share the bar equally.
    let maxItemLength: CGFloat
    let spacing: CGFloat
}
```

- Each subview gets a share of `min(maxItemLength, (length - spacing × (n - 1)) / n)` along the axis and the bar's full depth across it, so items shrink equally when there isn't room.
- The group is centred along the axis when it doesn't fill the bar.
- `sizeThatFits` takes the proposal along the axis (the bar fills what it's given) and the proposal across it.
- The share arithmetic is a static function, `shares(count:length:)`, returning the item frames, so tests don't need a view.

The horizontal bar reads `maxItemLength` and `spacing` from the resolved `TabMenuHorizontalDistribution`, as `maxItemWidth` and `itemSpacing` do now. The vertical bar uses infinity and 0. The vertical `.grouped` distribution stays in `TabMenuVerticalBarLayout`, which caps the menu's height from outside, as now.

### `TabMenuBar`

Wraps the layout with what belongs to the whole bar:

- Horizontal: `.padding(.bottom, 2)`, `.padding(.horizontal, 1)`, `.frame(height: 50)`.
- Both axes: `.accessibilityElement(children: .contain)` and `.accessibilityLabel(Text("Tab bar"))`.

### `TabMenuCell`

The styled label padded for the axis (10 points horizontally along the bottom, 4 in a vertical bar, as now), filling its share, with `.contentShape(Rectangle())`. Both behaviours wrap a cell, so the whole share, padding included, takes taps.

### `TabMenuTabItem`

Today's `itemView`, unchanged in behaviour: the tap that sets the selection, the reselect and double-tap overlay on the selected item, the named accessibility actions, `.accessibilityElement(children: .combine)`, the hint and `.isSelected`.

The hint counts tabs only: "Tab 2 of 3" for the second tab in a menu with three tabs and one action, wherever the action sits. `TabMenu` works out each tab's index and the tab count once and passes them in, so the hint no longer searches `items` for each item.

### `TabMenuActionItem`

```swift
Button(action: perform) {
    TabMenuCell(...) { styledLabel }
}
.buttonStyle(.plain)
```

- `.plain` stops the `Button` from tinting or dimming the style's drawing. The style can still respond to `isEnabled` from the environment.
- `.accessibilityElement(children: .combine)` as for tabs, so the label is read once. No hint and no `.isSelected`.
- No reselect or double-tap actions, even when they are set in the environment.

### `TabMenu`

```swift
public var body: some View {
    TabMenuBar(edge: edge, distribution: horizontalDistribution) {
        ForEach(items) { item in
            switch item.kind {
            case let .tab(tab): TabMenuTabItem(...)
            case let .action(_, perform): TabMenuActionItem(...)
            }
        }
    }
}
```

The deprecated overrides (`itemStyleOverride`, `reselectOverride`, `doubleTapOverride`) are passed through to the tab items as now.

### `tabMenu(...)`

The `#available(iOS 16, *)` check and the iOS 15 branch go. The modifier is applied directly.

### Deprecated code

- The deprecated `==` on `TabMenuItem` compares `id`, so two action items compare by their ids. Its message changes to "Compare the ids instead: lhs.id == rhs.id."
- `isNamed` and the deprecated `init(image:name:tab:)` only make tab items, and are unchanged.

## Migration

| Before | After |
|---|---|
| `item.tab` (a `Tab`) | `item.tab` (a `Tab?`, nil for an action item) |
| `item.id` (a `Tab`) | `item.id` (a `TabMenuItemID<Tab>`); compare with `.tab(value)` |
| A fake tab that resets the selection in `onChange` | `TabMenuItem("New", systemImage: "plus", id: "new") { ... }` |
| A `switch` over a configuration's properties in a custom style | Add `configuration.role` if action items should look different |
| `TabMenu` on iOS 15 | Needs iOS 16 |

## Out of scope

- **Items that open a `Menu`.** A common pattern for "+", but a `Menu` draws its own label, which works against the item style. This could be a later `.menu` role.
- **Pinning an item to one end of the bar**, like iOS 26's separated search tab. The order in the array covers most cases. The `Layout` makes this possible later.
- **A public bar** for a bar of plain buttons with no tabs.
- **`ButtonRole`** (such as `.destructive`) on action items.
- **A pressed state in the configuration.** The plain `Button` gives no highlight. A style that wants one can use its own `ButtonStyle` later if the configuration grows `isPressed`.

## Tests

- Unit, `TabMenuBarLayout.shares`: equal shares fill the length; grouped shares are capped and centred; spacing is counted between items only; shares shrink equally when the capped group doesn't fit; zero items and one item. Both axes.
- Unit: tab hints count tabs only, with an action first, in the middle and last; an action item's `id` is `.action`, and a tab and an action holding equal values have different ids; `tab` is nil for an action item.
- Unit: the configuration's `role` is `.action` and `isSelected` is false for an action item, even when no tab is selected.
- Example app: add a "+" action to `TabMenuExample` that opens a sheet. Check that tapping it leaves the selection alone, along the bottom, in the custom vertical bar (iPhone 18 Pro, landscape) and in the Duo's vertical toolbar. Add a capsule-backed action to the custom style example to show `role`.
- VoiceOver: an action reads its title and "Button" with no tab hint; tabs read "Tab n of m" counting tabs only; reselect and double-tap named actions appear only on the selected tab, never on an action.
- `.disabled(true)` on the menu, or a style that reads `isEnabled`, greys and disables an action item.
- Layout regression: compare the bar along the bottom, `.equal` and `.grouped`, and in both vertical bars, before and after the split, with `ImageRenderer`, as for the styles change. Item frames must match to the point.
