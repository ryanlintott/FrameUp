//
//  VGridMasonry.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-04-21.
//

import SwiftUI

public struct VGridMasonry<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable, Data.Index == Int {
    
    let data: Array<(Data.Element, Int)>
    let width: CGFloat
    let columns: Int
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat
    let content: (Data.Element) -> Content
    
    @State private var sizes: [Int: CGSize] = [:]
    
    public init(_ data: Data, width: CGFloat, columns: Int, horizontalSpacing: CGFloat = 0, verticalSpacing: CGFloat = 0, content: @escaping (Data.Element) -> Content) {
        self.data = Array(zip(data, data.indices))
        self.width = width
        self.columns = columns
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.content = content
    }

    var columnWidth: CGFloat {
        (width - (horizontalSpacing * CGFloat(columns - 1))) / CGFloat(columns)
    }
    
    var contentPositions: [Int: CGPoint] {
        var result: [Int: CGPoint] = [:]
        let columnTopLeft: [Int: CGFloat] = (0..<columns).reduce(into: [Int: CGFloat]()) {
            $0[$1] = CGFloat($1) * (columnWidth + horizontalSpacing)
        }
        var columnHeights: [Int: CGFloat] = (0..<columns).reduce(into: [Int: CGFloat]()) { $0[$1] = 0 }
        
        for size in sizes.sorted(by: { $0.key < $1.key }) {
            let minColumnHeight: CGFloat = columnHeights.min(by: { $0.value < $1.value })?.value ?? 0
            
            // Get the shortest column
            if let column = columnHeights
                .filter({ $0.value == minColumnHeight })
                .sorted(by: { $0.key < $1.key })
                .first {
                result.updateValue(CGPoint(x: columnTopLeft[column.key] ?? 0, y: column.value), forKey: size.key)
                columnHeights.updateValue((columnHeights[column.key] ?? 0) + size.value.height + verticalSpacing, forKey: column.key)
            }
        }
        
        return result
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
                    .frame(width: columnWidth)
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
