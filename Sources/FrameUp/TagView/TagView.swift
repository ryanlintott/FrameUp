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
        var width = CGFloat.zero
        var height = CGFloat.zero

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
                        if (abs(width - d.width) > maxWidth) {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        if element == elements.last {
                            width = 0 //last item
                        } else {
                            width -= d.width
                        }
                        return result
                    }
                    .alignmentGuide(.top) { d in
                        let result = height
                        if element == elements.last {
                            height = 0 // last item
                        }
                        return result
                    }
            }
        }
    }
}
