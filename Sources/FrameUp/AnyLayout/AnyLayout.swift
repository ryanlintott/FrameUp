//
//  HVLayout.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2022-05-31.
//

import SwiftUI

public struct AnyLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable, Data.Index == Int {
    let data: Array<(Data.Element, Int)>
    let layout: Layout
    let content: (Data.Element) -> Content
    
    @State private var contentPositions: [Int: CGPoint] = [:]
    @State private var frameSize: CGSize? = nil
    
    public init(_ data: Data, layout: Layout, content: @escaping (Data.Element) -> Content) {
        self.data = Array(zip(data, data.indices))
        self.layout = layout
        self.content = content
    }
    
    public var body: some View {
        ZStack(alignment: layout.alignment) {
            ForEach(data, id: \.0.id) { (item, index) in
                content(item)
                    .overlay(
                        GeometryReader { proxy in
                            Color.clear
                                .preference(key: LayoutSizeKey.self, value: [index: proxy.size])
                        }
                    )
                    .fixedSize(
                        horizontal: layout.fixedSize.contains(.horizontal),
                        vertical: layout.fixedSize.contains(.vertical)
                    )
                    .frame(
                        maxWidth: layout.maxItemWidth,
                        maxHeight: layout.maxItemHeight,
                        alignment: layout.itemAlignment
                    )
                    .alignmentGuide(layout.alignment.horizontal) { d in
                        -(contentPositions[index]?.x ?? .zero)
                    }
                    .alignmentGuide(layout.alignment.vertical) { d in
                        -(contentPositions[index]?.y ?? .zero)
                    }
            }
        }
        .frame(frameSize, alignment: layout.alignment)
        .fixedSize()
        .onPreferenceChange(LayoutSizeKey.self) {
            self.contentPositions = layout.contentOffsets($0)
            self.frameSize = layout.rect(positions: contentPositions, sizes: $0).size
        }
        .id(layout.id)
    }
}
