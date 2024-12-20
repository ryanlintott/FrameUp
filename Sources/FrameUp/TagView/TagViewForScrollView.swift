//
//  TagViewForScrollView.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-05-25.

import SwiftUI

/// A view that creates views based on an array of elments from left to right, adding rows when needed. Each row height will be determined by the tallest element.
///
/// Each row height will be determined by the tallest element. A maximum width must be provided but ``WidthReader`` can be used to get the value (especially helpful when inside a `ScrollView`).
///
///     WidthReader { width in
///         TagViewForScrollView(maxWidth: width, elements: ["One", "Two", "Three"]) { element in
///             Text(element)
///         }
///     }
///
@available(swift, deprecated: 6, message: "Replace with HFlowLayout and ForEach.")
@available(iOS, introduced: 14, deprecated: 16, message: "Replace with HFlowLayout and ForEach.")
@available(macOS, introduced: 11, deprecated: 13, message: "Replace with HFlowLayout and ForEach.")
@available(watchOS, introduced: 7, deprecated: 9, message: "Replace with HFlowLayout and ForEach.")
@available(tvOS, introduced: 14, deprecated: 16, message: "Replace with HFlowLayout and ForEach.")
@available(visionOS, introduced: 1, deprecated: 1, message: "Replace with HFlowLayout and ForEach.")
public struct TagViewForScrollView<Element: Hashable, Content: View>: View {
    let maxWidth: CGFloat
    let elements: [Element]
    let content: (Element) -> Content
    
    /// Creates a copy of the content view for each hashable element and lays them out from left to right adding additional rows where necessary.
    /// - Parameters:
    ///   - maxWidth: Maximum available width. Final width will be based on width of content
    ///   - elements: Any hashable element
    ///   - content: Content view that takes an element as a parameter
    public init(maxWidth: CGFloat, elements: [Element], content: @escaping (Element) -> Content) {
        self.maxWidth = maxWidth
        self.elements = elements
        self.content = content
    }
    
    public var body: some View {
        if #available(iOS 16, macOS 13, watchOS 9, tvOS 16, *) {
            hFlowLayoutBody
        } else {
            hFlowBody
        }
    }
    
    @available(iOS 16, macOS 13, watchOS 9, tvOS 16, *)
    @ViewBuilder
    public var hFlowLayoutBody: some View {
        HFlowLayout(alignment: .topLeading, spacing: 0) {
            ForEach(elements, id: \.self) { element in
                content(element)
            }
        }
    }
    
    public var hFlowBody: some View {
        HFlow(alignment: .topLeading, maxWidth: maxWidth, maxItemWidth: nil, horizontalSpacing: 0, verticalSpacing: 0) {
            ForEach(elements, id: \.self) { element in
                content(element)
            }
        }
    }
    
    #if swift(<6)
    @available(*, deprecated, message: "This code did not layout elements correctly when adding or removing tags. I'm just keeping it around because it's weird and it kinda works.")
    public var legacyBody: some View {
        /// Using variables inside the view body is not recommended by Apple but it mostly works. Mutating these main actor variables from a nonisolated closure (like alignmentGuide) may cause unexpected behaviour in Swift 5 mode (but it appears to work) and will likely cause crashes in Swift 6.
        var x = CGFloat.zero
        var y = CGFloat.zero
        var rowHeight = CGFloat.zero

        return ZStack(alignment: .topLeading) {
            ForEach(elements, id: \.self) { [elements] element in
                content(element)
                    .alignmentGuide(.leading) { d in
                        let result: CGFloat
                        if element == elements.first {
                            x = d.width
                            rowHeight = d.height
                            result = d[.leading]
                        } else if (x + d.width) <= maxWidth {
                            result = d[.leading] - x
                            x += d.width
                            rowHeight = max(rowHeight, d.height)
                        } else {
                            result = d[.leading]
                            y += rowHeight
                            x = d.width
                            rowHeight = d.height
                        }
                        return result
                    }
                    .alignmentGuide(.top) { d in
                        if element == elements.first {
                            y = -d[.top]
                        }
                        return -y
                    }
            }
        }
    }
    #endif
}
