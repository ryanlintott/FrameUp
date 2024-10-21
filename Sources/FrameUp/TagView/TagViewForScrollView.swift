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
@available(swift, deprecated: 6.0, message: "This view may crash with Swift 6 strict concurrency due to unsafe thread jumping. Use HFlowLayout instead.")
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
        /// Using variables inside the view body is not recommended by Apple but it mostly works. Mutating these main actor variables from a nonisolated closure (like alignmentGuide) may cause unexpected behaviour in Swift 5 mode (but it appears to work) and will likely cause crashes in Swift 6.
        var x = CGFloat.zero
        var y = CGFloat.zero
        var rowHeight = CGFloat.zero

        return ZStack(alignment: .topLeading) {
            ForEach(elements, id: \.self) { element in
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
}
