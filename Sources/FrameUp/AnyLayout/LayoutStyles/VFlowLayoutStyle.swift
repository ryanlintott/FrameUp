//
//  VFlowLayout.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2022-06-01.
//

import SwiftUI

public struct VFlowLayoutStyle: LayoutStyle {
    public let id = UUID()
    public let alignment: Alignment
    public let start: Alignment
    public let fixedSize: Axis.Set = .vertical
    public let maxWidth: CGFloat
    public let itemAlignment: Alignment
    public var maxItemWidth: CGFloat?
    public let maxItemHeight: CGFloat? = nil
    public let horizontalSpacing: CGFloat
    public let verticalSpacing: CGFloat
    
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
