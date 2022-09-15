<img width="456" alt="FrameUp Logo" src="https://user-images.githubusercontent.com/2143656/149010960-2b0e1200-b6d4-40a5-bbe7-4aabc5ce6b09.png">

[![Swift Compatibility](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fryanlintott%2FFrameUp%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/ryanlintott/FrameUp)
[![Platform Compatibility](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fryanlintott%2FFrameUp%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/ryanlintott/FrameUp)
![License - MIT](https://img.shields.io/github/license/ryanlintott/FrameUp)
![Version](https://img.shields.io/github/v/tag/ryanlintott/FrameUp?label=version)
![GitHub last commit](https://img.shields.io/github/last-commit/ryanlintott/FrameUp)
[![Twitter](https://img.shields.io/badge/twitter-@ryanlintott-blue.svg?style=flat)](http://twitter.com/ryanlintott)

# Overview
A Swift Package with a collection of SwiftUI framing views and tools to help with layout.

- Size readers like [`WidthReader`](#widthreader), [`HeightReader`](#heightreader), and [`onSizeChange(perform:)`](#onsizechangeperform)
- [`SmartScrollView`](#smartscrollview) with optional scrolling, a content-fitable frame, and live edge inset values.
- [`FULayout`](#fulayout) for building custom layouts (similar to SwiftUI `Layout` but works in iOS 14).
- [`HFlow`](#hflow) or [`VFlow`](#vflow) for presenting tags or any view in a flow style.
- [`VMasonry`](#vmasonry) or [`HMasonry`](#hmasonry) for presenting view in a masonry (Pinterest) style.
- Make your own [`CustomFULayout`](#make-your-own-fulayout).
- [`OverlappingImage`](#overlappingimage) that overlaps neighbouring content by a percent of the image size.
- [`.relativePadding`](#relativepaddingedges-lengthfactor) adds padding relative to the content view size.
- [`TabMenuView`](#tabmenuview), a customizable tab menu with `onReselect` and `onDoubleTap` functions.
- [`ScaledView`](#scaledview) to scale views and their frames to specific sizes.
- [`AutoRotatingView`](#autorotatingview) to give some views a different set of allowable orientations.
- [`WidgetSize`](#widgetsize) - Similar to WidgetFamily but returns widget frame sizes by device and doesn't require `WidgetKit`
- [`WidgetDemoFrame`](#widgetdemoframe) creates widget frames sized for the current device (and scaled for iPad)
- [`WidgetRelativeShape`](#widgetrelativeshape) fixes a bug with the corner radius of `ContainerRelativeShape` on iPad.
- [`Proportionable`](#proportionable) protocol with `aspectFormat`, `aspectRatio`, `minDimension`, and `maxDimension`
- View extension [`frame(size:,alignment:)`](#framesizealignment)

# FrameUpExample
Check out the [example app](https://github.com/ryanlintott/FrameUpExample) to see how you can use this package in your iOS app.

# Installation
1. In Xcode 13 `File -> Add Packages` or in Xcode 12 go to `File -> Swift Packages -> Add Package Dependency`
2. Paste in the repo's url: `https://github.com/ryanlintott/FrameUp` and select by version.

# Usage
Import the package using `import FrameUp`

# Platforms
This package is compatible with iOS 14 or later.

# Is this Production-Ready?
Really it's up to you. I currently use this package in my own [Old English Wordhord app](https://oldenglishwordhord.com/app).

# Support
If you like this package, buy me a coffee to say thanks!

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/X7X04PU6T)

- - -
# Details
## Size Readers
Unlike 'GeometryReader' these views will provide measurement of only one axis and will only take up as much space on the other axis as is needed for their child views.

### WidthReader
Provides the available width while fitting to the height of the content.

Useful inside vertical scroll views where you want to get the width without specifying a frame height.

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
Provides the available height while fitting to the width of the content.

Useful inside horizontal scroll views where you want to get the height without specifying a frame width.
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

## SmartScrollView
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

Limitations:
- If placed directly inside a NavigationView with a resizing header, this view may behave strangely when scrolling. To avoid this add 1 point of padding to the top of this view.
- If the available space for this view grows for any reason other than screen rotation, this view will not grow to fill the space. If you know the value that causes this change, add an `.id(value)` modifier below this view to trigger the view to recalculate. This will cause it to scroll to the top.

## FULayout
Similar to the SwiftUI `Layout` protocol, the FrameUp layout `FULayout` protocol is used to define view layouts.

### You can call them as functions.
This method is the most straightforward as it works the same as SwiftUI layouts.

```swift
MyFULayout() {
    Text("Hello")
    Text("World")
}
```

*Caution: `_VariadicView` is used under the hood. If this underscore protocol concerns you, use method 2 below.*

### You can use the `.forEach()` function.
This method uses a method that works in a very similar way to `ForEach()`.

```swift
MyFULayout().forEach(["Hello", "World"], id: \.self) { item in
        Text(item.value)
    }
}
```

### AnyFULayout
 A type-erased FrameUp layout can be used to wrap multiple layouts and switch between them with animation.

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
                .padding(12)
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(12)
                .clipped()
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
                 .padding(12)
                 .foregroundColor(.white)
                 .background(Color.blue)
                 .cornerRadius(12)
                 .clipped()
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
                .padding(12)
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(12)
                .clipped()
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
                    .padding(12)
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(12)
                    .clipped()
            }
        }
    }
 ```
 
### FULAyout Stacks
`HStackFULayout`, `VStackFULayout`, and `ZStackFULayout` are also available and helpful when you want to toggle between layout options.

## Make your own FULayout
The FrameUp layout protocol requires you to define which axes are fixed, the maximum item size, and a function that takes view sizes and ouputs view offsets.

Below is an example layout that arranges views on left and right sides of a central line.

```swift
struct CustomFULayout: FULayout {
    let maxWidth: CGFloat
    
    var fixedSize: Axis.Set = .horizontal
    var maxItemWidth: CGFloat? { maxWidth / 2 }
    var maxItemHeight: CGFloat? = nil
    
    func contentOffsets(sizes: [Int : CGSize]) -> [Int : CGPoint] {
        var heightOffset = 0.0
        var rowHeight = 0.0
        var offsets = [Int : CGPoint]()
        for size in sizes.sortedByKey() {
            let widthOffset = (size.key % 2 == 0) ? -size.value.width : 0
            
            offsets.updateValue(
                CGPoint(x: widthOffset, y: heightOffset),
                forKey: size.key
            )
            rowHeight = (size.key % 2 == 0) ? size.value.height : max(size.value.height, rowHeight)
            heightOffset += (size.key % 2 == 0) ? 0 : rowHeight
        }
        return offsets
    }
}
```

## OverlappingImage
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

## .relativePadding(edges:, lengthFactor:)
A view modifier that pads its content by the specified edge insets with a percentage of the content view size. Width is used for .leading/.trailing and height is used for .top/.bottom

Negative values can be used to overlap content.

```swift
Text("This text will have padding based on the width and height of its frame.")
    .relativePadding([.leading, .top], 0.2)
```

## TabMenuView
Customizable tab menu bar view designed to mimic the style of the default tab menu bar on iPhone. Images or views and name provied are used to mask another provided view which is often a color.

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

## ScaledView
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

## AutoRotatingView
A view that rotates any view to match the current device orientation if it's in an array of allowed orientations. This is most useful for allowing fullscreen image views to use landscape orientations while inside a portrait-only app. It can also be used to limit orientations such as landscape-only in an app that allows portrait. Rotations can be animated.

```swift
AutoRotatingView([.portrait, .landscapeLeft, .landscapeRight], animation: .default) {
    Image("MyFullscreenImage")
        .resizable()
        .scaledToFit()
}
```

## WidgetSize
An enum similar to WidgetFamily but returns widget frame sizes by device and doesn't require `WidgetKit`

### Cases
- small
- medium
- large
- extraLarge

### Key Functions and Properties
#### `supportedSizesForCurrentDevice`
Returns an array of supported widget sizes based on device type and iOS version.

#### `sizeForCurrentDevice`
The size of this WidgetSize on the current device.

All size information from:
[Apple - Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/widgets/overview/design/)

#### `scaleFactorForCurrentDevice`
How much the widget is scaled down to fit on the Home Screen.

Home Screen width divided by design canvas width. iPhone value will always be 1.

## WidgetDemoFrame
Creates widget frames sized for the current device (and scaled for iPad). Used for showing example widgets from inside the app.

Corner radius size defaults to 20 and may not be the same as the actual widget corner radius.

For iPad, widget views use a design size and are scaled to a smaller Home Screen size using `ScaledView`. This demo frame uses the same scaling to properly preview the widget. All sizes will work on all devices and all versions of iOS (even extraLarge on iPhone with iOS 14.0).

Example:
```swift
WidgetDemoFrame(.medium, cornerRadius: 20) { size, cornerRadius in
    Text("Demo Widget")
}
```

## WidgetRelativeShape
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

## Proportionable
A protocol that adds helpful parameters like `aspectFormat`, `aspectRatio`, `minDimension`, and `maxDimension`.

Used on types that have `width` and `height` properties like `CGSize`.

How to add conformance in your app:
```swift
extension CGSize: Proportionable { }
```

## View Extensions
### frame(size:,alignment:)
Alternative to `frame(width:,height:,alignment:)` that takes a `CGSize` parameter instead.
