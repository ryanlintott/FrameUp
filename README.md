<img width="400" alt="FrameUp Logo" src="https://user-images.githubusercontent.com/2143656/149010960-2b0e1200-b6d4-40a5-bbe7-4aabc5ce6b09.png"> 

![License - MIT](https://img.shields.io/github/license/ryanlintott/FrameUp)
![Version](https://img.shields.io/github/v/tag/ryanlintott/FrameUp?label=version)

# Overview
A collection of SwiftUI framing views and tools to help with layout.

- Size Readers like [`WidthReader`](#widthreader), [`HeightReader`](#heightreader), and [`onSizeChange(perform:)`](#onsizechangeperform)
- [`SmartScrollView`](#smartscrollview) with optional scrolling, a content-fitable frame, and live edge inset values.
- Flow views for presenting tags or any view. [`HFlow`](#hflow) or [`VFlow`](#vflow)
- [`OverlappingImage`](#overlappingimage) that overlaps neighbouring content by a percent of the image size.
- [`TabMenuView`](#tabmenuview), a customizable tab menu with `onReselect` and `onDoubleTap` functions.
- [`ScaledView`](#scaledview) to scale views and their frames to specific sizes.
- [`WidgetSize`](#widgetsize) - Similar to WidgetFamily but returns widget frame sizes by device and doesn't require `WidgetKit`
- [`WidgetDemoFrame`](#widgetdemoframe) creates widget frames sized for the current device (and scaled for iPad)
- [`WidgetRelativeShape`](#widgetrelativeshape) fixes a bug with the corner radius of `ContainerRelativeShape` on iPad.
- [`Proportionable`](#proportionable) protocol with `aspectFormat`, `aspectRatio`, `minDimension`, and `maxDimension`
- View extension [`frame(size:,alignment:)`](#framesizealignment)

# [FrameUpExample](https://github.com/ryanlintott/FrameUpExample)
Check out the example app to see how you can use this package in your iOS app.

# Installation
1. In XCode 12 go to `File -> Swift Packages -> Add Package Dependency` or in XCode 13 `File -> Add Packages`
2. Paste in the repo's url: `https://github.com/ryanlintott/FrameUp` and select by version.

# Usage
Import the package using `import FrameUp`

# Is this Production-Ready?
Really it's up to you. I originally developed, and currently use, many of the features in my own [Old English Wordhord app](https://oldenglishwordhord.com/app).

# Support
If you like this package you can always buy me a beer (I'm not a coffee drinker).

- - -
# Details
## Size Readers
Unlike 'GeometryReader' these views will provide measurement of only one axis and will only take up as much space on the other axis as is needed for their child views.

### WidthReader
Provides the available width while fitting to the height of the content.

### HeightReader
Provides the available height while fitting to the width of the content.

### .onSizeChange(perform:)
Adds an action to perform when parent view size value changes.

## SmartScrollView
A ScrollView with extra features.
- Optional Scrolling - When active, the view will only be scrollable if the content is too large to fit in the parent frame.
- Shrink to Fit - When active, the view will only take as much vertical and horizontal space as is required to fit the content.
- Edge Insets - An onScroll function runs when the view is scrolled and reports the edge insets. Insets are negative when content edges are beyond the scroll view edges.

These features are disabled by default and can be enabled in any combination. Similar to a standard `ScrollView` you can also specify the axes and toggle `showsIndicators`.

Example:
```swift
SmartScrollView(.vertical, showsIndicators: true, optionalScrolling: true, shrinkToFit: true) {
    // Content here
} onScroll: { edgeInsets in
    // Runs when view is scrolled
}
```

## Flow Views
### HFlow
A view that creates views based on a collection of data from left to right, adding rows when needed.

Each row height will be determined by the tallest element. The overall frame size will fit to the size of the laid out content.

A maximum width must be provided but `WidthReader` can be used to get the value (especially helpful when inside a `ScrollView`).

Example:
```swift
WidthReader { width in
    HFlow(["Hello", "World", "More Text"], maxWidth: width) { item in
        Text(item.value)
            .padding(12)
            .foregroundColor(.white)
            .background(Color.blue)
            .cornerRadius(12)
            .clipped()
    }
}
```

Adding or removing elements may not animate as intended as element ids are based on their index.

### VFlow
A view that creates views based on a collection of data from top to bottom, addcolumns when needed.

Each column width will be determined by the widest element. The overall frame swill fit to the size of the laid out content.

A maximum height must be provided but `HeightReader` can be used to get the va(especially helpful when  inside a `ScrollView`).

Example:
```swift
HeightReader { height in
    HFlow(["Hello", "World", "More Text"], maxHeight: height) { item in
        Text(item.value)
            .padding(12)
            .foregroundColor(.white)
            .background(Color.blue)
            .cornerRadius(12)
            .clipped()
    }
}
```

Adding or removing elements may not animate as intended as element ids are based on their index.

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

## TabMenuView
Customizable tab menu bar view designed to mimic the style of the default tab menu bar on iPhone. Images or views and name provied are used to mask another provided view which is often a color.

Features:
- Use any image or AnyView as a mask for the menu item.
- Use any view as the 'color' including gradients.
- onReselect function that triggers when the active tab menu item is selected.
- onDoubleTap function that triggers when any tab is double-tapped.

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
    print("TabMenu item \(selection) reselected")
} onDoubleTap: {
    print("TabMenu item \(selection) doubletapped")
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
A re-scaled version of `ContainerRelativeShape` used to fix a bug with the corner radius on iPads.

Example:
This widget view will have a blue background with a 1 point inset from the edge. On iPad, the red background will show on the corners as the corner radius does not match.
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

- - -
# License


