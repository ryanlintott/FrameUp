//
//  HFlow.swift
//  SwiftUITextDemo
//
//  Created by Ryan Lintott on 2021-06-11.
//

import SwiftUI

struct HFlow<Element: Identifiable, Cell: View>: View {
    let items: [Element]
    let maxWidth: CGFloat
    let maxRowHeight: CGFloat
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat
    var cell: (Element) -> Cell
    
    @State private var sizes: [Int: CGSize] = [:]
    
    var cellPositions: [Int: CGPoint] {
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
    
    init(items: [Element], maxWidth: CGFloat, maxRowHeight: CGFloat = .infinity, horizontalSpacing: CGFloat = 10, verticalSpacing: CGFloat = 10, cell: @escaping (Element) -> Cell) {
        self.items = items
        self.maxWidth = maxWidth
        self.maxRowHeight = maxRowHeight
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.cell = cell
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(zip(items, items.indices)), id: \.0.id) { (item, index) in
                cell(item)
                    .frame(maxWidth: maxWidth, maxHeight: maxRowHeight, alignment: .top)
                    .fixedSize()
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .preference(key: CellSizeKey.self, value: [index: proxy.size])
                        }
                    )
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
