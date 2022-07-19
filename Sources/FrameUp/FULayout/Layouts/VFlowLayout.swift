//
//  VFlowLayout.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-07-14.
//

import Foundation
import SwiftUI

public struct VFlowLayout: FULayout {
    public var fuLayoutName: String { String(describing: Self.self) }
    public let id = UUID()
    public let alignment: Alignment
    public let start: Alignment
    public let maxWidth: CGFloat
    public let itemAlignment: Alignment
    public let maxItemWidth: CGFloat?
    public let horizontalSpacing: CGFloat
    public let verticalSpacing: CGFloat

    public let maxItemHeight: CGFloat? = nil
    public let fixedSize: Axis.Set = .vertical
    
    public init(
        alignment: Alignment? = nil,
        start: Alignment? = nil,
        maxWidth: CGFloat,
        itemAlignment: Alignment? = nil,
        maxItemWidth: CGFloat? = nil,
        horizontalSpacing: CGFloat? = nil,
        verticalSpacing: CGFloat? = nil
    ) {
        self.alignment = alignment ?? .topLeading
        self.start = start ?? .topLeading
        self.maxWidth = maxWidth
        self.itemAlignment = itemAlignment ?? .topLeading
        self.maxItemWidth = min(maxWidth, maxItemWidth ?? .infinity)
        self.horizontalSpacing = horizontalSpacing ?? 10
        self.verticalSpacing = verticalSpacing ?? 10
    }
    
    public func contentOffsets(sizes: [Int: CGSize]) -> [Int: CGPoint] {
        var currentPoint: CGPoint = .zero
        var result = [Int: CGPoint]()
        var rowHeight: CGFloat = .zero
        
        for size in sizes.sorted(by: { $0.key < $1.key }) {
            if currentPoint != .zero,
               currentPoint.x + size.value.width > maxWidth {
                currentPoint.x = .zero
                currentPoint.y += rowHeight + verticalSpacing
                rowHeight = .zero
            }
            result.updateValue(currentPoint, forKey: size.key)
            
            currentPoint.x += size.value.width + horizontalSpacing
            rowHeight = max(rowHeight, size.value.height)
        }
        
        return result
    }
}

extension VFlowLayout {
    public struct ForEach<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable, Data.Index == Int {
        let data: Data
        let layout: VFlowLayout
        let content: (Data.Element) -> Content
        
        public init(
            _ data: Data,
            alignment: Alignment? = nil,
            start: Alignment? = nil,
            maxWidth: CGFloat,
            itemAlignment: Alignment? = nil,
            maxItemWidth: CGFloat? = nil,
            horizontalSpacing: CGFloat? = nil,
            verticalSpacing: CGFloat? = nil,
            content: @escaping (Data.Element) -> Content
        ) {
            self.data = data
            layout = .init(
                alignment: alignment,
                start: start,
                maxWidth: maxWidth,
                itemAlignment: itemAlignment,
                maxItemWidth: maxItemWidth,
                horizontalSpacing: horizontalSpacing,
                verticalSpacing: verticalSpacing
            )
            self.content = content
        }
        
        public var body: some View {
            layout.forEach(data, content: content)
        }
    }
    
    public struct _View<Content: View>: View {
        @ViewBuilder
        let layout: VFlowLayout
        let content: Content
        
        public init(
            alignment: Alignment? = nil,
            start: Alignment? = nil,
            maxWidth: CGFloat,
            itemAlignment: Alignment? = nil,
            maxItemWidth: CGFloat? = nil,
            horizontalSpacing: CGFloat? = nil,
            verticalSpacing: CGFloat? = nil,
            @ViewBuilder content: () -> Content
        ) {
            layout = .init(
                alignment: alignment,
                start: start,
                maxWidth: maxWidth,
                itemAlignment: itemAlignment,
                maxItemWidth: maxItemWidth,
                horizontalSpacing: horizontalSpacing,
                verticalSpacing: verticalSpacing
            )
            self.content = content()
        }
        
        public var body: some View {
            layout._view { content }
        }
    }
}
