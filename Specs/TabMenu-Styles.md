# TabMenu styles

Status: spec only, not started (2026-10-09)
Target: FrameUp `TabMenu` and `tabMenu(...)`. The package stays iOS 15+. Breaking changes are fine; this is aimed at the next minor release with a CHANGELOG migration note.

## Problem

Since `tabMenu(selection:items:...)` creates and places the `TabMenu` itself, an app can't wrap the menu view in its own modifiers. Wordhord puts a gold shimmer on its menu (`WordhordTabMenuView().shimmerGold()` in `WordhordCustomTabView`), and that can't be done with the modifier.

The only customisation today is `maskedView: (Bool) -> Content`, a fill masked by each item's icon and name. An app can't change how an item is drawn: where the name goes, the icon size, a selection indicator, or a different look in the vertical bar.

## Decisions

- **An item style, set through the environment, as SwiftUI does with `ButtonStyle` and `LabelStyle`.** `TabMenuItemStyle` draws one item. It works the same whether the menu is placed by `tabMenu(...)` or by hand.
- **A whole-menu style is an optional extra.** A per-item shimmer is expected to look fine in Wordhord, so the item style covers the problem above. `TabMenuStyle`, which decorates the whole menu, is specified below as a later, optional step, built only if an effect really needs to span the menu.
- **Layout options go in the environment too.** `horizontalDistribution` moves to `.tabMenuHorizontalDistribution(_:)`.
- **Actions are modifiers.** `onReselect` and `onDoubleTap` become `.onTabMenuItemReselect(_:perform:)` and `.onTabMenuItemDoubleTap(_:perform:)`, which set environment values, as SwiftUI does with `refreshable`. `NamedAction` is removed. `TabMenu` and `tabMenu(...)` take only the selection and the items.
- **No item size in the configuration.** Like SwiftUI's own style configurations, it doesn't report the space available. A style that adapts to its size uses its own layout, such as `ViewThatFits`.
- **`TabMenu` keeps the behaviour, the styles only draw.** Selection, reselect, double tap, the tap area, and all accessibility (label, hint, `.isSelected`, named actions, combining children) stay in `TabMenu`, outside the style. A custom style can't break VoiceOver or tapping.
- **The placement keeps the size.** The horizontal menu is 50 points tall, the custom vertical bar is `customBarWidth` wide, and the system column is measured. Styles draw within those sizes and can't change them.
- **`maskedView` goes away.** Today's look becomes the default item style, `.masked`, which takes the same closure. The whole tab menu needs no closure at all by default.
- **An item is a `Label`.** `TabMenuItem` is built like a `Label` (a localised title and an icon), and the item style gets it as `configuration.label`. Styles customise it with the label styles SwiftUI already has, or their own `LabelStyle`, as anywhere else in SwiftUI.
- **Showing names is the style's choice.** Every item has a title, so VoiceOver always has a name. A style that hides names uses `.labelStyle(.iconOnly)`, which keeps the title for VoiceOver. `isShowingName` is removed.

## API

### Items

```swift
public struct TabMenuItem<Tab: Hashable> {
    public let tab: Tab
    /// The title and icon, as a `Label`.
    public let label: Label<Text, TabMenuItemIcon>

    public init(_ titleKey: LocalizedStringKey, systemImage: String, tab: Tab)
    public init(_ titleKey: LocalizedStringKey, image: ImageResource, tab: Tab)
    public init<Icon: View>(_ titleKey: LocalizedStringKey, tab: Tab, @ViewBuilder icon: () -> Icon)
    public init<Icon: View>(tab: Tab, @ViewBuilder label: () -> Label<Text, Icon>)
}

/// An item's icon, with its type erased. Behaves like any other view.
public struct TabMenuItemIcon: View { ... }   // wraps AnyView internally
```

The icon's type is erased because `items` is an array of one type, and an app can mix icons, as Wordhord mixes SF Symbols with a custom shape. Avoiding erasure would need a result builder like `TabView { Tab(...) }`, which on iOS 15 means a hand-written fixed-arity builder: a lot of API for no benefit to callers. The erasure is hidden in `TabMenuItemIcon`, as SwiftUI hides it in `LabelStyleConfiguration.Icon`, so callers never write `AnyView` and FrameUp can change how icons are stored without breaking the API. The cost is one erased view per item, eight at most.

The `LocalizedStringKey` initialisers look the title up in the app's string catalog, as `Label` does. Equality stays by `tab`.

Wordhord's items become:

```swift
TabMenuItem("Wordhord", systemImage: viewManager.tab == .wordhord ? "book.closed.fill" : "book.closed", tab: .wordhord)
TabMenuItem("Favourites", tab: .favourite) { favouritesIcon }
```

### Item style

```swift
public protocol TabMenuItemStyle {
    associatedtype Body: View
    @MainActor @ViewBuilder func makeBody(configuration: Configuration) -> Body
    typealias Configuration = TabMenuItemStyleConfiguration
}

public struct TabMenuItemStyleConfiguration {
    /// The item's title and icon, as given in `TabMenuItem`.
    public let label: Label<Text, TabMenuItemIcon>
    public let isSelected: Bool
    /// The screen edge the menu is placed against: `.bottom`, `.leading` or `.trailing`. Nil for a `TabMenu` placed by hand, which can't know where it is.
    public let edge: Edge?
    /// `.vertical` when `edge` is leading or trailing, otherwise `.horizontal`.
    public var axis: Axis { get }
}

public extension View {
    func tabMenuItemStyle<S: TabMenuItemStyle>(_ style: S) -> some View
}
```

`edge` is one value rather than separate axis and edge fields, so they can't disagree. Like `tabMenuVerticalEdge`, it's layout-relative: in a right-to-left layout a bar on the physical right is `.leading`. It doesn't say whether a vertical bar is the system's column or FrameUp's custom bar; add that only if a style needs it.

Built-in styles:

- `.masked(_ fill: (Bool) -> some View)`: today's look. An internal `LabelStyle` puts the icon at 22 points tall above a 10 point title, and the result masks `fill`. Bottom-aligned along the bottom, centred in a vertical bar. Owns the 10 point font, which moves out of `TabMenu` so a custom style starts from the inherited font.
- `.automatic`: `.masked` with the accent colour when selected and `.secondaryLabel` otherwise. The default.

`TabMenu` gives each item a cell: the full height and an equal or grouped share of the width along the bottom, or an equal share of the height and the full width in a vertical bar, with today's padding. The style's body is centred in the cell, and the whole cell takes taps (`contentShape(Rectangle())`), so a style that draws less than the cell is still easy to hit.

#### Example: rearranging the label

Most styles can use `configuration.label` with SwiftUI's own label styles. This one shows icons only in a vertical bar, and the icon and title side by side along the bottom, with a capsule behind the selected item:

```swift
struct CapsuleItemStyle: TabMenuItemStyle {
    func makeBody(configuration: Configuration) -> some View {
        Group {
            if configuration.axis == .vertical {
                configuration.label
                    .labelStyle(.iconOnly)
            } else {
                configuration.label
                    .labelStyle(.titleAndIcon)
            }
        }
        .font(.footnote)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .foregroundStyle(configuration.isSelected ? .white : .secondary)
        .background {
            if configuration.isSelected {
                Capsule().fill(.tint)
            }
        }
    }
}

ContentView()
    .tabMenu(selection: $selection, items: items)
    .tabMenuItemStyle(CapsuleItemStyle())
```

`.iconOnly` hides the title on screen, but VoiceOver still reads it.

#### Example: styling the icon and title separately

To size or place the icon and title separately, a style applies its own `LabelStyle`. This one stacks a large icon over a small title, with a dot beside the selected item, on the side nearest the content:

```swift
struct StackedLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 2) {
            configuration.icon
                .imageScale(.large)
                .frame(height: 24)
            configuration.title
                .font(.caption2)
                .lineLimit(1)
        }
    }
}

struct DotItemStyle: TabMenuItemStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(StackedLabelStyle())
            .foregroundStyle(configuration.isSelected ? .primary : .secondary)
            .overlay(alignment: dotAlignment(for: configuration.edge)) {
                if configuration.isSelected {
                    Circle()
                        .fill(.tint)
                        .frame(width: 5, height: 5)
                        .padding(2)
                }
            }
    }

    /// Above the item along the bottom, toward the middle of the screen in a vertical bar.
    private func dotAlignment(for edge: Edge?) -> Alignment {
        switch edge {
        case .leading: .trailing
        case .trailing: .leading
        default: .top
        }
    }
}
```

`.masked` is built the same way: its internal `LabelStyle` lays out the icon and title, and the item style masks the fill with the result.

#### Wordhord's shimmer

Wordhord moves its shimmer into the fill, so each item shimmers on its own:

```swift
ContentView()
    .tabMenu(selection: $viewManager.tab, items: tabMenuItems)
    .tabMenuItemStyle(.masked { isSelected in
        (isSelected ? Color.oeGold : .oeGoldDark)
            .shimmerGold()
    })
    .onTabMenuItemReselect("Scroll to top") {
        Task { await viewManager.scrollToTop() }
    }
    .onTabMenuItemDoubleTap("Close cover") {
        Task { await viewManager.closeCover() }
    }
```

Style and action modifiers can go outside `tabMenu(...)`, as above, since the menu is inside it. They also reach the content, which only matters if the content has its own `TabMenu`.

### Horizontal distribution

```swift
public extension View {
    /// How the items are spread across the width of a horizontal tab menu. Default is `.equal`. A vertical menu always stacks them.
    func tabMenuHorizontalDistribution(_ distribution: TabMenuHorizontalDistribution) -> some View
}
```

`TabMenuHorizontalDistribution` itself is unchanged (`.equal`, `.grouped(maxItemWidth:spacing:)`).

### Actions

```swift
public extension View {
    /// Runs when the selected item is tapped again. The name is the VoiceOver action's name on the selected item.
    func onTabMenuItemReselect(_ name: LocalizedStringKey, perform action: @escaping () -> Void) -> some View
    func onTabMenuItemReselect(_ name: Text, perform action: @escaping () -> Void) -> some View
    /// Runs when the selected item is tapped twice. The name is the VoiceOver action's name on the selected item.
    func onTabMenuItemDoubleTap(_ name: LocalizedStringKey, perform action: @escaping () -> Void) -> some View
    func onTabMenuItemDoubleTap(_ name: Text, perform action: @escaping () -> Void) -> some View
}
```

The behaviour is unchanged: both only apply to the selected item, a single tap waits to rule out a double tap only when a double-tap action is set, and each action is offered to VoiceOver by name.

The action isn't stale. Each update of the view that applies the modifier puts a fresh closure in the environment, and `TabMenu` reads it in its own body. A closure that reads state when it runs, as Wordhord's does through `viewManager`, always sees the current tab. The only cost is that an update to that view also updates `TabMenu`, which with at most 8 items doesn't matter.

### `TabMenu` and `tabMenu(...)`

```swift
public struct TabMenu<Tab: Hashable>: View {
    public init(
        selection: Binding<Tab>,
        items: [TabMenuItem<Tab>]
    )
}

func tabMenu<Tab: Hashable>(
    selection: Binding<Tab>,
    items: [TabMenuItem<Tab>]
) -> some View
```

- The `Content` generic, `maskedView`, `isShowingName`, `horizontalDistribution`, `onReselect` and `onDoubleTap` are removed from both. `TabMenuModifier` drops its `MaskedView` generic. `NamedAction` is removed from the package.

## Migration

| Before | After |
|---|---|
| `TabMenu(selection:items:) { isSelected in fill }` | `TabMenu(selection:items:)` `.tabMenuItemStyle(.masked { isSelected in fill })` |
| `.tabMenu(selection:items:) { isSelected in fill }` | `.tabMenu(selection:items:)` `.tabMenuItemStyle(.masked { isSelected in fill })` |
| `horizontalDistribution: .grouped(...)` | `.tabMenuHorizontalDistribution(.grouped(...))` |
| `onReselect: { NamedAction("Name") { ... } }` | `.onTabMenuItemReselect("Name") { ... }` |
| `onDoubleTap: { NamedAction("Name") { ... } }` | `.onTabMenuItemDoubleTap("Name") { ... }` |
| `TabMenu(...).someEffect()` placed by hand | still works; with `tabMenu(...)`, put the effect in the item style |
| `TabMenu<Tab, Content>` in a type | `TabMenu<Tab>` |
| `TabMenuItem(image: Image(systemName: "star"), name: "Favourites", tab: 1)` | `TabMenuItem("Favourites", systemImage: "star", tab: 1)` |
| `TabMenuItem(icon: AnyView(view), name: "Info", tab: 0)` | `TabMenuItem("Info", tab: 0) { view }` |
| `TabMenuItem(..., name: nil, ...)` | a title is required; hide titles with a style using `.labelStyle(.iconOnly)` |
| `isShowingName: false` | an item style using `.labelStyle(.iconOnly)` |

Update the README, the example app's TabMenu examples, and Wordhord.

## Implementation notes

- The environment holds `any TabMenuItemStyle` (and `any TabMenuStyle` if the optional extra is built). `TabMenu` opens the existential and wraps the body in `AnyView`. That's at most 8 items, so the cost doesn't matter.
- Swift 6 language mode: an environment key's `defaultValue` must be `Sendable`. Check whether that forces the protocols to be `Sendable`, and whether `.masked`'s closure then needs to be `@MainActor @Sendable`. A closure capturing a SwiftUI view is fine there, since views are main-actor isolated.
- `.masked`'s fill closure is stored in the style and called during `TabMenu`'s body, so it always sees current state (see the `swiftui-stale-closure-state` skill if that changes).
- `TabMenu` reads the edge from the environment: the placement sets it (replacing the internal `tabMenuAxis` key with an edge key), and a menu placed by hand sees nil.
- Icons are kept as given. `TabMenuItem(_:systemImage:tab:)` doesn't make the symbol resizable, so it responds to `font` and `imageScale` as in a system `Label`. `.masked` has to size symbols, custom shapes such as Wordhord's cross, and image resources to today's 22 point look; check it side by side with the current menu.
- The VoiceOver label comes from the label's title, replacing the fallback to the tab's hash value.
- Keep `TabMenu`'s accessibility modifiers around the cell, after the style, so `.accessibilityElement(children: .combine)` still merges whatever the style draws.

## Tests

- Unit: `edge` is `.bottom` along the bottom, the bar's edge in a vertical bar (`.system` and `.custom`, left to right and right to left), and nil for a `TabMenu` placed by hand. `axis` follows `edge`.
- Example app: add `CapsuleItemStyle` and `DotItemStyle` to the TabMenu examples, and one with `.tabMenuHorizontalDistribution(.grouped(...))`. Check them along the bottom, in the custom vertical bar (iPhone 18 Pro, landscape), and in the Duo's column.
- VoiceOver: with each custom item style, including an icons-only one, each item still reads its title, "Tab n of m", selected state and named actions.
- Actions: reselect and double tap run only on the selected item, with and without a double-tap action set, and with the modifiers outside `tabMenu(...)` and around a hand-placed `TabMenu`.
- Wordhord: the per-item shimmer looks right in each placement. If it doesn't, build the optional menu style. **Ryan checks this on a physical device; agents don't attempt it.** The shimmer follows device motion, which the simulator can't produce.

## Optional extra: menu style

Not part of the first release. Build it only if an effect needs to run across the whole menu as one, rather than per item.

```swift
public protocol TabMenuStyle {
    associatedtype Body: View
    @MainActor @ViewBuilder func makeBody(configuration: Configuration) -> Body
    typealias Configuration = TabMenuStyleConfiguration
}

public struct TabMenuStyleConfiguration {
    /// The laid-out items, each already drawn with the item style.
    public let content: TabMenuStyleConfiguration.Content   // opaque View
    /// The screen edge the menu is placed against, as for items.
    public let edge: Edge?
    public var axis: Axis { get }
}

public extension View {
    func tabMenuStyle<S: TabMenuStyle>(_ style: S) -> some View
}
```

- `.automatic`: returns `configuration.content` unchanged. The default.

The menu style is applied to the stack of items, before the placement sets the frame. It can add an overlay, background, mask or effect over the whole menu, and use `edge` to orient it, such as a shadow or gradient that faces the content. A background drawn here covers the menu's own frame only; a background that runs under the Home indicator or to the screen's edge belongs to the app, in its content, because the safe area below the menu isn't part of the menu.

If Wordhord's per-item shimmer doesn't look right, the whole-menu version would be:

```swift
struct GoldShimmerTabMenuStyle: TabMenuStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.content.shimmerGold()
    }
}

ContentView()
    .tabMenu(selection: $viewManager.tab, items: tabMenuItems)
    .tabMenuItemStyle(.masked { $0 ? Color.oeGold : .oeGoldDark })
    .tabMenuStyle(GoldShimmerTabMenuStyle())
```

`TabMenuStyleConfiguration.Content` would be an opaque wrapper view (like `LabelStyleConfiguration.Title`), so the configuration needn't be generic. Tests would check it along the bottom, in the custom vertical bar and in the Duo's column, with a moving gradient masked over the whole menu.
