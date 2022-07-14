//
//  File.swift
//  
//
//  Created by Ryan Lintott on 2022-07-14.
//

import SwiftUI

public struct HFlowLayup: Layup {
    public let id = UUID()
    public let alignment: Alignment
    public let fixedSize: Axis.Set = .horizontal
    public let start: Alignment
    public let maxHeight: CGFloat
    public let itemAlignment: Alignment
    public var maxItemWidth: CGFloat?
    public let maxItemHeight: CGFloat? = nil
    public let horizontalSpacing: CGFloat
    public let verticalSpacing: CGFloat
    
    public init(
        alignment: Alignment? = nil,
        start: Alignment? = nil,
        maxHeight: CGFloat,
        itemAlignment: VerticalAlignment? = nil,
        maxItemWidth: CGFloat? = nil,
        horizontalSpacing: CGFloat? = nil,
        verticalSpacing: CGFloat? = nil
    ) {
        self.alignment = alignment ?? .topLeading
        self.start = start ?? .topLeading
        self.maxHeight = maxHeight
        self.itemAlignment = Alignment(horizontal: .leading, vertical: itemAlignment ?? .top)
        self.maxItemWidth = min(maxHeight, maxItemHeight ?? .infinity)
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
