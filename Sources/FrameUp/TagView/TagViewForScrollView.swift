//
//  TagViewForScrollView.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-05-25.
//

import SwiftUI

public struct TagViewForScrollView<Element: Hashable, Content: View>: View {
    let maxWidth: CGFloat
    let elements: [Element]
    let content: (Element) -> Content
    
    public init(maxWidth: CGFloat, elements: [Element], content: @escaping (Element) -> Content) {
        self.maxWidth = maxWidth
        self.elements = elements
        self.content = content
    }

    public var body: some View {
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
