<img width="456" alt="FrameUp Logo" src="https://user-images.githubusercontent.com/2143656/149010960-2b0e1200-b6d4-40a5-bbe7-4aabc5ce6b09.png">

[![Swift Compatibility](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fryanlintott%2FFrameUp%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/ryanlintott/FrameUp)
[![Platform Compatibility](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fryanlintott%2FFrameUp%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/ryanlintott/FrameUp)
![License - MIT](https://img.shields.io/github/license/ryanlintott/FrameUp)
![Version](https://img.shields.io/github/v/tag/ryanlintott/FrameUp?label=version)
![GitHub last commit](https://img.shields.io/github/last-commit/ryanlintott/FrameUp)
[![Mastodon](https://img.shields.io/badge/mastodon-@ryanlintott-5c4ee4.svg?style=flat)](http://mastodon.social/@ryanlintott)
[![Twitter](https://img.shields.io/badge/twitter-@ryanlintott-blue.svg?style=flat)](http://twitter.com/ryanlintott)

# Overview
A collection of SwiftUI tools to help with layout.

- SwiftUI [`Layouts`](#layouts) like [`HFlowLayout`](#hflowlayout), [`VFlowLayout`](#vflowlayout), [`VMasonryLayout`](#vmasonrylayout), [`HMasonryLayout`](#hmasonrylayout), and [`LayoutThatFits`](#layoutthatfits)
- [`AutoRotatingView`](#autorotatingview) to set allowable orientations for a view.
- [Frame Adjustment](#frame-adjustment) tools like [`WidthReader`](#widthreader), [`HeightReader`](#heightreader), [`onSizeChange(perform:)`](#onsizechangeperform), [`keyboardHeight`](#keyboardHeight), [`.relativePadding`](#relativepaddingedges-lengthfactor), [`ScaledView`](#scaledview) and [`OverlappingImage`](#overlappingimage).
- [unclippedTextRenderer](#unclippedtextrenderer) for fixing clipped `Text`. 
- [`SmartScrollView`](#smartscrollview) with optional scrolling, a content-fitable frame, and live edge inset values.
- [`FlippingView`](#flippingview) and [`rotation3DEffect(back:)`](#rotation3deffectback) for making flippable views with a different view on the back side.
- [`TabMenu`](#tabmenu), a customizable iOS tab menu with `onReselect` and `onDoubleTap` functions.

Some widget-related tools

- [`AccessoryInlineImage`](#accessoryinlineimage) to use any image inside an `accessoryInline` widget
- [`WidgetSize`](#widgetsize) - Similar to WidgetFamily but returns widget frame sizes by device and doesn't require `WidgetKit`
- [`WidgetDemoFrame`](#widgetdemoframe) creates accurately sized widget frames you can use in an iOS or macOS app.

Additional SwiftUI tools for iOS 14+15, macOS 11+12, watchOS 7+8, and tvOS 14+15

- [`FULayout`](#fulayout) for building custom layouts (similar to SwiftUI `Layout`).
- FULayouts: [`HFlow`](#hflow), [`VFlow`](#vflow), [`HMasonry`](#hmasonry), [`VMasonry`](#vmasonry), [`FULayoutThatFits`](#fulayoutthatfits), and [`FUViewThatFits`](#fuviewthatfits)
- [`AnyFULayout`](#anyfulayout) to wrap multiple layouts and switch between with animation.
- Make your own [`Custom FULayout`](#custom-fulayout) and add a SwiftUI `Layout` version using [`LayoutFromFULayout`](#layoutfromfulayout)
- [`TagView`](#tagview) for a simple flow view based on an array of elements.
- [`WidgetRelativeShape`](#widgetrelativeshape) fixes a `ContainerRelativeShape` bug on iPad.


# Demo App
Check out [FrameUpExample](https://github.com/ryanlintott/FrameUpExample) to see how to use this package in your app.

# Installation and Usage
This package is compatible with iOS 14+, macOS 11+, watchOS 7+, tvOS 14+, and visionOS.

1. In Xcode go to `File -> Add Packages`
2. Paste in the repo's url: `https://github.com/ryanlintott/FrameUp` and select by version.
3. Import the package using `import FrameUp`

## Is it Production-Ready?
Really it's up to you. I currently use this package in my own [Old English Wordhord app](https://oldenglishwordhord.com/app).

Additionally, if you find a bug or want a new feature add an issue and I will get back to you about it.

# Support This Project
FrameUp is open source and free but if you like using it, please consider supporting my work.

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/X7X04PU6T)

- - -
# Features

## Layouts
*\*iOS 16+, macOS 13+, watchOS 9+, tvOS 16+*

If your target OS is older and doesn't support SwiftUI `Layout`, use [`FULayout`](#fulayout) equivalents.

### HFlowLayout
A `Layout` that arranges views in horizontal rows flowing from one to the next with adjustable horizontal and vertical spacing and support for horiztonal and vertical alignment including a justified alignment that will space elements in completed rows evenly.

Each row height will be determined by the tallest element. The overall frame size will fit to the size of the laid out content.

```swift
HFlowLayout {
    ForEach(["Hello", "World", "More Text"], id: \.self) { item in
        Text(item.value)
    }
}
```

### VFlowLayout
A `Layout` that arranges views in vertical columns flowing from one to the next with adjustable horizontal and vertical spacing and support for horiztonal and vertical alignment including a justified alignment that will space elements in completed columns evenly.

Each column width will be determined by the widest element. The overall frame size will fit to the size of the laid out content.

```swift
VFlowLayout {
    ForEach(["Hello", "World", "More Text"], id: \.self) { item in
        Text(item.value)
    }
}
```

### VMasonryLayout
A `Layout` that arranges views into a set number of columns by adding each view to the shortest column.

```swift
VMasonryLayout(columns: 3) {
    ForEach(["Hello", "World", "More Text"], id: \.self) { item in
        Text(item.value)
    }
}
```
 
### HMasonryLayout
A `Layout` that arranges views into a set number of rows by adding each view to the shortest row.

```swift
HMasonryLayout(rows: 3) {
    ForEach(["Hello", "World", "More Text"], id: \.self) { item in
        Text(item.value)
    }
}
```

### LayoutThatFits
Creates a layout using the first layout that fits in the axes provided from the array of layout preferences.

```swift
LayoutThatFits(in: .horizontal, [HStackLayout(), VStackLayout()]) {
    Color.green.frame(width: 50, height: 50)
    Color.yellow.frame(width: 50, height: 200)
    Color.blue.frame(width: 50, height: 100)
}
```

## AutoRotatingView
*\*iOS only*

A view that rotates any view to match the current device orientation if it's in an array of allowed orientations. This is most useful for allowing fullscreen image views to use landscape orientations while inside a portrait-only app. It can also be used to limit orientations such as landscape-only in an app that allows portrait. Rotations can be animated.

```swift
AutoRotatingView([.portrait, .landscapeLeft, .landscapeRight], animation: .default) {
    Image("MyFullscreenImage")
        .resizable()
        .scaledToFit()
}
```

## Frame Adjustment
### WidthReader
A view that takes the available width and provides this measurement to its content. Unlike 'GeometryReader' this view will not take up all the available height and will instead fit the height of the content.

Useful inside vertical scroll views where you want to measure the width without specifying a frame height.

```swift
ScrollView {
    WidthReader { width in
        HStack(spacing: 0) {
            Text("This text frame is set to 70% of the width.")
                .frame(width: width * 0.7)
                .background(Color.green)

            Circle()
        }
    }
    .foregroundColor(.white)
    .background(Color.blue)

    Text("The WidthReader above does not have a fixed height and will grow to fit the content.")
        .padding()
}
```

### HeightReader
A view that takes the available height and provides this measurement to its content. Unlike 'GeometryReader' this view will not take up all the available width and will instead fit the width of the content.

Useful inside horizontal scroll views where you want to measure the height without specifying a frame width.

```swift
ScrollView(.horizontal) {
    HeightReader { height in
        VStack(spacing: 0) {
            Text("This\ntext\nframe\nis\nset\nto\n70%\nof\nthe\nheight.")
                .frame(height: height * 0.7)
                .background(Color.green)

            Circle()
        }
        .foregroundColor(.white)
        .background(Color.blue)

        Text("\nThe\nHeightReader\nto\nthe\nleft\ndoes\nnot\nhave\na\nfixed\nwidth\nand\nwill\ngrow\nto\nfit\nthe\ncontent.")
            .padding()
    }
}
```

### .onSizeChange(perform:)
Adds an action to perform when parent view size value changes.

```swift
struct OnSizeChangeExample: View {
    @State private var size: CGSize = .zero
    
    var body: some View {
        Text("Hello, World!")
            .padding(100)
            .background(Color.blue)
            .onSizeChange { size in
                self.size = size
            }
            .overlay(Text("size: \(size.width) x \(size.height)"), alignment: .bottom)
    }
}
```

### equalWidthPreferred
Views with `.equalWidthPreferred()` inside a view with `.equalWidthContainer()` will have widths equal to the largest view. If space is limited views will shrink equally, each to a minimum size that fits the content. It works in `HStack`, `VStack` and even custom layouts like `HFlow`

This works especially well in macOS when you want all buttons on a window to have the same width while still allowing some shrinking.

```swift
HStack {
    Button { } label: {
        Text("More Information")
            .equalWidthPreferred()
    }
    Spacer()
    
    Button { } label: {
        Text("Cancel")
            .equalWidthPreferred()
    }
    
    Spacer()
    
    Button { } label: {
        Text("OK")
            .equalWidthPreferred()
    }
}
.equalWidthContainer()
.frame(maxWidth: 400)
.padding()
```

### equalHeightPreferred
Views with `.equalHeightPreferred()` inside a view with `.equalHeightContainer()` will have heights equal to the largest view. If space is limited views will shrink equally, each to a minimum size that fits the content. It works in `HStack`, `VStack` and even custom layouts like `VFlow`

```swift
HStack {
    Group {
        Text("Here's something with some text")
        
        Text("And more")
    }
    .foregroundColor(.white)
    .padding()
    .equalHeightPreferred()
    .background(Color.blue.cornerRadius(10))
}
.equalHeightContainer()
.frame(maxWidth: 200)
```

### keyboardHeight
An environment variable that will update with animation as the iOS keyboard appears and disappears. It will always be zero for non-iOS platforms. 

`Animation.keyboard` is added as an approximation of the keyboard animation curve and is used by keyboardHeight.

In order to use keyboardHeight you first need to add it somewhere at the top of your view heirachry so it can see the entire frame. It will use a GeometryReader on a background layer to measure the keyboard so ensure the view is using the entire available height.

```swift
struct ContentView: View {
    var body: some View {
        MyView()
            .frame(maxHeight: .infinity)
            .keyboardHeightEnvironmentValue()
    }
}
```

When you want to access the keyboardHeight use an environment variable. If you're using it to adjust the position of a view that should avoid the keyboard use the keyboardHeight directly and make sure the view ignores the keyboard safe area.

```swift
struct MyView: View {
    @Environment(\.keyboardHeight) var keyboardHeight
    @State private var text = ""
    
    var body: some View {
        TextField("Moves with keyboard", text: $text)
            .keyboardHeightEnvironmentValue()
            .padding(.bottom, keyboardHeight == 0 ? 100 : keyboardHeight)
            .ignoresSafeArea(.keyboard)
    }
}
```

### .relativePadding(edges:, lengthFactor:)
Adds a padding amount to specified edges of a view relative to the size of the view. Width is used for .leading/.trailing and height is used for .top/.bottom

Negative values can be used to overlap content.

```swift
Text("This text will have padding based on the width and height of its frame.")
    .relativePadding([.leading, .top], 0.2)
```

### ScaledView
A view modifier that scales a view using `scaleEffect` to match a frame size.

View must have an intrinsic content size or be provided a specific frame size. Final frame size may be different depending on modes chosen.

Uses ScaleMode to limit the view so it can only grow/shrink or both.

### Used in these view Extensions
- `scaledToFrame(size:,contentMode:,scaleMode:)`
- `scaledToFrame(width:,height:,contentMode:,scaleMode:)`
- `scaledToFit(size:,scaleMode:)`
- `scaledToFit(width:,height:,scaleMode:)`
- `scaledToFit(width:,scaleMode:)`
- `scaledToFit(height:,scaleMode:)`
- `scaledToFill(size:,scaleMode:)`
- `scaledToFill(width:,height:,scaleMode:)`

### OverlappingImage
An image view that can overlap content on the edges of its frame.

Image can overlap either on the vertical or horizontal axis but not both.

Be sure to consider spacing and use zIndex to place the image in front or behind content.

```swift
VStack(spacing: 0) {
    Text("Overlapping Image")
        .font(.system(size: 50))

    OverlappingImage(Image(systemName: "star.square"), aspectRatio: 1.0, top: 0.1, bottom: 0.25)
        .padding(.horizontal, 50)
        .zIndex(1)

    Text("The image above will overlap content above and below.")
        .padding(20)
}
```

## Text
### unclippedTextRenderer
*\*iOS 18+, macOS 15+, watchOS 11+, tvOS 18+, visionOS 2+*

SwiftUI `Text` has a clipping frame that cannot be adjusted and will occasionally clip the rendered text. This modifier applies an `UnclippedTextRenderer` that removes this clipping frame.

This modifier is unnecessary if another text renderer is used as all text renderers will remove the clipping frame.

```swift
Text("f")
    .font(.custom("zapfino", size: 30))
    .unclippedTextRenderer()
```

## SmartScrollView
*\*iOS only*

A ScrollView with extra features.
- Optional Scrolling - When active, the view will only be scrollable if the content is too large to fit in the parent frame. Enabled by default.
- Shrink to Fit - When active, the view will only take as much vertical and horizontal space as is required to fit the content. Enabled by default.
- Edge Insets - An onScroll function runs when the edge insets update. This occurs on scroll, on first load and on any size change to the scroll view or the content. Insets are negative when content edges are beyond the scroll view edges. Values may not be exactly 0 but will be less than 1 when content edges match scroll view edges.

```swift
SmartScrollView(.vertical, showsIndicators: true, optionalScrolling: true, shrinkToFit: true) {
    // Content here
} onScroll: { edgeInsets in
    // Runs when edge insets change
}
```

**Limitations:**
- If placed directly inside a NavigationView with a resizing header, this view may behave strangely when scrolling. To avoid this add 1 point of padding just inside the NavigationView.
- If the available space for this view grows for any reason other than screen rotation, this view might not grow to fill the space.

## FlippingView

### FlippingView
A two-sided view that can be flipped by tapping or swiping.

The axis, anchor, perspective, drag distance to flip, animation for tap to flip and more can all be customized.

For visionOS a slightly different initializer might be needed and the flips will occur in 3d space. If instead you want a perspective effect on a flat view you can use `PerspectiveFlippingView`

```swift
FlippingView(flips: $flips) {
    Color.blue.overlay(Text("Up"))
} back: {
    Color.red.overlay(Text("Back"))
}
```

### rotation3DEffect(angle:axis:anchor:anchorZ:perspective:backsideFlip:back:)
*\*deprecated in visionOS*
Renders a view’s content as if it’s rotated in three dimensions around the specified axis with a closure containing a different view to show on the back.

The example below is a view with two sides. One blue side that says "Front" and a red side on the back that says "Back". Changing the angle will show each side as it becomes visible.

```swift
Color.blue.overlay(Text("Front"))
    .rotation3DEffect(angle) {
        Color.red.overlay(Text("Back"))
    }
```

### rotation3DEffect(angle:axis:anchor:backsideFlip:back:)
*\*visionOS*
Rotates this view’s rendered output in three dimensions around the given axis of rotation with a closure containing a different view on the back. A minimum thickness that offsets the two views is required to ensure the side facing the user renders on top.
```swift
Color.blue.overlay(Text("Front"))
    .rotation3DEffect(angle) {
        Color.red.overlay(Text("Back"))
    }
```

### perspectiveRotationEffect(angle:axis:anchor:anchorZ:perspective:backsideFlip:back:)
*\*visionOS*
Renders a view’s content as if it’s rotated in three dimensions around the specified axis with a closure containing a different view to show on the back. The view is not actually rotated in 3d space.

```swift
Color.blue.overlay(Text("Front"))
    .rotation3DEffect(angle) {
        Color.red.overlay(Text("Back"))
    }
```

## TabMenu
*\*iOS only*

Customizable tab menu bar view designed to mimic the style of the default tab menu bar on iPhone. Images or views and name provided are used to mask another provided view which is often a color.

Features:
- Use any image or AnyView as a mask for the menu item.
- Use any view as the 'color' including gradients.
- onReselect closure that returns a NamedAction that triggers when the active tab is selected.
- onDoubleTap closure that returns a NamedAction that triggers when the active tab is double-tapped.
- accessibility actions are automatically added for onReselect and onDoubleTap if they are added.

```swift
let items = [
    TabMenuItem(icon: AnyView(Circle().stroke().overlay(Text("i"))), name: "Info", tab: 0),
    TabMenuItem(image: Image(systemName: "star"), name: "Favourites", tab: 1),
    TabMenuItem(image: Image(systemName: "bookmark"), name: "Categories", tab: 2),
    TabMenuItem(image: Image(systemName: "books.vertical"), name: "About", tab: 3)
]

TabMenuView(selection: $selection, items: items) { isSelected in
    Group {
        if isSelected {
            Color.accentColor
        } else {
            Color(.secondaryLabel)
        }
    }
} onReselect: {
    NamedAction("Reselect") {
        print("TabMenu item \(selection) reselected")
    }
} onDoubleTap: {
    NamedAction("Double Tap") {
        print("TabMenu item \(selection) doubletapped")
    }
}
```

## Widgets
### AccessoryInlineImage
An image that will be scaled and have the rendering mode adjusted to work inside an `accessoryInline` widget. The image will scale to fit the frame and have the template rendering mode applied.

Use inside a Label's icon property.

```swift
Label {
    Text("Label Text")
} icon: {
    AccessoryInlineImage("myImage")
}
```

### WidgetSize
An enum similar to WidgetFamily but returns widget frame sizes by device and doesn't require `WidgetKit` so it can be used inside your main iOS or macOS app.

#### `sizeForiPhone(screenSize:)
Returns the size of the widget based on the screen size provided.

#### `sizeForiPad(screenSize:, target:)
Returns either the design canvas or the home screen size (depending on the supplied target) of the widget based on the screen size provided. On iPads widget content is put on the design canvas then scaled to fit the home screen size. (The `WidgetDemoFrame` will do this scaling for you)

#### `supportedSizesForCurrentDevice` (iOS Only)
Returns an array of supported widget sizes based on device type and iOS version.

#### `sizeForCurrentDevice` (iOS Only)
Returns the size of the widget based on the current device.

All widget size information was sourced from:
[Apple - Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/widgets#Specifications)

### WidgetDemoFrame
Creates widget frames sized for a supplied screen size or the current device (iOS only). Used for showing example widgets from inside the app.

Corner radius size defaults to 20 and may not be the same as the actual widget corner radius.

For iPad, widget views use a design size and are scaled to a smaller Home Screen size using `ScaledView`. This demo frame uses the same scaling to properly preview the widget. All sizes will work on all devices and all versions of iOS (even extraLarge on iPhone with iOS 14.0).

```swift
WidgetDemoFrame(.medium, cornerRadius: 20) { size, cornerRadius in
    Text("Demo Widget")
}
```

## Additional Tools
### Proportionable
A protocol that adds helpful parameters like `aspectFormat`, `aspectRatio`, `minDimension`, and `maxDimension`.

Used on types that have `width` and `height` properties like `CGSize`.

How to add conformance in your app:
```swift
extension CGSize: Proportionable { }
```

### frame(size:,alignment:)
Alternative to the `frame(width:,height:,alignment:)` View modifier that takes a `CGSize` parameter instead.

----
# Features for iOS 14+15

## FULayout
If you like the SwiftUI `Layout` protocol but you need to target an older OS that doesn't support it then the `FULayout` protocol might be your answer!

An `FULayout` will work in the same way as a SwiftUI `Layout`. The main difference is it will require a `maxWidth` or `maxHeight` parameter when initializing in order to know the available space. This can be provided by `GeometryReader` or with [`WidthReader`](#widthreader) or [`HeightReader`](#heightreader) from this package.

### ViewBuilder
*\*Deprecated iOS 16, macOS 13, watchOS 7, tvOS 14, visionOS 1*
An `FULayout` uses `callAsFunction()` with a view builder so you can use it just like a SwiftUI `Layout`.

```swift
VFlow(maxWidth: 200) {
    Text("Hello")
    Text("World")
}
```

*Caution: This method uses Apple's private protocol `_VariadicView` under the hood. There is a small risk Apple could change the implementation so if this concerns you, use method 2 below.*

### `.forEach()`
*\*Deprecated iOS 16, macOS 13, watchOS 7, tvOS 14, visionOS 1*
This method works in a very similar way to `ForEach()`.

```swift
MyFULayout().forEach(["Hello", "World"], id: \.self) { item in
        Text(item.value)
    }
}
```

## FULayouts
### HFlow
*\*Deprecated iOS 16, macOS 13, watchOS 7, tvOS 14, visionOS 1*
The [`FULayout`](#fulayout) equivalent of [`HFlowLayout`](#hflowlayout).

A FrameUp `FULayout` that arranges views in horizontal rows flowing from one to the next with adjustable horizontal and vertical spacing and support for horiztonal and vertical alignment including a justified alignment that will space elements in completed rows evenly.

Each row height will be determined by the tallest view in that row.

```swift
WidthReader { width in
    HFlow(maxWidth: width) {
        ForEach(["Hello", "World", "More Text"], id: \.self) { item in
            Text(item.value)
        }
    }
}
```

### VFlow
*\*Deprecated iOS 16, macOS 13, watchOS 7, tvOS 14, visionOS 1*
The [`FULayout`](#fulayout) equivalent of [`VFlowLayout`](#vflowlayout).

A FrameUp `FULayout` that arranges views in vertical columns flowing from one to the next with adjustable horizontal and vertical spacing and support for horiztonal and vertical alignment including a justified alignment that will space elements in completed columns evenly.

Each column width will be determined by the widest element.

```swift
WidthReader { width in
    VFlow(maxWidth: width) {
        ForEach(["Hello", "World", "More Text"], id: \.self) { item in
            Text(item.value)
        }
    }
}
```
 
### HMasonry
*\*Deprecated iOS 16, macOS 13, watchOS 7, tvOS 14, visionOS 1*
The [`FULayout`](#fulayout) equivalent of [`HMasonryLayout`](#hmasonrylayout).

A FrameUp `FULayout` that arranges views into a set number of rows by adding each view to the shortest row.

```swift
HeightReader { height in
    HMasonry(columns: 3, maxHeight: height) {
        ForEach(["Hello", "World", "More Text"], id: \.self) { item in
            Text(item.value)
                .frame(maxHeight: .infinity, alignment: .center)
        }
    }
}
```

### VMasonry
*\*Deprecated iOS 16, macOS 13, watchOS 7, tvOS 14, visionOS 1*
The [`FULayout`](#fulayout) equivalent of [`VMasonryLayout`](#vmasonrylayout).

A FrameUp `FULayout` that arranges views into a set number of rows by adding each view to the shortest row.

```swift
WidthReader { width in
    VMasonry(columns: 3, maxWidth: width) {
        ForEach(["Hello", "World", "More Text"], id: \.self) { item in
            Text(item.value)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}
```

### FULayoutThatFits
*\*Deprecated iOS 16, macOS 13, watchOS 7, tvOS 14, visionOS 1*
The [`FULayout`](#fulayout) equivalent of [`LayoutThatFits`](#layoutthatfits).

An `FULayout` that picks the first provided layout that will fit the content in the provided maxWidth, maxHeight, or both. This is most helpful when switching between `HStackFULayout` and `VStackFULayout` as the content only needs to be provided once and will even animate when the stack changes.

```swift
FULayoutThatFits(
    maxWidth: maxWidth,
    layouts: [
        HStackFULayout(maxHeight: 1000),
        VStackFULayout(maxWidth: maxWidth)
    ]
) {
    Color.green.frame(width: 50, height: 50)
    Color.yellow.frame(width: 50, height: 200)
    Color.blue.frame(width: 50, height: 100)
}
```

### FUViewThatFits
*\*Deprecated iOS 16, macOS 13, watchOS 7, tvOS 14, visionOS 1*
The [`FULayout`](#fulayout) equivalent of SwiftUI `ViewThatFits`.

An `FULayout` that presents the first view that fits the provided maxWidth, maxHeight, or both depending on which parameters are used.

As this view cannot measure the available space the maxWidth and/or maxHeight parameters need to be passed in using a `GeometryReader`, `WidthReader`, or `HeightReader`.

```swift
WidthReader { width in
    FUViewThatFits(maxWidth: width) {
        Group {
            Text("This layout will pick the first view that fits the available width.")
            Text("Maybe this?")
            Text("OK!")
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}
```

(`.fixedSize` needs to be used in this example or the first view will automatically fit by truncating the text)

### FULayout Stacks
Alternative stack layouts that can be wrapped in [`AnyFULayout`](#anyfulayout) and then toggled between with animation. Useful when you want to toggle between VStack and HStack based on available space.

#### HStackFULayout
*\*Deprecated iOS 16, macOS 13, watchOS 7, tvOS 14, visionOS 1*
Similar to `HStack` but `Spacer()` cannot be used and content will always use a fixed size on the horizontal axis.

#### VStackFULayout
*\*Deprecated iOS 16, macOS 13, watchOS 7, tvOS 14, visionOS 1*
Similar to `VStack` but `Spacer()` cannot be used and content will always use a fixed size on the vertical axis.

#### ZStackFULayout
*\*Deprecated iOS 16, macOS 13, watchOS 7, tvOS 14, visionOS 1*
Similar to `ZStack` but content will always use a fixed size on both the vertical and horizontal axes.

### AnyFULayout
*\*Deprecated iOS 16, macOS 13, watchOS 7, tvOS 14, visionOS 1*
The [`FULayout`](#fulayout) equivalent of SwiftUI `AnyLayout`.

A type-erased FrameUp layout can be used to wrap multiple layouts and switch between them with animation.

```swift
struct AnyFULayoutSimple: View {
    let isVStack: Bool
    let maxSize: CGSize
    
    var layout: any FULayout {
        isVStack ? VStackFULayout(maxWidth: maxSize.width) : HStackFULayout(maxHeight: maxSize.height)
    }
    
    var body: some View {
        AnyFULayout(layout) {
            Text("First")
            Text("Second")
            Text("Third")
        }
        .animation(.spring(), value: isVStack)
    }
}
```

### Custom FULayout

The FrameUp [`FULayout`](#fulayout) protocol requires you to define which axes are fixed, the maximum item size, and a function that takes view sizes and outputs view offsets.

Below is an example layout that arranges views on left and right sides of a central line.

```swift
struct CustomFULayout: FULayout {
    /// Add parameters here to adjust layout
    
    /// Define these required parameters
    var fixedSize: Axis.Set = .horizontal
    var maxItemWidth: CGFloat? { maxWidth }
    var maxItemHeight: CGFloat? = nil
    
    func contentOffsets(sizes: [Int : CGSize]) -> [Int : CGPoint] {
        /// Write code that uses the dictionary of sizes and your parameters to output a dictionary of offsets from the top left corner.
    }
}
```

### LayoutFromFULayout

If you've created an [`FULayout`](#fulayout) you can use it to easily create a SwiftUI `Layout`.

```swift
struct CustomLayout: LayoutFromtFULayout {
    /// Add parameters here to adjust layout
    
    /// Add this function that will create the associated FULayout
    func fuLayout(maxSize: CGSize) -> CustomFULayout {
        CustomFULayout(
            /// Pass parameters through to FULayout using maxSize to help define the maximum item size.
        )
    }
}
```

## TagView
An older and much simpler version of [`HFlow`](#hflow) not based on `FULayout`.

### TagView
A view that creates views based on an array of elements from left to right, adding rows when needed. Each row height will be determined by the tallest element.

*Warning: Does not work in ScrollView.*

```swift
TagView(elements: ["One", "Two", "Three"]) { element in
    Text(element)
}
```

### TagViewForScrollView
A view that creates views based on an array of elements from left to right, adding rows when needed. Each row height will be determined by the tallest element.

A maximum width must be provided but `WidthReader` can be used to get the value.

```swift
WidthReader { width in
    TagView(maxWidth: width, elements: ["One", "Two", "Three"]) { element in
        Text(element)
    }
}
```

## Widget bugfixes

### WidgetRelativeShape
*\*iOS only*

A re-scaled version of `ContainerRelativeShape` used to fix a bug with the corner radius on iPads running iOS 15 and earlier. It acts exactly the same as ContainerRelativeShape for iOS 16 and up.

This example has a blue background with a 1 point inset. On an iPad running iOS 15 or earlier, the red background will show on the corners as the corner radius does not match.

```swift
Text("Example widget")
    .background(.blue)
    .clipShape(WidgetRelativeShape(.systemSmall))
    .background(
        ContainerRelativeShape()
            .fill(.red)
    )
    .padding(1)
```








