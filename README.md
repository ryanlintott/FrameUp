<img width="456" alt="FrameUp Logo" src="https://user-images.githubusercontent.com/2143656/149010960-2b0e1200-b6d4-40a5-bbe7-4aabc5ce6b09.png">

[![Swift Compatibility](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fryanlintott%2FFrameUp%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/ryanlintott/FrameUp)
[![Platform Compatibility](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fryanlintott%2FFrameUp%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/ryanlintott/FrameUp)
![License - MIT](https://img.shields.io/github/license/ryanlintott/FrameUp)
![Version](https://img.shields.io/github/v/tag/ryanlintott/FrameUp?label=version)
![GitHub last commit](https://img.shields.io/github/last-commit/ryanlintott/FrameUp)
[![Twitter](https://img.shields.io/badge/twitter-@ryanlintott-blue.svg?style=flat)](http://twitter.com/ryanlintott)

# Overview
A Swift Package with a collection of SwiftUI framing views and tools to help with layout.

- [`AutoRotatingView`](#autorotatingview) to set allowable orientations for a view.
- ['Frame Adjustment'(#frameadjustment) tools like [`WidthReader`](#widthreader), [`HeightReader`](#heightreader), [`onSizeChange(perform:)`](#onsizechangeperform), [`.relativePadding`](#relativepaddingedges-lengthfactor), [`ScaledView`](#scaledview) and [`OverlappingImage`](#overlappingimage).
- [`FULayout`](#fulayout) for building custom layouts (similar to SwiftUI `Layout`).
- Included FULayouts: [`HFlow`](#hflow), [`VFlow`](#vflow), [`HMasonry`](#hmasonry), and [`VMasonry`](#vmasonry).
- [`AnyFULayout`](#anyfulayout) to wrap multiple layouts and switch between with animation.
- [`FUViewThatFits`](#fuviewthatfits) (similar to SwiftUI `ViewThatFits`)
- [`FULayoutThatFits`](#fulayoutthatfits) to use an `FULayout` that fits with the same content.
- Make your own [`Custom FULayout`](#customfulayout).
- SwiftUI [`Layout`](#layout) versions of `FULayout` views built using [`LayoutFromFULayout`](#layoutfromfulayout).
- [`LayoutThatFits`](#layoutthatfits) to use a `Layout` that fits with the same content.
- [`SmartScrollView`](#smartscrollview) with optional scrolling, a content-fitable frame, and live edge inset values.
- [`TabMenuView`](#tabmenuview), a customizable iOS tab menu with `onReselect` and `onDoubleTap` functions.
- [`TagView`](#tagview) and [`TagViewForScrollView`](#tagviewforscrollview) for simple flow view based on an array of elements.
- [`WidgetSize`](#widgetsize) - Similar to WidgetFamily but returns widget frame sizes by device and doesn't require `WidgetKit`
- [`WidgetDemoFrame`](#widgetdemoframe) creates accurately sized widget frames you can use in an iOS or macOS app.
- [`WidgetRelativeShape`](#widgetrelativeshape) fixes a `ContainerRelativeShape` bug on iPad.
- [`TwoSidedView`](#twosidedview) for making flippable views with a different view on the back side.

# FrameUpExample
Check out the [example app](https://github.com/ryanlintott/FrameUpExample) to see how you can use this package in your iOS app.

# Installation
1. In Xcode 13 and up use `File -> Add Packages` or in Xcode 12 go to `File -> Swift Packages -> Add Package Dependency`
2. Paste in the repo's url: `https://github.com/ryanlintott/FrameUp` and select by version.

# Usage
Import the package using `import FrameUp`

# Platforms
This package is compatible with iOS 14 or later and macOS 11 or later.

# Is this Production-Ready?
Really it's up to you. I currently use this package in my own [Old English Wordhord app](https://oldenglishwordhord.com/app).

# Support
If you like this package, buy me a coffee to say thanks!

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/X7X04PU6T)

- - -
# Details
## AutoRotatingView
*iOS only*
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

Example:
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

Example:
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

## FULayout
Similar to the SwiftUI `Layout` protocol available in iOS 16 and macOS 13, the FrameUp layout `FULayout` protocol is used to define view layouts.

### ViewBuilder
Use `FULayout` the same way as other built-in layout containers. It looks like a trailing closure but its using `callAsFunction()` on the initialized `FULayout`.

```swift
VFlow(maxWidth: 200) {
    Text("Hello")
    Text("World")
}
```

*Caution: Creating a container like this uses Apple's private protocol `_VariadicView` under the hood. There is a small risk Apple could change the implementation so if this concerns you, use method 2 below.*

### `.forEach()`
This method works in a very similar way to `ForEach()`.

```swift
MyFULayout().forEach(["Hello", "World"], id: \.self) { item in
        Text(item.value)
    }
}
```

## Included FULayouts
### HFlow
A FrameUp layout that arranges views in a row, adding rows when needed.
 
Each row height will be determined by the tallest element. The overall frame size will fit to the size of the laid out content.
 
A maximum height must be provided but `HeightReader` can be used to get the value (especially helpful when inside a `ScrollView`).
 
A FrameUp layout is not a view but it works like a view by using `callAsFunction`. There is also an alternative view function `.forEach()` that works like `ForEach`
 
Example:
```swift
HeightReader { height in
    HFlow(maxHeight: height) {
        ForEach(["Hello", "World", "More Text"], id: \.self) { item in
            Text(item.value)
        }
    }
}
```

### VFlow
 A FrameUp layout that arranges views in a column, adding columns when needed.

 Each column width will be determined by the widest element. The overall frame size will fit to the size of the laid out content.

 A maximum width must be provided but `WidthReader` can be used to get the value (especially helpful when inside a `ScrollView`).

 A FrameUp layout is not a view but it works like a view by using `callAsFunction`. There is also an alternative view function `.forEach()` that works like `ForEach`

 Example:
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
 A FrameUp layout that arranges views into rows, adding views to the shortest row.
 
 A maximum height must be provided but `HeightReader` can be used to get the value (especially helpful when inside a `ScrollView`).
 
 A FrameUp layout is not a view but it works like a view by using `callAsFunction`. There is also an alternative view function `.forEach()` that works like `ForEach`
 
 Example:
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
 A FrameUp layout that arranges views into columns, adding views to the shortest column.
 
 A maximum width must be provided but `WidthReader` can be used to get the value (especially helpful when inside a `ScrollView`).
 
 A FrameUp layout is not a view but it works like a view by using `callAsFunction`. There is also an alternative view function `.forEach()` that works like `ForEach`
 
 Example:
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

### FULayout Stacks
Alternative stack layouts that can be wrapped in `AnyFULayout` and then toggled between with animation. Useful when you want to toggle between VStack and HStack based on available space.

#### HStackFULayout
Similar to HStack but `Spacer()` cannot be used and content will always use a fixed size on the horizontal axis.

#### VStackFULayout
Similar to VStack but `Spacer()` cannot be used and content will always use a fixed size on the vertical axis.

#### ZStackFULayout
Similar to ZStack but content will always use a fixed size on both the vertical and horizontal axes.

### AnyFULayout
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

### FUViewThatFits
A layout that picks the first provided view that fits the available space.

A maxWidth, maxHeight, or both must be provided.

```swift
FUViewThatFits(maxWidth: 300, maxHeight: 30) {
    Group {
        Text("This layout will pick the first view that fits the available width.")
        Text("Maybe this?")
        Text("OK!")
    }
    .fixedSize(horizontal: true, vertical: false)
}
```

(`.fixedSize` needs to be used in this example or the first view will automatically fit by truncating the text)

### FULayoutThatFits
A layout that picks the first provided layout that will fit the provided content in the available space. This is most helpful when switching between `HStackFULayout` and `VStackFULayout` as the content only needs to be provided once and will even animate when the stack changes. 

A maxWidth, maxHeight, or both must be provided.

```swift
FULayoutThatFits(maxWidth: maxWidth, layouts: [HStackFULayout(maxHeight: 1000), VStackFULayout(maxWidth: maxWidth)]) {
    Color.green.frame(width: 50, height: 50)
    Color.yellow.frame(width: 50, height: 200)
    Color.blue.frame(width: 50, height: 100)
}
```

### Custom FULayout
The FrameUp layout protocol requires you to define which axes are fixed, the maximum item size, and a function that takes view sizes and outputs view offsets.

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

## Layout
*iOS 16+ or macOS 13+*

### Included Layouts
These SwiftUI `Layout` equivalents to the included `FULayout` views require iOS 16 or macOS 13 but you no longer need to supply a maxWidth or maxHeight.

- `HFlowLayout`
- `VFlowLayout`
- `HMasonryLayout`
- `VMasonryLayout`

Example:
```swift
HFlowLayout {
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

### LayoutFromFULayout
A protocol that quickly lets you make a `Layout` from an `FULayout`

```swift
struct CustomLayout: LayoutFromFULayout {
    /// Add parameters here to adjust layout
    
    /// Add this function that will create the associated FULayout
    func fuLayout(maxSize: CGSize) -> CustomFULayout {
        CustomFULayout(
            /// Pass parameters through to FULayout using maxSize to help define the maximum item size.
        )
    }
}
```

## SmartScrollView
*iOS only*
A ScrollView with extra features.
- Optional Scrolling - When active, the view will only be scrollable if the content is too large to fit in the parent frame. Enabled by default.
- Shrink to Fit - When active, the view will only take as much vertical and horizontal space as is required to fit the content. Enabled by default.
- Edge Insets - An onScroll function runs when the view is scrolled and reports the edge insets. Insets are negative when content edges are beyond the scroll view edges.

Example:
```swift
SmartScrollView(.vertical, showsIndicators: true, optionalScrolling: true, shrinkToFit: true) {
    // Content here
} onScroll: { edgeInsets in
    // Runs when view is scrolled
}
```

**Limitations:**
- If placed directly inside a NavigationView with a resizing header, this view may behave strangely when scrolling. To avoid this add 1 point of padding to the top of this view.
- If the available space for this view grows for any reason other than screen rotation, this view will not grow to fill the space. If you know the value that causes this change, add an `.id(value)` modifier below this view to force the view to reinitialize. This will cause it to scroll to the top.
- `FULayout` views like `HFlow`, `VMasonry`, etc will not work inside `SmartScrollView`

## TabMenuView
*iOS only*
Customizable tab menu bar view designed to mimic the style of the default tab menu bar on iPhone. Images or views and name provided are used to mask another provided view which is often a color.

Features:
- Use any image or AnyView as a mask for the menu item.
- Use any view as the 'color' including gradients.
- onReselect closure that returns a NamedAction that triggers when the active tab is selected.
- onDoubleTap closure that returns a NamedAction that triggers when the active tab is double-tapped.
- accessibility actions are automatically added for onReselect and onDoubleTap if they are added.

Example:
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

## TagView
Similar to the `HFlow` but a much simpler implementation not based on `FULayout`.

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

## Widgets
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

iOS Example:
```swift
WidgetDemoFrame(.medium, cornerRadius: 20) { size, cornerRadius in
    Text("Demo Widget")
}
```

### WidgetRelativeShape (iOS only)
A re-scaled version of `ContainerRelativeShape` used to fix a bug with the corner radius on iPads running iOS 15 and earlier.

Example:
This widget view has a blue background with a 1 point inset. On an iPad running iOS 15 or earlier, the red background will show on the corners as the corner radius does not match.
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

## TwoSidedView
### rotation3DEffect(angle:, axis:, anchor:, anchorZ, perspective:, back:)
An alternative to rotation3DEffect that provides a closure for views that will be seen on the back side of this view.

The example below is a view with two sides. One blue side that says "Front" and a red side on the back that says "Back". Changing the angle will show each side as it becomes visible.

```swift
Color.blue.overlay(Text("Front"))
    .rotation3DEffect(angle) {
        Color.red.overlay(Text("Back"))
    }
```

### FlippingView
A two-sided view that can be flipped by tapping or swiping.

The axis, anchor, perspective, drag distance to flip, animation for tap to flip and more can all be customized.

```swift
FlippingView(flips: $flips) {
    Color.blue.overlay(Text("Up"))
} back: {
    Color.red.overlay(Text("Back"))
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
