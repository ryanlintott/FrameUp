//
//  VFlow.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-06-11.
//

import SwiftUI

import SwiftUI

public struct VFlow<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable, Data.Index == Int {
    let data: Array<(Data.Element, Int)>
    let maxHeight: CGFloat
    let maxColumnWidth: CGFloat
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat
    var content: (Data.Element) -> Content
    
    @State private var sizes: [Int: CGSize] = [:]
    
    var contentPositions: [Int: CGPoint] {
        var currentPoint: CGPoint = .zero
        var result = [Int: CGPoint]()
        var columnWidth: CGFloat = .zero

        for size in sizes.sorted(by: { $0.key < $1.key }) {
            if currentPoint != .zero && currentPoint.y + size.value.height > maxHeight {
                currentPoint.y = .zero
                currentPoint.x += columnWidth + horizontalSpacing
                columnWidth = .zero
            }
            result.updateValue(currentPoint, forKey: size.key)
            
            currentPoint.y += size.value.height + verticalSpacing
            columnWidth = min(max(columnWidth, size.value.width), maxColumnWidth)
        }
        
        return result
    }
    
    public init(_ data: Data, maxHeight: CGFloat, maxColumnWidth: CGFloat = .infinity, horizontalSpacing: CGFloat = 10, verticalSpacing: CGFloat = 10, content: @escaping (Data.Element) -> Content) {
        self.data = Array(zip(data, data.indices))
        self.maxHeight = maxHeight
        self.maxColumnWidth = maxColumnWidth
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.content = content
    }
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(data, id: \.0.id) { (item, index) in
                content(item)
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .preference(key: FlowContentSizeKey.self, value: [index: proxy.size])
                        }
                    )
                    .frame(maxWidth: maxColumnWidth, maxHeight: maxHeight, alignment: .topLeading)
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
