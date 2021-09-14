//
//  VFlow.swift
//  SwiftUITextDemo
//
//  Created by Ryan Lintott on 2021-06-11.
//

import SwiftUI

import SwiftUI

public struct VFlow<Element: Identifiable, Cell: View>: View {
    let items: [Element]
    let maxHeight: CGFloat
    let maxColumnWidth: CGFloat
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat
    var cell: (Element) -> Cell
    
    @State private var sizes: [Int: CGSize] = [:]
    
    var cellPositions: [Int: CGPoint] {
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
    
    public init(items: [Element], maxHeight: CGFloat, maxColumnWidth: CGFloat = .infinity, horizontalSpacing: CGFloat = 10, verticalSpacing: CGFloat = 10, cell: @escaping (Element) -> Cell) {
        self.items = items
        self.maxHeight = maxHeight
        self.maxColumnWidth = maxColumnWidth
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.cell = cell
    }
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(zip(items, items.indices)), id: \.0.id) { (item, index) in
                cell(item)
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .preference(key: CellSizeKey.self, value: [index: proxy.size])
                        }
                    )
                    .frame(maxWidth: maxColumnWidth, maxHeight: maxHeight, alignment: .topLeading)
                    .fixedSize()
                    .alignmentGuide(.leading) { d in
                        -(cellPositions[index]?.x ?? .zero)
                    }
                    .alignmentGuide(.top) { d in
                        -(cellPositions[index]?.y ?? .zero)
                    }
            }
        }
        .onPreferenceChange(CellSizeKey.self) {
            self.sizes = $0
        }
    }
}
