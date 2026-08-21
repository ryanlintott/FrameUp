# ``FrameUp``

A Swift Package of SwiftUI layout tools for flowing, fitting, measuring, scaling, rotating and flipping views.

## Overview

Arrange views with layouts like ``HFlowLayout`` and ``VMasonryLayout``, pick the best layout for the available space with ``LayoutThatFits``, measure the space you are given with ``WidthReader``, ``HeightReader`` and ``SwiftUICore/View/onSizeChange(perform:)``, and use ``SmartScrollView`` that fits to the content and only scrolls when it needs to.

Additional tools help with problems SwiftUI does not solve on its own. ``AutoRotatingView`` lets a view have its own set of allowed device orientations separate from the app. ``FlippingView`` and ``SwiftUICore/View/rotation3DEffect(_:axis:anchor:anchorZ:perspective:backsideFlip:back:)`` put a different view on the back of a rotated view. ``SwiftUICore/View/unclippedTextRenderer()`` stops SwiftUI `Text` from clipping. ``WidgetSize`` and ``WidgetDemoFrame`` give accurate widget frames without `WidgetKit`. And ``FULayout`` provides a `Layout`-like API that works in iOS 15.

Requires iOS 15+, macOS 12+, watchOS 9+, tvOS 15+, or visionOS 1+.

For a feature-by-feature guide with examples, see the [README](https://github.com/ryanlintott/FrameUp), and the `Example` folder in the [repository](https://github.com/ryanlintott/FrameUp) for a demo app.

## Topics

### Layouts

- ``HFlowLayout``
- ``VFlowLayout``
- ``HMasonryLayout``
- ``VMasonryLayout``
- ``LayoutThatFits``
- ``LayoutFromFULayout``

### Alignment

- ``FUAlignment``
- ``FUHorizontalAlignment``
- ``FUVerticalAlignment``

### Scroll Views

- ``SmartScrollView``

### Size Readers

- ``WidthReader``
- ``HeightReader``
- ``SwiftUICore/View/onSizeChange(perform:)``

### Equal Sizing

- ``SwiftUICore/View/equalWidthPreferred()``
- ``SwiftUICore/View/equalWidthContainer()``
- ``SwiftUICore/View/equalHeightPreferred()``
- ``SwiftUICore/View/equalHeightContainer()``

### Keyboard Height

- ``SwiftUICore/View/keyboardHeightEnvironmentValue()``
- ``SwiftUICore/EnvironmentValues/keyboardHeight``
- ``SwiftUICore/Animation/keyboard``

### Frame Adjustment

- ``SwiftUICore/View/relativePadding(_:_:)``
- ``SwiftUICore/View/relativePadding(_:)``
- ``SwiftUICore/View/frame(_:alignment:)``
- ``ScaledView``
- ``ScaleMode``
- ``OverlappingImage``

### Scaling View Modifiers

- ``SwiftUICore/View/scaledToFrame(_:contentMode:scaleMode:)``
- ``SwiftUICore/View/scaledToFrame(width:height:contentMode:scaleMode:)``
- ``SwiftUICore/View/scaledToFit(_:scaleMode:)``
- ``SwiftUICore/View/scaledToFit(width:height:scaleMode:)``
- ``SwiftUICore/View/scaledToFit(width:scaleMode:)``
- ``SwiftUICore/View/scaledToFit(height:scaleMode:)``
- ``SwiftUICore/View/scaledToFill(_:scaleMode:)``
- ``SwiftUICore/View/scaledToFill(width:height:scaleMode:)``

### Text

- ``SwiftUICore/View/unclippedTextRenderer()``
- ``HairSpaceJustifiedText``

### Orientation

- ``AutoRotatingView``
- ``FUInterfaceOrientation``
- ``SwiftUICore/View/rotationMatchingOrientation(_:isOn:withAnimation:)``

### Two-Sided Views

- ``FlippingView``
- ``PerspectiveFlippingView``
- ``BacksideFlip``
- ``SwiftUICore/View/rotation3DEffect(_:axis:anchor:anchorZ:perspective:backsideFlip:back:)``
- ``SwiftUICore/View/rotation3DEffect(_:axis:anchor:backsideFlip:thickness:back:)``
- ``SwiftUICore/View/perspectiveRotationEffect(_:axis:anchor:anchorZ:perspective:backsideFlip:back:)``

### Tab Menu

- ``TabMenu``
- ``TabMenuItem``
- ``NamedAction``

### Widgets

- ``WidgetSize``
- ``WidgetTarget``
- ``WidgetDemoFrame``
- ``AccessoryInlineImage``

### FULayout

- ``FULayout``
- ``AnyFULayout``
- ``FULayoutRow``
- ``FULayoutColumn``
- ``FULayoutSizeKey``

### FULayouts

- ``HFlow``
- ``VFlow``
- ``HMasonry``
- ``VMasonry``
- ``HStackFULayout``
- ``VStackFULayout``
- ``ZStackFULayout``
- ``FULayoutThatFits``
- ``FUViewThatFits``

### Proportions

- ``Proportionable``
- ``AspectFormat``

### Extended Types

- ``Swift/Dictionary``
- ``UIKit/UIImage``
- ``WidgetKit/WidgetFamily``
