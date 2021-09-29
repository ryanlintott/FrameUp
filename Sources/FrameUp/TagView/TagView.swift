//
//  TagView.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-04-23.
//  Inspired by: https://stackoverflow.com/questions/62102647/swiftui-hstack-with-wrap-and-dynamic-height/62103264#62103264

import SwiftUI

// Does not work reliably in ScrollView
public struct TagView<Element: Hashable, Content: View>: View {
    let elements: [Element]
    let content: (Element) -> Content
    
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
