//
//  TagView.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-04-23.
//  Inspired by: https://stackoverflow.com/questions/62102647/swiftui-hstack-with-wrap-and-dynamic-height/62103264#62103264

import SwiftUI

/// A view that creates views based on an array of elments from left to right, adding rows when needed.
///
/// *Warning: Does not work in ScrollView.*
/// Each row height will be determined by the tallest element. Using variables inside the view body is not recommended by Apple. You can use `HFlow` for a more Apple-approved methodology and more advanced features.
///
///     TagView(elements: ["One", "Two", "Three"]) { element in
///         Text(element)
///     }
///
public struct TagView<Element: Hashable, Content: View>: View {
    let elements: [Element]
    let content: (Element) -> Content
    
    /// Creates a copy of the content view for each hashable element and lays them out from left to right adding additional rows where necessary.
    /// - Parameters:
    ///   - elements: any hashable element
    ///   - content: content view that takes an element as a parameter
    public init(elements: [Element], content: @escaping (Element) -> Content) {
        self.elements = elements
        self.content = content
    }

    public var body: some View {
        var maxWidth = CGFloat.zero
        var x = CGFloat.zero
        var y = CGFloat.zero
        var rowHeight = CGFloat.zero

        return ZStack(alignment: .topLeading) {
            Color.clear
                .frame(height: 0)
                .alignmentGuide(.leading) { d in
                    maxWidth = d.width
                    return d[.leading]
                }
            
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
