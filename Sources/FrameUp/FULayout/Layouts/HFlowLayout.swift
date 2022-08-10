//
//  File.swift
//  
//
//  Created by Ryan Lintott on 2022-07-14.
//

import SwiftUI

public struct HFlowLayout: FULayout {
    public var fuLayoutName: String { String(describing: Self.self) }
    public let id = UUID()
    public let alignment: Alignment
    public let start: Alignment
    public let maxHeight: CGFloat
    public let itemAlignment: Alignment
    public let maxItemHeight: CGFloat?
    public let horizontalSpacing: CGFloat
    public let verticalSpacing: CGFloat
    
    public var maxItemWidth: CGFloat? = nil
    public let fixedSize: Axis.Set = .horizontal
    
    public init(
        alignment: VerticalAlignment? = nil,
        start: Alignment? = nil,
        maxHeight: CGFloat,
        itemAlignment: HorizontalAlignment? = nil,
        maxItemHeight: CGFloat? = nil,
        horizontalSpacing: CGFloat? = nil,
        verticalSpacing: CGFloat? = nil
    ) {
        self.alignment = Alignment(horizontal: .leading, vertical: alignment ?? .top)
        self.start = start ?? .topLeading
        self.maxHeight = maxHeight
        self.itemAlignment = Alignment(horizontal: itemAlignment ?? .leading, vertical: .top)
        self.maxItemHeight = min(maxHeight, maxItemHeight ?? .infinity)
        self.horizontalSpacing = horizontalSpacing ?? 10
        self.verticalSpacing = verticalSpacing ?? 10
    }
    
    public func contentOffsets(sizes: [Int: CGSize]) -> [Int: CGPoint] {
        var currentPoint: CGPoint = .zero
        var result = [Int: CGPoint]()
        var columnWidth: CGFloat = .zero
        
        for size in sizes.sorted(by: { $0.key < $1.key }) {
            if currentPoint != .zero,
               currentPoint.y + size.value.height > maxHeight {
                currentPoint.y = .zero
                currentPoint.x += columnWidth + horizontalSpacing
                columnWidth = .zero
            }
            result.updateValue(currentPoint, forKey: size.key)
            
            currentPoint.y += size.value.height + verticalSpacing
            columnWidth = max(columnWidth, size.value.width)
        }
        
        return result
    }
}

//extension HFlowLayout {
//    public struct ForEach<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable, Data.Index == Int {
//        let data: Data
//        let layout: HFlowLayout
//        let content: (Data.Element) -> Content
//        
//        public init(
//            _ data: Data,
//            alignment: VerticalAlignment? = nil,
//            start: Alignment? = nil,
//            maxHeight: CGFloat,
//            itemAlignment: HorizontalAlignment? = nil,
//            maxItemHeight: CGFloat? = nil,
//            horizontalSpacing: CGFloat? = nil,
//            verticalSpacing: CGFloat? = nil,
//            content: @escaping (Data.Element) -> Content
//        ) {
//            self.data = data
//            layout = .init(
//                alignment: alignment,
//                start: start,
//                maxHeight: maxHeight,
//                itemAlignment: itemAlignment,
//                maxItemHeight: maxItemHeight,
//                horizontalSpacing: horizontalSpacing,
//                verticalSpacing: verticalSpacing
//            )
//            self.content = content
//        }
//        
//        public var body: some View {
//            layout.forEach(data, content: content)
//        }
//    }
//    
//    public struct _View<Content: View>: View {
//        @ViewBuilder
//        let layout: HFlowLayout
//        let content: Content
//        
//        public init(
//            alignment: VerticalAlignment? = nil,
//            start: Alignment? = nil,
//            maxHeight: CGFloat,
//            itemAlignment: HorizontalAlignment? = nil,
//            maxItemHeight: CGFloat? = nil,
//            horizontalSpacing: CGFloat? = nil,
//            verticalSpacing: CGFloat? = nil,
//            @ViewBuilder content: () -> Content
//        ) {
//            layout = .init(
//                alignment: alignment,
//                start: start,
//                maxHeight: maxHeight,
//                itemAlignment: itemAlignment,
//                maxItemHeight: maxItemHeight,
//                horizontalSpacing: horizontalSpacing,
//                verticalSpacing: verticalSpacing
//            )
//            self.content = content()
//        }
//        
//        public var body: some View {
//            layout._view { content }
//        }
//    }
//}
