# FrameUp

![License - MIT](https://img.shields.io/github/license/ryanlintott/FrameUp)
![Version](https://img.shields.io/github/v/tag/ryanlintott/FrameUp?label=version)

A collection of SwiftUI framing views and tools to help with layout.

## Width/Height Readers
Unlike 'GeometryReader' these views will provide only one measurement and not take up all the available space on the other axis.

### WidthReader
Provides the available width while fitting to the height of the content.

### HeightReader
Provides the available height while fitting to the width of the content.

## .onSizeChange(perform:)
A view modifier that scales a view using `scaleEffect` to match a frame size.

## Flow Views
Laying out views that flow from one row or column to the next based on a collection of data

### HFlow
A view that creates views based on a collection of data from left to right, adding rows when needed.

### VFlow
A view that creates views based on a collection of data from top to bottom, adding columns when needed.
