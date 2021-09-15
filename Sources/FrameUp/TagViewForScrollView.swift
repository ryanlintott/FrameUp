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
        var width = CGFloat.zero
        var height = CGFloat.zero

        return ZStack(alignment: .topLeading) {
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

struct TagViewForScrollView_Previews: PreviewProvider {
    static let elements = ["Thing", "Another", "Test", "Short", "Long Text is Long", "More", "Cool Tag"]
    
    static var previews: some View {
        GeometryReader { previewProxy in
            TagViewForScrollView(maxWidth: previewProxy.size.width, elements: elements) { element in
                Text(element)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.blue)
                    .clipShape(Capsule())
                    .padding(2)
            }
            .padding(2)
            .background(Color.gray)
        }
    }
}
