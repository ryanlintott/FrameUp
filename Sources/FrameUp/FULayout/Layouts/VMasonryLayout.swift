//
//  VMasonryLayout.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-07-14.
//

import Foundation
import SwiftUI

public struct VMasonryLayout: FULayout {
    public var fuLayoutName: String { String(describing: Self.self) }
    public let id = UUID()
    public let alignment: Alignment
    public let start: Alignment
    public let columns: Int
    public let columnWidth: CGFloat
    public var itemAlignment: Alignment
    public let maxItemWidth: CGFloat?
    public let horizontalSpacing: CGFloat
    public let verticalSpacing: CGFloat
    
    public let maxItemHeight: CGFloat? = nil
    public let fixedSize: Axis.Set = .vertical
    
    public init(
        alignment: Alignment? = nil,
        start: Alignment? = nil,
        columns: Int,
        maxWidth: CGFloat,
        itemAlignment: HorizontalAlignment? = nil,
        horizontalSpacing: CGFloat? = nil,
        verticalSpacing: CGFloat? = nil
    ) {
        self.alignment = alignment ?? .topLeading
        self.start = start ?? .topLeading
        self.columns = max(1, columns)
        self.itemAlignment = Alignment(horizontal: itemAlignment ?? .leading, vertical: .top)
        self.horizontalSpacing = horizontalSpacing ?? 10
        self.verticalSpacing = verticalSpacing ?? 10
        self.maxItemWidth = (maxWidth - (self.horizontalSpacing * CGFloat(self.columns - 1))) / CGFloat(self.columns)
        self.columnWidth = maxItemWidth ?? maxWidth
    }
    
    public func contentOffsets(sizes: [Int: CGSize]) -> [Int: CGPoint] {
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
}

extension VMasonryLayout {
    public struct ForEach<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable, Data.Index == Int {
        let data: Data
        let layout: VMasonryLayout
        let content: (Data.Element) -> Content
        
        public init(
            _ data: Data,
            alignment: Alignment? = nil,
            start: Alignment? = nil,
            columns: Int,
            maxWidth: CGFloat,
            itemAlignment: HorizontalAlignment? = nil,
            horizontalSpacing: CGFloat? = nil,
            verticalSpacing: CGFloat? = nil,
            content: @escaping (Data.Element) -> Content
        ) {
            self.data = data
            layout = .init(
                alignment: alignment,
                start: start,
                columns: columns,
                maxWidth: maxWidth,
                itemAlignment: itemAlignment,
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
        let layout: VMasonryLayout
        let content: Content
        
        public init(
            alignment: Alignment? = nil,
            start: Alignment? = nil,
            columns: Int,
            maxWidth: CGFloat,
            itemAlignment: HorizontalAlignment? = nil,
            horizontalSpacing: CGFloat? = nil,
            verticalSpacing: CGFloat? = nil,
            @ViewBuilder content: () -> Content
        ) {
            layout = .init(
                alignment: alignment,
                start: start,
                columns: columns,
                maxWidth: maxWidth,
                itemAlignment: itemAlignment,
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
