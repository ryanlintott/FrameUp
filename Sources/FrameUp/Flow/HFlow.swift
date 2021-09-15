//
//  HFlow.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-06-11.
//

import SwiftUI

public struct HFlow<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable, Data.Index == Int {
    let data: Array<(Data.Element, Int)>
    let maxWidth: CGFloat
    let maxRowHeight: CGFloat
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat
    var content: (Data.Element) -> Content
    
    @State private var sizes: [Int: CGSize] = [:]
    
    var contentPositions: [Int: CGPoint] {
        var currentPoint: CGPoint = .zero
        var result = [Int: CGPoint]()
        var rowHeight: CGFloat = .zero

        for size in sizes.sorted(by: { $0.key < $1.key }) {
            if currentPoint != .zero && currentPoint.x + size.value.width > maxWidth {
                currentPoint.x = .zero
                currentPoint.y += rowHeight + verticalSpacing
                rowHeight = .zero
            }
            result.updateValue(currentPoint, forKey: size.key)
            
            currentPoint.x += size.value.width + horizontalSpacing
            rowHeight = min(max(rowHeight, size.value.height), maxRowHeight)
        }
        
        return result
    }
    
    public init(_ data: Data, maxWidth: CGFloat, maxRowHeight: CGFloat = .infinity, horizontalSpacing: CGFloat = 10, verticalSpacing: CGFloat = 10, content: @escaping (Data.Element) -> Content) {
        self.data = Array(zip(data, data.indices))
        self.maxWidth = maxWidth
        self.maxRowHeight = maxRowHeight
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.content = content
    }
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(data, id: \.0.id) { (item, index) in
                content(item)
                    .overlay(
                        GeometryReader { proxy in
                            Color.clear
                                .preference(key: FlowContentSizeKey.self, value: [index: proxy.size])
                        }
                    )
                    .frame(maxWidth: maxWidth, maxHeight: maxRowHeight, alignment: .topLeading)
                    .fixedSize()
                    .alignmentGuide(.leading) { d in
                        -(contentPositions[index]?.x ?? .zero)
                    }
                    .alignmentGuide(.top) { d in
                        -(contentPositions[index]?.y ?? .zero)
                    }
            }
        }
        .onPreferenceChange(FlowContentSizeKey.self) {
            self.sizes = $0
        }
    }
}
